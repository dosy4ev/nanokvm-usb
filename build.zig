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

    const raylib_shared = true;
    const raylib = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
        .shared = raylib_shared,
    });
    exe.root_module.addImport("raylib", raylib.module("raylib"));
    if (raylib_shared) {
        exe.linkSystemLibrary("raylib");
    } else {
        exe.linkLibrary(raylib.artifact("raylib"));
    }

    const raylib_media = b.addStaticLibrary(.{
        .name = "raylib-media",
        .target = target,
        .optimize = optimize,
    });
    const raylib_media_dep = b.dependency("raylib-media", .{
        .target = target,
        .optimize = optimize,
    });
    raylib_media.addCSourceFiles(.{
        .root = raylib_media_dep.path("src"),
        .files = &.{"rmedia.c"},
    });
    // todo raylib media should use "" for raymedia.h instead of <>
    raylib_media.addSystemIncludePath(raylib_media_dep.path("src"));
    raylib_media.installHeadersDirectory(raylib_media_dep.path("src"), "", .{
        .include_extensions = &.{"raymedia.h"},
    });
    raylib_media.linkLibC();
    exe.linkLibrary(raylib_media);
    exe.linkSystemLibrary("avcodec");
    exe.linkSystemLibrary("avformat");
    exe.linkSystemLibrary("avutil");
    exe.linkSystemLibrary("swresample");
    exe.linkSystemLibrary("swscale");

    b.installArtifact(exe);
}
