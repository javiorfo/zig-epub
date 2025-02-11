const std = @import("std");

path: []const u8,
image_type: ImageType,

const CoverImage = @This();

const ImageType = enum(u8) {
    jpg,
    jpeg,
    png,
    gif,

    pub fn toString(self: ImageType) []const u8 {
        return switch (self) {
            .jpg => "jpeg",
            inline else => |tag| @tagName(tag),
        };
    }
};
