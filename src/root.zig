const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const build_config = @import("config");

pub const config = @import("config.zig");
pub const build = @import("build.zig");

/// Program version.
pub const version: []const u8 = build_config.version;

/// Filepath from which to load the ZON book config.
const config_zon_path = "book.zon";

pub const LoadConfigError = error{
    ReadFailed,
    ParseFailed,
} || Allocator.Error;

/// Load config from expected filepath or return default config if file isn't
/// present.
pub fn loadConfig(
    io: Io,
    alloc: Allocator,
    diag: ?*config.Diagnostics,
) LoadConfigError!config.Config {
    const conf = config.loadZON(
        io,
        alloc,
        config_zon_path,
        diag,
    ) catch |err| blk: {
        switch (err) {
            config.LoadError.FileNotFound => break :blk config.Config{},
            else => |e| return e,
        }
    };

    return conf;
}
