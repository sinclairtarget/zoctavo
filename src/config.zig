const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

/// Configuration for a book.
pub const Config = struct {
    /// Overall title for book.
    title: []const u8,

    pub const default: Config = .{
        .title = "My Zoctavo Book",
    };
};

pub const LoadError = error{
    FileNotFound,
    ReadFailed,
    ParseFailed,
} || Allocator.Error;

pub const Diagnostics = struct {
    /// The filepath we attempted to read.
    filepath: ?[]const u8 = null,
    /// Underlying error if we failed to open the file.
    sub_error: ?Io.Dir.ReadFileAllocError = null,
};

/// Loads config from ZON file at runtime.
///
/// Caller owns the returned object.
pub fn loadZON(
    io: Io,
    alloc: Allocator,
    filepath: []const u8,
    diag: ?*Diagnostics,
) LoadError!Config {
    if (diag) |d| {
        d.filepath = filepath;
    }

    const contents = Io.Dir.readFileAllocOptions(
        Io.Dir.cwd(),
        io,
        filepath,
        alloc,
        .unlimited,
        .of(u8),
        0,
    ) catch |err| {
        switch (err) {
            Io.File.OpenError.FileNotFound,
            Allocator.Error.OutOfMemory,
            => |e| return e,
            else => {
                if (diag) |d| {
                    d.sub_error = err;
                }
                return LoadError.ReadFailed;
            },
        }
    };
    defer alloc.free(contents);

    const config = std.zon.parse.fromSliceAlloc(
        Config,
        alloc,
        contents,
        null,
        .{ .ignore_unknown_fields = true },
    ) catch |err| {
        switch (err) {
            Allocator.Error.OutOfMemory => |e| return e,
            error.ParseZon => return LoadError.ParseFailed,
        }
    };

    return config;
}
