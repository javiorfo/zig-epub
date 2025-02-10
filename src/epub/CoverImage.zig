const std = @import("std");

path: []const u8,
image_type: ImageType,

const CoverImage = @This();

const ImageType = enum(u8) {
    jpg,
    png,
    svg,
    gif,
    tiff,
    bmp,
    webp,

    pub fn toString(self: ImageType) []const u8 {
        return switch (self) {
            inline else => |tag| @tagName(tag),
        };
    }
};
