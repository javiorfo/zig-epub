const std = @import("std");

/// The file path of the cover image.
path: []const u8,

/// The type of the cover image.
image_type: ImageType,

const CoverImage = @This();

/// Represents the different types of cover images supported.
const ImageType = enum(u8) {
    jpg,
    jpeg,
    png,
    gif,

    /// Returns the string representation of the image type.
    pub fn toString(self: ImageType) []const u8 {
        return switch (self) {
            .jpg => "jpeg",
            inline else => |tag| @tagName(tag),
        };
    }
};
