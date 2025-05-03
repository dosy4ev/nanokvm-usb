const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayList;

const zig_serial = @import("serial");
const rl = @import("raylib");

const proto = @import("./proto.zig");

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const port_name = "/dev/ttyUSB1";

    var serial = std.fs.cwd().openFile(port_name, .{ .mode = .read_write }) catch |err| switch (err) {
        error.FileNotFound => {
            std.debug.print("{s} does not exist\n", .{port_name});
            return 1;
        },
        else => return err,
    };
    defer serial.close();

    try zig_serial.configureSerialPort(serial, zig_serial.SerialConfig{
        .baud_rate = 57600,
        .word_size = .eight,
        .parity = .none,
        .stop_bits = .one,
        .handshake = .none,
    });

    //try proto.send_key_single(allocator, serial.writer(), 0, 0x2c);

    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "Nanokvm");
    rl.setTargetFPS(60);
    defer rl.closeWindow();

    while (!rl.windowShouldClose()) {
        var keycodes = ArrayList(rl.KeyboardKey).init(allocator);
        inline for (std.meta.fields(rl.KeyboardKey)) |key| {
            const keycode : rl.KeyboardKey = @enumFromInt(key.value);
            if (rl.isKeyDown(keycode)) {
                try keycodes.append(keycode);
            }
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.ray_white);
        if (keycodes.items.len == 0) {
            rl.drawText("no keys were pressed", 10, 10, 20, .dark_gray);
        }
        for (keycodes.items, 0..) |_, i| {
            rl.drawText("keycode was pressed", 10, @intCast(20 * i + 10), 20, .dark_gray);
        } 
    }

    return 0;
}
