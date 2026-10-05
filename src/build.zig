const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Config = @import("config.zig").Config;

pub fn run(io: Io, alloc: Allocator, config: Config) !void {
    _ = io;
    _ = alloc;
    _ = config;
}
