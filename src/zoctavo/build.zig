const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const book = @import("book.zig");

pub const Error = error{
    CreateBuildDirectoryFailed,
};

pub fn run(io: Io, alloc: Allocator, config: book.Config) Error!void {
    _ = alloc;

    try ensureBuildDir(io, config.build.dir);
}

/// Ensure the build output dir exists.
fn ensureBuildDir(io: Io, dirpath: []const u8) !void {
    const cwd = Io.Dir.cwd();
    cwd.createDir(io, dirpath, .fromMode(0o755)) catch |err| {
        switch (err) {
            Io.Dir.CreateDirError.PathAlreadyExists => {},
            else => return Error.CreateBuildDirectoryFailed,
        }
    };
}
