const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const book = @import("book.zig");

/// Defines build parameters and location for the build.
pub const Workspace = struct {
    absolute_working_dir: []const u8,
    config: book.Config,

    fn resolveBuildDir(self: Workspace, alloc: Allocator) ![]const u8 {
        std.debug.assert(std.fs.path.isAbsolute(self.absolute_working_dir));
        return try std.fs.path.join(
            alloc,
            &.{ self.absolute_working_dir, self.config.build.dir },
        );
    }
};

pub const BuildError = error{
    CreateBuildDirectoryFailed,
} || Allocator.Error;

pub const CleanError = error{
    DeleteBuildDirectoryFailed,
} || Allocator.Error;

pub fn run(io: Io, alloc: Allocator, ws: Workspace) BuildError!void {
    const build_dir = try ws.resolveBuildDir(alloc);
    try ensureDir(io, build_dir);
}

pub fn clean(io: Io, alloc: Allocator, ws: Workspace) CleanError!void {
    try removeDirRecursive(io, try ws.resolveBuildDir(alloc));
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
