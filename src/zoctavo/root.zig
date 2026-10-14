const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const compile_opts = @import("compile_opts");

pub const book = @import("book.zig");
pub const build = @import("build.zig");

/// Program version.
pub const version: []const u8 = compile_opts.version;

/// Filepath from which to load the ZON book config.
const book_zon_path = "book.zon";

pub const LoadConfigError = error{
    ReadFailed,
    ParseFailed,
} || Allocator.Error;

/// Load book config from expected filepath or return default book config if
/// file isn't present.
pub fn loadBookConfig(
    io: Io,
    alloc: Allocator,
    diag: ?*book.Diagnostics,
) LoadConfigError!book.Config {
    const config = book.loadZON(
        io,
        alloc,
        book_zon_path,
        diag,
    ) catch |err| blk: {
        switch (err) {
            book.LoadError.FileNotFound => break :blk book.Config{},
            else => |e| return e,
        }
    };

    return config;
}
