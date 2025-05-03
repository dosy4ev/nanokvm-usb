const std = @import("std");
const mem = std.mem;

const Event = enum(u8) {
    get_info = 1,
    send_kbd_general_data,
};

const Packet = struct {
    header1: u8,
    header2: u8,
    addr: u8,
    cmd: u8,
    len: u8,
    data: []u8,
    sum: u8,

    pub fn calc_checksum(self: *Packet) void {
        var checksum : u32 = 0;
        checksum = checksum + self.header1 + self.header2 + self.addr + self.cmd + self.len;
        for (self.data) |val| {
            checksum += val;
        }
        self.sum = @truncate(checksum);
    }

    pub fn to_bytes(self: *Packet, allocator: mem.Allocator) ![]u8 {
        const total_len : usize = 6 + self.len;
        var packet = try allocator.alloc(u8 , total_len);
        packet[0] = self.header1;
        packet[1] = self.header2;
        packet[2] = self.addr;
        packet[3] = self.cmd;
        packet[4] = self.len;

        for (self.data, 0..) |d, i| {
            packet[5 + i] = d;
        }

        packet[5 + self.len] = self.sum;

        return packet;
    }
};

const KbdEvent = struct {
    modifier: u8,
    key: u8,

    pub fn to_bytes(self: *KbdEvent, allocator: mem.Allocator) ![]u8 {
        const data = [_]u8{ self.modifier, 0, 0, 0, self.key, 0, 0, 0 };
        return try allocator.dupe(u8, &data);
    }
};

fn send_key(allocator : mem.Allocator, writer : anytype, modifier : u8, key : u8) !void {
    var event = KbdEvent {
        .modifier = modifier,
        .key = key,
    };
    const event_data = try event.to_bytes(allocator);
    defer allocator.free(event_data);

    var packet = Packet {
        .header1 = 0x57,
        .header2 = 0xab,
        .addr = 0x0,
        .cmd = 0x02,
        .len = @truncate(event_data.len),
        .data = event_data,
        .sum = 0x0
    };
    packet.calc_checksum();
    const packet_data = try packet.to_bytes(allocator);
    defer allocator.free(packet_data);
    
    try writer.writeAll(packet_data);
}

pub fn send_key_single(allocator : mem.Allocator, writer : anytype, modifier : u8, key : u8) !void {
    try send_key(allocator, writer, modifier, key);
    try send_key(allocator, writer, 0, 0);
}
