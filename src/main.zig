const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayList;

const zig_serial = @import("serial");
const rl = @import("raylib");

const proto = @import("./proto.zig");
const keymapping = @import("./keycodes.zig");

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

    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "Nanokvm");
    rl.setTargetFPS(60);
    defer rl.closeWindow();

    while (!rl.windowShouldClose()) {
        while (true) {
            const key = rl.getKeyPressed();
            if (key == .null) break;

            if (keymapping.get(key)) |value| {
                try proto.send_key_single(allocator, serial.writer(), 0, value);
            }
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.ray_white);
        rl.drawText("Hello!", 10, 10, 20, .dark_gray);
    }

    return 0;
}
