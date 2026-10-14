const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const utils = @import("utils");

const book = @import("book.zig");
const summary = @import("summary.zig");
const logger = @import("logging.zig").logger;

/// Defines build parameters and location for the build.
pub const Workspace = struct {
    absolute_working_dir: []const u8,
    config: book.Config,

    /// Returns an absolute path to the build directory.
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
    OpenBuildDirectoryFailed,
    OpenFileFailed,
} || Allocator.Error || Io.Writer.Error;

pub const CleanError = error{
    DeleteBuildDirectoryFailed,
} || Allocator.Error;

/// Run a build.
pub fn run(io: Io, alloc: Allocator, ws: Workspace) BuildError!void {
    logger.debug("Running build!", .{});

    const build_dirpath = try ws.resolveBuildDir(alloc);
    try ensureDir(io, build_dirpath);

    var build_dir = Io.Dir.openDirAbsolute(io, build_dirpath, .{}) catch {
        return BuildError.OpenBuildDirectoryFailed;
    };
    defer build_dir.close(io);

    // For each summary entry, write placeholder HTML doc.
    const summ = try summary.load(io, alloc, "foobar");
    for (summ.entries) |entry| {
        switch (entry) {
            .chapter => |chapter| {
                const dest_filepath = try utils.path.replaceExtAlloc(
                    alloc,
                    chapter.src_filepath,
                    ".md",
                    ".html",
                );
                writeIndex(io, build_dir, dest_filepath) catch |err| {
                    switch (err) {
                        Io.Writer.Error.WriteFailed => |e| return e,
                        else => return BuildError.OpenFileFailed,
                    }
                };
            },
            else => @panic("unhandled entry type"),
        }
    }
}

/// Clear build output directory.
pub fn clean(io: Io, alloc: Allocator, ws: Workspace) CleanError!void {
    try removeDirRecursive(io, try ws.resolveBuildDir(alloc));
}

/// Ensure the given directory exists.
fn ensureDir(io: Io, dirpath: []const u8) !void {
    Io.Dir.createDirAbsolute(io, dirpath, .fromMode(0o755)) catch |err| {
        switch (err) {
            Io.Dir.CreateDirError.PathAlreadyExists => {},
            else => return BuildError.CreateBuildDirectoryFailed,
        }
    };
}

fn writeIndex(io: Io, dir: Io.Dir, filepath: []const u8) !void {
    const s =
        \\<!DOCTYPE html>
        \\<html>
        \\  <head>
        \\  </head>
        \\  <body>
        \\    <p>Hello, world!</p>
        \\  </body>
        \\</html>
        \\
    ;

    var out_file = try dir.createFile(io, filepath, .{ .truncate = true });
    defer out_file.close(io);

    var out_buf: [128]u8 = undefined;
    var out_file_writer = out_file.writer(io, &out_buf);
    var out = &out_file_writer.interface;

    _ = try out.writeAll(s);
    try out.flush();
}

/// Recursively remove the given directory.
fn removeDirRecursive(io: Io, dirpath: []const u8) !void {
    std.debug.assert(std.fs.path.isAbsolute(dirpath));

    const cwd = Io.Dir.cwd();
    cwd.deleteTree(io, dirpath) catch {
        return CleanError.DeleteBuildDirectoryFailed;
    };
}
