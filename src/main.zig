const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayList;

const zig_serial = @import("serial");
const rl = @import("raylib");

const proto = @import("./proto.zig");
const keymapping = @import("./keycodes.zig");

const c = @cImport({
    @cInclude("raymedia.h");
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

    const port_name = "/dev/ttyUSB1";

    var serial = try open_serial_port(port_name);
    defer serial.close();

    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "Nanokvm");
    rl.setTargetFPS(60);
    defer rl.closeWindow();

    var media = c.LoadMedia("test.mp4");
    defer c.UnloadMedia(&media);

    while (!rl.windowShouldClose()) {
        while (true) {
            const key = rl.getKeyPressed();
            if (key == .null) break;

            if (keymapping.get(key)) |value| {
                std.debug.print("{d}\n", .{get_modifier()});
                try proto.send_key_single(allocator, serial.writer(), get_modifier(), value);
            }
        }

        _ = c.UpdateMedia(&media);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.ray_white);
        rl.drawTextureEx(@as(*rl.Texture, @ptrCast(&media.videoTexture)).*, .{.x = 0, .y = 0}, 0, 0.5, .white);
        rl.drawText("Hello!", 10, 10, 20, .dark_gray);
    }

    return 0;
}
