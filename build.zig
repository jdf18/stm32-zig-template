const std = @import("std");
const stm = @import("stm32-zig-build/stm32.zig");
const libopencm3 = @import("stm32-zig-build/libopencm3.zig");

const build_dir = "stm32-zig-build";

pub fn build(b: *std.Build) !void {
    const native_target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Configure STM32 chip being used
    const stm32_chip = try stm.get_stm32_chip(b, "stm32l452ret6");
    const stm32_target = b.resolveTargetQuery(stm32_chip.target);

    // Define what hardware the software will be built for
    const builds = [_]stm.TargetConfig{
        stm.TargetConfig{
            .name = "stm32",
            .kind = .stm32,
            .target = stm32_target,
            .flags = stm32_chip.flags,
        },
        stm.TargetConfig{
            .name = "native",
            .kind = .native,
            .target = native_target,
            .flags = &[_][]const u8{"-DNATIVE"},
        },
    };

    // Steps required for libopencm3
    const opencm3 = try libopencm3.libopencm3(b, stm32_chip);

    // Define default build step
    const build_all = b.step("build", "default build - builds for all targets");
    b.default_step = build_all;

    for (builds) |config| {
        // Create the executable and individual build step
        const exe_name = try std.fmt.allocPrint(b.allocator, "Project-template-{s}", .{config.name});
        const exe = b.addExecutable(.{
            .name = exe_name,
            .target = config.target,
            .optimize = optimize,
        });

        const build_single = b.step(switch (config.kind) {
            .stm32 => "target",
            .native => "native",
        }, switch (config.kind) {
            .stm32 => "Build the application for the target device only",
            .native => "Build the application for this machine only",
        });

        // Add source files to executable
        exe.addCSourceFiles(.{
            .root = b.path("src"),
            .files = &.{"main.cpp"},
            .flags = config.flags,
        });

        // Link libraries
        switch (config.kind) {
            .stm32 => {
                exe.addObjectFile(opencm3.@"1");
                exe.step.dependOn(opencm3.@"0");

                exe.addIncludePath(b.path(build_dir ++ "/libopencm3/include/"));

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

        // Configure build steps
        const install_step = b.addInstallArtifact(exe, .{});

        build_single.dependOn(&exe.step);
        build_single.dependOn(&install_step.step);

        build_all.dependOn(build_single);

        switch (config.kind) {
            .stm32 => {
                const flash_step = b.step("flash", "flash firmware onto the stm32");
                flash_step.dependOn(build_single);

                const run_flash = b.addSystemCommand(&.{"./scripts/flash.sh"});
                var firmware_path: []const u8 = try std.mem.concat(
                    b.allocator,
                    u8,
                    &[_][]const u8{ "zig-out/bin/", exe.out_filename },
                );
                defer b.allocator.free(firmware_path);
                run_flash.addArg(firmware_path);
                run_flash.addArg("target/stm32l4x.cfg");
                run_flash.step.dependOn(build_single);

                flash_step.dependOn(&run_flash.step);

                const debug_step = b.step("debug-target", "flash and debug firmware on the stm32");
                debug_step.dependOn(build_single);

                const run_flash_debug = b.addSystemCommand(&.{"./scripts/flash-debug.sh"});
                firmware_path = try std.mem.concat(
                    b.allocator,
                    u8,
                    &[_][]const u8{ "zig-out/bin/", exe.out_filename },
                );
                defer b.allocator.free(firmware_path);
                run_flash_debug.addArg(firmware_path);
                run_flash_debug.addArg("target/stm32l4x.cfg");
                run_flash_debug.step.dependOn(build_single);

                debug_step.dependOn(&run_flash_debug.step);
            },
            .native => {
                const run_step = b.step("run", "run the program natively");
                const run = b.addRunArtifact(exe);
                run_step.dependOn(build_single); // build and install
                run_step.dependOn(&run.step);

                const debug_step = b.step("debug", "debug the prorgam natively using gdb");
                debug_step.dependOn(build_single); // build and install

                const run_gdb = b.addSystemCommand(&.{"gdb"});
                const executable_path: []const u8 = try std.mem.concat(
                    b.allocator,
                    u8,
                    &[_][]const u8{ "zig-out/bin/", exe.out_filename },
                );
                defer b.allocator.free(executable_path);
                run_gdb.addArg(executable_path);
                debug_step.dependOn(&run_gdb.step);
            },
        }
    }

    // CLEAN STEP

    const clean = b.step("clean", "Remove cache and binary files");

    clean.dependOn(&b.addRemoveDirTree(b.path(".zig-cache/")).step);
    clean.dependOn(&b.addRemoveDirTree(b.path("zig-out/")).step);
    clean.dependOn(try libopencm3.clean(b));
}
