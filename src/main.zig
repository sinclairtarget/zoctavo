const std = @import("std");
const Io = std.Io;

const atrus = @import("atrus");
const zoctavo = @import("zoctavo");

const cli = @import("cli.zig");

pub fn main(init: std.process.Init) !void {
    const scratch = init.arena.allocator();

    // Parse CLI args.
    const invocation = parse_args: {
        var args_iterator = try init.minimal.args.iterateAllocator(scratch);
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
        .build, .config => {
            @panic("not yet implemented");
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

fn printVersion(out: *Io.Writer) !void {
    try out.print("{s}\n", .{zoctavo.version});
}

/// Prints a message to stderr and exits with code 1.
fn die(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print("Error: " ++ fmt ++ "\n", args);
    std.process.exit(1);
}
