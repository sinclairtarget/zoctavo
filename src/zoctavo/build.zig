const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const book = @import("book.zig");

pub const BuildError = error{
    CreateBuildDirectoryFailed,
};

pub const CleanError = error{
    DeleteBuildDirectoryFailed,
};

pub fn run(io: Io, alloc: Allocator, config: book.Config) BuildError!void {
    _ = alloc;

    try ensureDir(io, config.build.dir);
}

pub fn clean(io: Io, config: book.Config) CleanError!void {
    try removeDirRecursive(io, config.build.dir);
}

/// Ensure the given directory exists.
fn ensureDir(io: Io, dirpath: []const u8) !void {
    const cwd = Io.Dir.cwd();
    cwd.createDir(io, dirpath, .fromMode(0o755)) catch |err| {
        switch (err) {
            Io.Dir.CreateDirError.PathAlreadyExists => {},
            else => return BuildError.CreateBuildDirectoryFailed,
        }
    };
}

/// Recursively remove the given directory.
fn removeDirRecursive(io: Io, dirpath: []const u8) !void {
    const cwd = Io.Dir.cwd();
    cwd.deleteTree(io, dirpath) catch {
        return CleanError.DeleteBuildDirectoryFailed;
    };
}
