const std = @import("std");

const stm = @import("stm32-zig-build/stm32.zig");
const libopencm3 = @import("stm32-zig-build/libopencm3.zig");
const build_dir = "stm32-zig-build";

pub fn build(b: *std.Build) !void {

    // ===== RESOLVE POSSIBLE TARGETS =====

    const native_target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Configure STM32 chip being used
    const stm32_chip = try stm.get_stm32_chip(b, "stm32l452ret6");
    const stm32_target = b.resolveTargetQuery(stm32_chip.target);

    // ===== ADD LIBRARIES AND DEPENDANCIES ======

    const opencm3 = try libopencm3.libopencm3(b, stm32_chip);

    // ===== DEFAINE GLOBAL BUILD STEPS

    const build_all = b.step("all", "default build - builds for all targets");
    const build_all_release = b.step("release", "builds all release builds");
    const build_all_tests = b.step("tests", "builds all tests");

    b.default_step = build_all;

    // ===== DEFINE ALL BUILD CONFIGURATIONS =====

    const builds = try generate_configs(b, stm32_target, stm32_chip, native_target);

    // ===== CREATE THE BUILD TREE FOR EACH CONFIG =====

    for (builds) |config| {
        // Create the executable and individual build step
        const exe_name = try std.fmt.allocPrint(b.allocator, "Project-template-{s}", .{config.name});
        const exe = b.addExecutable(.{
            .name = exe_name,
            .root_module = b.createModule(.{
                .target = config.target,
                .optimize = optimize,
            }),
        });

        const build_current = b.step(config.name, switch (config.kind) {
            .stm32 => "Build the application for the target device only",
            .native => "Build the application for this machine only",
        });

        // ===== ADD MAIN SOURCE FILES =====

        exe.addCSourceFiles(.{
            .root = b.path("src"),
            .files = &.{
                "main.cpp",
            },
            .flags = config.flags,
        });
        exe.addIncludePath(b.path("src/"));

        // ===== LINK LIBRARIES =====

        switch (config.kind) {
            .stm32 => {
                // Link libopencm3
                exe.addObjectFile(opencm3.@"1");
                exe.step.dependOn(opencm3.@"0");

                exe.addIncludePath(b.path(build_dir ++ "/libopencm3/include/"));

                // Generate and use the linker script provided by libopencm3
                exe.setLinkerScript(
                    try libopencm3.processLinkerScript(b, stm32_chip.defines),
                );
                exe.entry = .{ .symbol_name = "reset_handler" };
            },
            .native => {
                exe.linkLibC();
                exe.linkLibCpp();
            },
        }

        // ===== ADD TO GLOBAL BUILD STEPS =====

        const install_step = b.addInstallArtifact(exe, .{});

        build_current.dependOn(&exe.step);
        build_current.dependOn(&install_step.step);

        build_all.dependOn(build_current);
        if (config.is_test) {
            build_all_tests.dependOn(build_current);
        } else {
            build_all_release.dependOn(build_current);
        }
    }

    // ===== CLEAN STEP ======

    const clean = b.step("clean", "Remove cache and binary files");

    clean.dependOn(&b.addRemoveDirTree(b.path(".zig-cache/")).step);
    clean.dependOn(&b.addRemoveDirTree(b.path("zig-out/")).step);
    clean.dependOn(try libopencm3.clean(b));
}

fn generate_configs(b: *std.Build, stm32_target: std.Build.ResolvedTarget, stm32_chip: stm.STM32Chip, native_target: std.Build.ResolvedTarget) ![]stm.TargetConfig {

    // ===== LIST OF TEST PROGRAMS TO BE GENERATED =====

    const tests = [_][]const u8{
        "blink",
    };

    // ===== CREATE THE RELEASE TARGET AND NATIVE CONFIGS =====

    var configs = std.ArrayList(stm.TargetConfig).empty;
    try configs.append(
        b.allocator,
        stm.TargetConfig{
            .name = "stm32",
            .kind = .stm32,
            .target = stm32_target,
            .flags = stm32_chip.flags,
        },
    );
    try configs.append(
        b.allocator,
        stm.TargetConfig{
            .name = "native",
            .kind = .native,
            .target = native_target,
            .flags = &[_][]const u8{"-DNATIVE"},
        },
    );

    //  ===== ADD TARGET AND NATIVE TEST BUILDS =====

    for (tests) |test_name| {
        const flags = [_][]const u8{ "-DTEST", try std.fmt.allocPrint(b.allocator, "{s}{s}", .{ "-DTEST_", test_name }) };
        try configs.append(
            b.allocator,
            stm.TargetConfig{
                .name = try std.fmt.allocPrint(b.allocator, "stm32-test-{s}", .{test_name}),
                .kind = .stm32,
                .target = stm32_target,
                .flags = try stm.concatSlices(
                    b.allocator,
                    stm32_chip.flags,
                    &flags,
                ),
                .is_test = true,
            },
        );
        try configs.append(
            b.allocator,
            stm.TargetConfig{
                .name = try std.fmt.allocPrint(b.allocator, "native-test-{s}", .{test_name}),
                .kind = .native,
                .target = native_target,
                .flags = try stm.concatSlices(
                    b.allocator,
                    &[_][]const u8{"-DNATIVE"},
                    &flags,
                ),
                .is_test = true,
            },
        );
    }
    return try configs.toOwnedSlice(b.allocator);
}
