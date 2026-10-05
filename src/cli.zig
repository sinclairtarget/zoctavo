const std = @import("std");
const Io = std.Io;

pub const Subcommand = enum {
    build,
    config,
    help,
    version,
};

pub const Invocation = struct {
    verbose: bool,
    subcommand: union(Subcommand) {
        build: void,
        config: void,
        help: void,
        version: void,
    },
};

pub const ParseError = error{
    UnrecognizedArgument,
};

pub const Diagnostic = struct {
    /// If present, then parsing failed for this specific subcommand.
    subcommand: ?Subcommand = null,
    /// If present, an error occurred while processing this argument.
    problem_arg: ?[]const u8 = null,
};

const top_usage =
    \\Usage: zoctavo [GLOBAL OPTIONS...] [SUBCOMMAND] [SUBCOMMAND OPTIONS...]
    \\
    \\zoctavo builds books from MyST markdown.
    \\
    \\Subcommands:
    \\  build    Builds the book. (default)
    \\  config   Print book config.
    \\  help     Print usage.
    \\  version  Print version.
    \\
    \\For more information on a subcommand, run `zoctavo help <subcommand>`.
    \\
    \\Global Options:
    \\  --verbose  Set the runtime log level to DEBUG. Note that unless
    \\             compiled in debug mode only log messages with level INFO and
    \\             above will actually be shown.
    \\
;

pub fn parse(
    args_iterator: *std.process.Args.Iterator,
    diagnostic: *Diagnostic,
) ParseError!Invocation {
    var invocation: Invocation = .{ // Default
        .verbose = false,
        .subcommand = .{ .build = {} },
    };

    _ = args_iterator.skip();
    var current = args_iterator.next();

    // Global options
    while (current) |arg| : ({
        current = args_iterator.next();
    }) {
        if (std.mem.eql(u8, arg, "--verbose")) {
            invocation.verbose = true;
        } else {
            break;
        }
    }

    // Subcommand
    while (current) |arg| : ({
        current = args_iterator.next();
    }) {
        if (std.mem.eql(u8, arg, "build")) {
            invocation.subcommand = .{ .build = {} };
        } else if (std.mem.eql(u8, arg, "config")) {
            invocation.subcommand = .{ .config = {} };
        } else if (std.mem.eql(u8, arg, "help")) {
            invocation.subcommand = .{ .help = {} };
        } else if (std.mem.eql(u8, arg, "version")) {
            invocation.subcommand = .{ .version = {} };
        } else {
            break;
        }
    }

    // Handle trailing unrecognized args
    if (current) |arg| {
        diagnostic.problem_arg = arg;
        return ParseError.UnrecognizedArgument;
    }

    return invocation;
}

/// Prints usage to the given writer.
///
/// If a subcommand is given, we print usage for that subcommand.
pub fn printUsage(
    out: *Io.Writer,
    opts: struct { subcommand: ?Subcommand = null },
) !void {
    if (opts.subcommand) |_| {
        return;
    }

    try out.writeAll(top_usage);
}
