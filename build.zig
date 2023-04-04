const std = @import("std");
const mach_core = @import("libs/mach-core/build.zig");
const core = mach_core.core;
const gpu_dawn = mach_core.gpu_dawn;
const imgui = @import("libs/imgui/build.zig");
const zmath = @import("libs/zmath/build.zig");

pub const Options = struct {
    core: core.Options = .{},
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const options = Options{ .core = .{
        .gpu_dawn_options = .{
            .from_source = b.option(bool, "dawn-from-source", "Build Dawn from source") orelse false,
            .debug = b.option(bool, "dawn-debug", "Use a debug build of Dawn") orelse false,
        },
    } };

    try ensureDependencies(b.allocator);

    const app_name = "falcon-slicer";

    const zmath_dependency = std.Build.ModuleDependency{
        .name = "zmath",
        .module = zmath.Package.build(b, .{
            .options = .{ .enable_cross_platform_determinism = true },
        }).zmath,
    };

    const imgui_pkg = imgui.Package(.{
        .gpu_dawn = gpu_dawn,
    }).build(b, target, optimize, .{
        .options = .{ .backend = .mach },
    }) catch unreachable;

    const imgui_dependency = std.Build.ModuleDependency{
        .name = "imgui",
        .module = imgui_pkg.zgui,
    };

    var deps = std.ArrayList(std.Build.ModuleDependency).init(b.allocator);
    try deps.append(zmath_dependency);
    try deps.append(imgui_dependency);

    // Add: .version = .{ .major = 0, .minor = 1, .patch = 0 },
    const app = try core.App.init(
        b,
        .{
            .name = app_name,
            .src = "src/main.zig",
            .target = target,
            .optimize = optimize,
            .deps = deps.items,
            .res_dirs = null,
            .watch_paths = &.{"/src"},
        },
    );

    imgui_pkg.link(app.step);

    try app.link(options.core);

    const flags = [_][]const u8{
        "-Wall",
        "-Wextra",
        "-Werror=return-type",
    };
    const cflags = flags ++ [_][]const u8{
        "-std=c99",
    };
    app.step.addCSourceFile("libs/zip/src/zip.c", &cflags);
    app.step.addIncludePath("libs/zip/src");
    app.step.linkLibC();

    app.install();

    const compile_step = b.step(app_name, "Compile " ++ app_name);
    compile_step.dependOn(&app.getInstallStep().?.step);

    const run_cmd = app.run();
    run_cmd.step.dependOn(compile_step);
    const run_step = b.step("run-" ++ app_name, "Run " ++ app_name);
    run_step.dependOn(&run_cmd.step);
}

pub fn copyFile(src_path: []const u8, dst_path: []const u8) void {
    std.fs.cwd().makePath(std.fs.path.dirname(dst_path).?) catch unreachable;
    std.fs.cwd().copyFile(src_path, std.fs.cwd(), dst_path, .{}) catch unreachable;
}

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}

fn ensureDependencies(allocator: std.mem.Allocator) !void {
    ensureGit(allocator);
    try ensureSubmodule(allocator, "libs/mach-glfw");
    try ensureSubmodule(allocator, "libs/mach-gpu");
    try ensureSubmodule(allocator, "libs/mach-gpu-dawn");
    try ensureSubmodule(allocator, "libs/imgui");
    try ensureSubmodule(allocator, "libs/zmath");
}

fn ensureSubmodule(allocator: std.mem.Allocator, path: []const u8) !void {
    if (std.process.getEnvVarOwned(allocator, "NO_ENSURE_SUBMODULES")) |no_ensure_submodules| {
        defer allocator.free(no_ensure_submodules);
        if (std.mem.eql(u8, no_ensure_submodules, "true")) return;
    } else |_| {}
    var child = std.ChildProcess.init(&.{ "git", "submodule", "update", "--init", path }, allocator);
    child.cwd = sdkPath("/");
    child.stderr = std.io.getStdErr();
    child.stdout = std.io.getStdOut();

    _ = try child.spawnAndWait();
}

fn ensureGit(allocator: std.mem.Allocator) void {
    const result = std.ChildProcess.exec(.{
        .allocator = allocator,
        .argv = &.{ "git", "--version" },
    }) catch { // e.g. FileNotFound
        std.log.err("mach: error: 'git --version' failed. Is git not installed?", .{});
        std.process.exit(1);
    };
    defer {
        allocator.free(result.stderr);
        allocator.free(result.stdout);
    }
    if (result.term.Exited != 0) {
        std.log.err("mach: error: 'git --version' failed. Is git not installed?", .{});
        std.process.exit(1);
    }
}
