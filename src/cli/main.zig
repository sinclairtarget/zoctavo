const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const zoctavo = @import("zoctavo");

const cli = @import("cli.zig");
const logging = @import("logging.zig");
const logger = logging.logger;

const UncaughtError = std.mem.Allocator.Error || Io.Writer.Error;

pub const std_options: std.Options = .{
    .logFn = logging.logRuntime,
};

pub fn main(init: std.process.Init) UncaughtError!void {
    const alloc = init.arena.allocator();

    // Parse CLI args.
    const invocation = parse_args: {
        var args_iterator = try init.minimal.args.iterateAllocator(alloc);
        defer args_iterator.deinit();

        var diagnostic: cli.Diagnostic = .{};
        break :parse_args cli.parse(&args_iterator, &diagnostic) catch |err| {
            switch (err) {
                cli.ParseError.UnrecognizedArgument => {
                    die("unrecognized argument", .{});
                },
            }
        };
    };

    // Set up I/O.
    var stdout_buffer: [64]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(init.io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const absolute_cwd = std.process.currentPathAlloc(init.io, alloc) catch {
        die("failed to get cwd", .{});
    };

    // Set log level
    if (invocation.verbose) {
        logging.runtime_log_level = .debug;
    }
    logger.debug("Running with invocation: {f}", .{invocation});

    // Dispatch on subcommand.
    switch (invocation.subcommand) {
        .build => {
            try runBuild(init.io, alloc, absolute_cwd);
        },
        .clean => {
            try runClean(init.io, alloc, absolute_cwd);
        },
        .config => {
            try printConfig(init.io, alloc, stdout);
        },
        .help => {
            try cli.printUsage(stdout, .{});
        },
        .version => {
            try printVersion(stdout);
        },
    }

    try stdout.flush();
}

fn runBuild(io: Io, alloc: Allocator, absolute_cwd: []const u8) !void {
    const config = try loadConfig(io, alloc);
    const ws: zoctavo.build.Workspace = .{
        .absolute_working_dir = absolute_cwd,
        .config = config,
    };
    zoctavo.build.run(io, alloc, ws) catch |err| {
        switch (err) {
            zoctavo.build.BuildError.CreateBuildDirectoryFailed => {
                die(
                    "failed to create build directory \"{s}\"",
                    .{config.build.dir},
                );
            },
            zoctavo.build.BuildError.OpenBuildDirectoryFailed => {
                die(
                    "failed to open build directory \"{s}\"",
                    .{config.build.dir},
                );
            },
            zoctavo.build.BuildError.OpenFileFailed => {
                die("I/O error during build", .{});
            },
            else => |e| return e,
        }
    };
}

fn runClean(io: Io, alloc: Allocator, absolute_cwd: []const u8) !void {
    const config = try loadConfig(io, alloc);
    const ws: zoctavo.build.Workspace = .{
        .absolute_working_dir = absolute_cwd,
        .config = config,
    };
    zoctavo.build.clean(io, alloc, ws) catch |err| {
        switch (err) {
            zoctavo.build.CleanError.DeleteBuildDirectoryFailed => {
                die(
                    "failed to clean build directory \"{s}\"",
                    .{config.build.dir},
                );
            },
            else => |e| return e,
        }
    };
}

fn printConfig(
    io: Io,
    alloc: Allocator,
    out: *Io.Writer,
) !void {
    const config = try loadConfig(io, alloc);
    try std.zon.stringify.serialize(config, .{}, out);
    _ = try out.writeAll("\n");
}

fn printVersion(out: *Io.Writer) Io.Writer.Error!void {
    try out.print("{s}\n", .{zoctavo.version});
}

fn loadConfig(io: Io, alloc: Allocator) !zoctavo.book.Config {
    var diag: zoctavo.book.Diagnostics = .{};
    const config = zoctavo.loadBookConfig(io, alloc, &diag) catch |err| {
        const filename = diag.filepath orelse "book config file";
        switch (err) {
            zoctavo.LoadConfigError.ReadFailed => {
                if (diag.sub_error) |sub_err| {
                    die(
                        "failed to read {s}: {any}",
                        .{ filename, sub_err },
                    );
                } else {
                    die("failed to read {s}: unknown error", .{filename});
                }
            },
            zoctavo.LoadConfigError.ParseFailed => {
                die("failed to parse {s}", .{filename});
            },
            else => |e| return e,
        }
    };

    return config;
}

/// Prints a message to stderr and exits with code 1.
fn die(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print("Error: " ++ fmt ++ ".\n", args);
    std.process.exit(1);
}
