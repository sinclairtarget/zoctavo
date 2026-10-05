const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const atrus = @import("atrus");
const zoctavo = @import("zoctavo");

const cli = @import("cli.zig");

const UncaughtError = std.mem.Allocator.Error || Io.Writer.Error;

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

    // Dispatch on subcommand.
    switch (invocation.subcommand) {
        .build => {
            try runBuild(init.io, alloc);
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

fn runBuild(io: Io, alloc: Allocator) !void {
    const config = try loadConfig(io, alloc);
    try zoctavo.build.run(io, alloc, config);
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

fn loadConfig(io: Io, alloc: Allocator) !zoctavo.config.Config {
    var diag: zoctavo.config.Diagnostics = .{};
    const config = zoctavo.loadConfig(io, alloc, &diag) catch |err| {
        switch (err) {
            zoctavo.LoadConfigError.ReadFailed => {
                const filename = diag.filepath orelse "config file";
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
                if (diag.filepath) |fp| {
                    die("failed to parse {s}", .{fp});
                } else {
                    die("failed to parse config file", .{});
                }
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
