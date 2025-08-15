const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mod = b.addModule("spirv_reflect", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const spirv_reflect = b.dependency("SPIRV-Reflect", .{});
    mod.addCSourceFile(.{
        .file = spirv_reflect.path("spirv_reflect.c"),
    });
    if (optimize == .Debug or optimize == .ReleaseSafe) {
        mod.addCMacro("SPIRV_REFLECT_ENABLE_ASSERTS", "1");
    }

    const tests = b.addTest(.{
        .root_source_file = b.path("src/tests.zig"),
    });
    tests.root_module.addImport("spirv_reflect", mod);
    tests.root_module.addIncludePath(spirv_reflect.path("."));

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
