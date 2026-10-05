const std = @import("std");

const atrus = @import("atrus");
const zoctavo = @import("zoctavo");

pub fn main(init: std.process.Init) !void {
    _ = init;

    std.debug.print("version: {s}\n", .{zoctavo.version});
    std.debug.print("atrus version: {s}\n", .{atrus.version});
}
