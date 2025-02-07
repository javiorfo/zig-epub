const std = @import("std");
const UUID = @import("UUID.zig");
const Section = @import("Section.zig");
const Body = @import("body.zig").Body;
const Stylesheet = @import("Stylesheet.zig");
const Cover = @import("Cover.zig");
const testing = std.testing;

allocator: std.mem.Allocator,
metadata: Metadata,
sections: std.ArrayList(Section),
stylesheet: ?Stylesheet = null,
cover: ?Cover = null,
// TODO
// images: []Image,

const Epub = @This();

pub fn init(allocator: std.mem.Allocator, metadata: Metadata) Epub {
    return .{
        .allocator = allocator,
        .metadata = metadata,
        .sections = std.ArrayList(Section).init(allocator),
    };
}

pub fn deinit(self: *Epub) void {
    self.sections.deinit();
}

pub fn addSection(self: *Epub, name: []const u8, body: Body) *Epub {
    self.sections.append(Section.create(self.allocator, name, body)) catch {
        std.log.err("Error adding section {s}", .{name});
    };
    return self;
}

pub fn addStylesheet(self: *Epub, body: Body) *Epub {
    self.stylesheet = Stylesheet.create(self.allocator, body);
    return self;
}

pub fn addCover(self: *Epub, body: Body) *Epub {
    self.stylesheet = Cover.create(self.allocator, body, null);
    return self;
}

pub fn addCoverWithImage(self: *Epub, body: Body, image_path: []const u8) *Epub {
    self.cover = Cover.create(self.allocator, body, image_path);
    return self;
}

pub fn generate(self: *Epub) !void {
    // TODO if stylesheet and cover are not null
    _ = self;
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
    const allocator = testing.allocator;

    const uuid = UUID.new();
    var epub = Epub.init(allocator, .{ .title = "test", .creator = "John", .identifier = uuid });
    defer epub.deinit();

    try epub
        .addStylesheet(.{ .raw = "body { background: '#808080' }" })
        .addCoverWithImage(.{ .raw = "<h1>title</h1>" }, "/path/to/img.png")
        .addSection("ch1", .{ .raw = "<p>test</p>" })
        .addSection("ch2", .{ .raw = "<p>test</p>" })
        .generate();

    try testing.expect(@TypeOf(epub) == Epub);
}
