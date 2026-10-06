const std = @import("std");
const Allocator = std.mem.Allocator;

/// Replaces existing extension with a new one. Asserts that the given filepath
/// indeed has the original extension.
///
/// Caller owns the returned slice.
pub fn replaceExtAlloc(
    alloc: Allocator,
    filepath: []const u8,
    original_ext: []const u8,
    replacement_ext: []const u8,
) ![]const u8 {
    const actual_ext = std.fs.path.extension(filepath);
    std.debug.assert(std.mem.eql(u8, actual_ext, original_ext));

    const stem = filepath[0 .. filepath.len - original_ext.len];
    return try std.mem.concat(alloc, u8, &.{ stem, replacement_ext });
}
