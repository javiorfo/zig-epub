const std = @import("std");

const encoded_pos = [16]u8{ 0, 2, 4, 6, 9, 11, 14, 16, 19, 21, 24, 26, 28, 30, 32, 34 };
const hex = "0123456789abcdef";

pub fn new() []const u8 {
    var bytes: [16]u8 = undefined;
    //     const seed: u64 = @intCast(@as(i128, @bitCast(std.time.nanoTimestamp())));
    //     var prng = std.rand.DefaultPrng.init(seed);
    //     prng.random().bytes(&bytes);

    std.crypto.random.bytes(&bytes);

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    var buffer: [36]u8 = undefined;
    buffer[8] = '-';
    buffer[13] = '-';
    buffer[18] = '-';
    buffer[23] = '-';
    inline for (encoded_pos, 0..) |i, j| {
        buffer[i + 0] = hex[bytes[j] >> 4];
        buffer[i + 1] = hex[bytes[j] & 0x0f];
    }

    return &buffer;
}

test "uuid" {
    const uuid = new();
    try std.testing.expect(uuid.len == 36);
    try std.testing.expect(uuid[8] == '-');
    try std.testing.expect(uuid[13] == '-');
    try std.testing.expect(uuid[18] == '-');
    try std.testing.expect(uuid[23] == '-');
}
