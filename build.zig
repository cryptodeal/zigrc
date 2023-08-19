const std = @import("std");
const builtin = @import("builtin");

const Target = std.Target;
const CrossTarget = std.zig.CrossTarget;

const Arch = Target.Cpu.Arch;
const Os = Target.Os.Tag;

pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const coverage = b.option(bool, "coverage", "Generate test coverage") orelse false;

    // Docs
    const docs = b.addStaticLibrary(.{
        .name = "zigrc",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(docs);

    const main_module = b.addModule("zigrc", .{
        .source_file = .{ .path = "src/main.zig" },
    });

    // Tests
    const main_tests = b.addTest(.{
        .root_source_file = main_module.source_file,
        .target = target,
        .optimize = optimize,
    });
    const run_main_tests = b.addRunArtifact(main_tests);

    if (coverage) {
        main_tests.setExecCmd(&[_]?[]const u8{
            "kcov",
            "--include-pattern=src/main.zig,src/tests.zig",
            "kcov-out",
            null, // to get zig to use the --test-cmd-bin flag
        });
    }

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);

    // Examples
    const example = b.addTest(.{
        .root_source_file = .{ .path = "src/example.zig" },
    });
    const run_example = b.addRunArtifact(example);
    const example_step = b.step("example", "Run library example");
    example_step.dependOn(&run_example.step);
}
