const std = @import("std");

const zoctavo = @import("zoctavo");

pub fn main(init: std.process.Init) !void {
    _ = init;

    std.debug.print("version: {s}\n", .{zoctavo.version});
}
