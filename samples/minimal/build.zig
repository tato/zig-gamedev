const std = @import("std");

const Options = @import("../../build.zig").Options;

pub fn build(b: *std.Build, options: Options) *std.Build.CompileStep {
    const exe = b.addExecutable(.{
        .name = "minimal",
        .root_source_file = .{ .path = thisDir() ++ "/src/minimal.zig" },
        .target = options.target,
        .optimize = options.optimize,
    });

    exe.step.dependOn(
        &exe.builder.addInstallFile(
            .{ .path = thisDir() ++ "/../../libs/zwin32/bin/x64/D3D12Core.dll" },
            "bin/d3d12/D3D12Core.dll",
        ).step,
    );
    exe.step.dependOn(
        &exe.builder.addInstallFile(
            .{ .path = thisDir() ++ "/../../libs/zwin32/bin/x64/D3D12Core.pdb" },
            "bin/d3d12/D3D12Core.pdb",
        ).step,
    );
    exe.step.dependOn(
        &exe.builder.addInstallFile(
            .{ .path = thisDir() ++ "/../../libs/zwin32/bin/x64/D3D12SDKLayers.dll" },
            "bin/d3d12/D3D12SDKLayers.dll",
        ).step,
    );
    exe.step.dependOn(
        &exe.builder.addInstallFile(
            .{ .path = thisDir() ++ "/../../libs/zwin32/bin/x64/D3D12SDKLayers.pdb" },
            "bin/d3d12/D3D12SDKLayers.pdb",
        ).step,
    );

    const dxc_step = buildShaders(b);
    exe.step.dependOn(dxc_step);

    exe.rdynamic = true;

    return exe;
}

fn buildShaders(b: *std.Build) *std.Build.Step {
    const dxc_step = b.step("minimal-dxc", "Build shaders for 'minimal' demo");

    makeDxcCmd(b, dxc_step, "src/minimal.hlsl", "vsMinimal", "minimal.vs.cso", "vs", "");
    makeDxcCmd(b, dxc_step, "src/minimal.hlsl", "psMinimal", "minimal.ps.cso", "ps", "");

    return dxc_step;
}

fn makeDxcCmd(
    b: *std.Build,
    dxc_step: *std.Build.Step,
    comptime input_path: []const u8,
    comptime entry_point: []const u8,
    comptime output_filename: []const u8,
    comptime profile: []const u8,
    comptime define: []const u8,
) void {
    const shader_ver = "6_0";
    const shader_dir = thisDir() ++ "/src/";

    const dxc_command = [9][]const u8{
        if (@import("builtin").target.os.tag == .windows)
            thisDir() ++ "/../../libs/zwin32/bin/x64/dxc.exe"
        else if (@import("builtin").target.os.tag == .linux)
            thisDir() ++ "/../../libs/zwin32/bin/x64/dxc",
        thisDir() ++ "/" ++ input_path,
        "/E " ++ entry_point,
        "/Fo " ++ shader_dir ++ output_filename,
        "/T " ++ profile ++ "_" ++ shader_ver,
        if (define.len == 0) "" else "/D " ++ define,
        "/WX",
        "/Ges",
        "/O3",
    };

    const cmd_step = b.addSystemCommand(&dxc_command);
    if (@import("builtin").target.os.tag == .linux)
        cmd_step.setEnvironmentVariable("LD_LIBRARY_PATH", thisDir() ++ "/../../libs/zwin32/bin/x64");
    dxc_step.dependOn(&cmd_step.step);
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
