const std = @import("std");
const UUID = @import("UUID.zig");
const Section = @import("Section.zig");
const testing = std.testing;

allocator: std.mem.Allocator,
metadata: Metadata,
sections: ?[]Section = null,
// TODO
// stylesheets: []Stylesheet,
// images: []Image,

const Epub = @This();

pub fn init(allocator: std.mem.Allocator, metadata: Metadata) Epub {
    return .{
        .allocator = allocator,
        .metadata = metadata,
    };
}

const Metadata = struct {
    title: []const u8,
    creator: []const u8,
    identifier: []const u8,
    language: []const u8 = "en",
    date: ?[]const u8 = null,
    publisher: ?[]const u8 = null,
};

test "epub" {
    const uuid = UUID.new();
    const epub = Epub.init(testing.allocator, .{ .title = "test", .creator = "John", .identifier = uuid });
    try testing.expect(@TypeOf(epub) == Epub);
}
