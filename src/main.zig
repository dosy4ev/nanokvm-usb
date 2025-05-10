const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayList;

const zig_serial = @import("serial");
const rl = @import("raylib");

const proto = @import("./proto.zig");
const keymapping = @import("./keycodes.zig");

const c = @cImport({
    @cInclude("raymedia.h");
    @cInclude("libavformat/avformat.h");
    @cInclude("libavdevice/avdevice.h");
    @cInclude("libavutil/dict.h");
});

fn open_serial_port(port_name : []const u8) !std.fs.File {
    var serial = std.fs.openFileAbsolute(port_name, .{ .mode = .read_write }) catch |err| switch (err) {
        error.FileNotFound => {
            std.debug.print("{s} does not exist\n", .{port_name});
            return err;
        },
        else => return err,
    };
    errdefer serial.close();

    try zig_serial.configureSerialPort(serial, zig_serial.SerialConfig{
        .baud_rate = 57600,
        .word_size = .eight,
        .parity = .none,
        .stop_bits = .one,
        .handshake = .none,
    });

    return serial;
}

pub fn get_modifier() u8 {
    const modifier = keymapping.Modifier{
	.left_control = rl.isKeyDown(rl.KeyboardKey.left_control), 
	.left_shift = rl.isKeyDown(rl.KeyboardKey.left_shift), 
	.left_alt = rl.isKeyDown(rl.KeyboardKey.left_alt), 
	.left_super = rl.isKeyDown(rl.KeyboardKey.left_super), 
	.right_control = rl.isKeyDown(rl.KeyboardKey.right_control), 
	.right_shift = rl.isKeyDown(rl.KeyboardKey.right_shift), 
	.right_alt = rl.isKeyDown(rl.KeyboardKey.right_alt), 
	.right_super = rl.isKeyDown(rl.KeyboardKey.right_super), 
    };

    return modifier.as_u8();
}

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);

    if (argv.len < 3) {
        std.debug.print("Usage: {s} serial_port video_device\n", .{argv[0]});
        return 1;
    }

    const port_name = argv[1];
    const video_dev = argv[2];

    var serial = try open_serial_port(port_name);
    defer serial.close();

    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "Nanokvm");
    rl.setTargetFPS(60);
    rl.setWindowState(rl.ConfigFlags{
        .window_resizable = true,
    });
    defer rl.closeWindow();

    c.avdevice_register_all();

    var media = c.LoadMedia(video_dev);
    defer c.UnloadMedia(&media);

    while (!rl.windowShouldClose()) {
        while (true) {
            const key = rl.getKeyPressed();
            if (key == .null) break;

            if (keymapping.get(key)) |value| {
                try proto.send_key_single(allocator, serial.writer(), get_modifier(), value);
            }
        }

        _ = c.UpdateMedia(&media);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.ray_white);

        const source_rec = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(media.videoTexture.width),
            .height = @floatFromInt(media.videoTexture.height),
        };
        const dest_rec = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(rl.getScreenWidth()),
            .height = @floatFromInt(rl.getScreenHeight()),
        };
        rl.drawTexturePro(@as(*rl.Texture, @ptrCast(&media.videoTexture)).*, source_rec, dest_rec, .{.x = 0, .y = 0}, 0, .white);
    }

    return 0;
}
