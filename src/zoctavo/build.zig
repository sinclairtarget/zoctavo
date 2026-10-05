const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const book = @import("book.zig");

pub fn run(io: Io, alloc: Allocator, config: book.Config) !void {
    _ = io;
    _ = alloc;
    _ = config;
}
