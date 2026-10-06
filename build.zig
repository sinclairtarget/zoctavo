const std = @import("std");
const pkg_zon = @import("build.zig.zon");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const atrus = b.dependency("atrus", .{ .target = target });

    const utils_module = b.createModule(.{
        .root_source_file = b.path("lib/utils/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zoctavo_module = b.addModule("zoctavo", .{
        .root_source_file = b.path("lib/zoctavo/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "utils", .module = utils_module },
        },
    });

    const options = b.addOptions();
    options.addOption([]const u8, "version", pkg_zon.version);
    zoctavo_module.addOptions("compile_opts", options);

    const exe = b.addExecutable(.{
        .name = "zoctavo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zoctavo", .module = zoctavo_module },
                .{ .name = "atrus", .module = atrus.module("atrus") },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    // By making the run step depend on the default step, it will be run from
    // the installation directory rather than directly from within the cache
    // directory.
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
