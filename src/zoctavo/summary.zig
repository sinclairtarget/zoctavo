const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

/// A chapter entry.
pub const Chapter = struct {
    name: []const u8,
    /// Path to the md source file, relative to the src root.
    src_filepath: []const u8,
    subchapters: []Chapter,
    /// Whether this chapter should be numbered.
    enumerated: bool,
};

/// An entry in our index/summary.
///
/// Can be a chapter, break, or section heading.
pub const Entry = union(enum) {
    chapter: Chapter,
    thematic_break: void,
    section_heading: struct {
        text: []const u8,
    },
};

pub const Summary = struct {
    /// The path this summary was loaded from, relative to the src root.
    src_filepath: []const u8,
    entries: []Entry,
};

pub const LoadError = error{} || Allocator.Error;

/// Loads a summary from the given absolute filepath.
pub fn load(
    io: Io,
    alloc: Allocator,
    abs_filepath: []const u8,
) LoadError!Summary {
    _ = io;
    _ = abs_filepath;

    // Hard-code for now.
    const chapter_one: Entry = .{
        .chapter = .{
            .name = "A Long-Expected Party",
            .src_filepath = "chapter_01.md",
            .subchapters = &.{},
            .enumerated = true,
        },
    };

    const chapter_two: Entry = .{
        .chapter = .{
            .name = "Second Thoughts",
            .src_filepath = "chapter_02.md",
            .subchapters = &.{},
            .enumerated = true,
        },
    };

    const entries = try alloc.dupe(Entry, &.{chapter_one, chapter_two});
    return .{
        .src_filepath = "SUMMARY.md",
        .entries = entries,
    };
}
