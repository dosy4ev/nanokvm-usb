const std = @import("std");
const mem = std.mem;
const zig_serial = @import("serial");

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

    pub fn write(self: *const Packet, writer: anytype) !void {
        try writer.writeAll(&[_]u8{ self.header1, self.header2, self.addr, self.cmd, self.len, self.sum });
        //if (self.len > 0) {
        //    try writer.writeAll(self.data);
        //}
        //try writer.writeAll(&[_]u8{self.checksum});
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

    pub fn calc_checksum(self: *Packet) void {
        var checksum : u32 = 0;
        checksum = checksum + self.header1 + self.header2 + self.addr + self.cmd + self.len;
        for (self.data) |val| {
            checksum += val;
        }
        self.sum = @truncate(checksum);
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

    //var get_info_packet = Packet {
    //    .header1 = 0x57,
    //    .header2 = 0xab,
    //    .addr = 0x0,
    //    .cmd = 0x01,
    //    .len = 0x0,
    //    .data = &.{},
    //    .sum = 0x0
    //};
    //get_info_packet.calc_checksum();


    //try get_info_packet.write(serial.writer());

    try send_key(allocator, serial.writer(), 0, 0x2c);
    try send_key(allocator, serial.writer(), 0, 0);
    
    //var buf: [14]u8 = undefined;
    //const r = try serial.reader().readAll(&buf);

    //std.debug.print("read {d} bytes", .{r});
    //std.debug.print("{d}", .{buf});

    return 0;
}
