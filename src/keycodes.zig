const std = @import("std");
const rl = @import("raylib");

pub fn get(key: rl.KeyboardKey) ?u8 {
    return switch(key) {
        .a => 0x04,
        .b => 0x05,
        .c => 0x06,
        .d => 0x07,
        .e => 0x08,
        .f => 0x09,
        .g => 0x0a,
        .h => 0x0b,
        .i => 0x0c,
        .j => 0x0d,
        .k => 0x0e,
        .l => 0x0f,
        .m => 0x10,
        .n => 0x11,
        .o => 0x12,
        .p => 0x13,
        .q => 0x14,
        .r => 0x15,
        .s => 0x16,
        .t => 0x17,
        .u => 0x18,
        .v => 0x19,
        .w => 0x1a,
        .x => 0x1b,
        .y => 0x1c,
        .z => 0x1d,

        .space => 0x2c,

        else => null,
    };
}
