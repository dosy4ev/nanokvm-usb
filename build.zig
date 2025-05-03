const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "main",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const serial = b.dependency("serial", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("serial", serial.module("serial"));

    const raylib = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("raylib", raylib.module("raylib"));
    exe.linkLibrary(raylib.artifact("raylib"));

    b.installArtifact(exe);
}
