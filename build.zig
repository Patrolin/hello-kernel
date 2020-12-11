const std = @import("std");
const builtin = std.builtin;
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target: std.zig.CrossTarget = .{
        .cpu_arch = .i386,
        .os_tag = .freestanding,
    };

    const exe = b.addExecutable("kernel.bin", "src/kernel.zig");
    exe.setLinkerScriptPath("src/kernel.ld");
    exe.setBuildMode(mode);
    exe.setTarget(target);
    exe.strip = true;
    b.installArtifact(exe);

    const copy = b.addSystemCommand(&[_][]const u8{
        "cp", "zig-cache/bin/kernel.bin", "iso/boot",
    });
    copy.step.dependOn(&exe.step);

    // note: GRUB has evil GPL license
    const iso = b.addSystemCommand(&[_][]const u8{
        "grub-mkrescue", "--output=dist/os.iso", "iso"
    });
    iso.step.dependOn(&copy.step);

    b.default_step.dependOn(&iso.step);


    const qemu = b.addSystemCommand(&[_][]const u8{
        "qemu-system-i386", "-cdrom", "dist/os.iso",
    });
    qemu.step.dependOn(&iso.step);

    const run_step = b.step("run", "run OS in QEMU");
    run_step.dependOn(&qemu.step);
}
