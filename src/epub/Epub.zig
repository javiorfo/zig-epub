const std = @import("std");
const UUID = @import("../util/UUID.zig");
const Section = @import("Section.zig");
const Body = @import("../util/body.zig").Body;
const Stylesheet = @import("Stylesheet.zig");
const Cover = @import("Cover.zig");
const Metadata = @import("Metadata.zig");
const testing = std.testing;

allocator: std.mem.Allocator,
metadata: Metadata,
sections: ?std.ArrayList(Section) = null,
stylesheet: ?Stylesheet = null,
cover: ?Cover = null,
images: ?[][]const u8 = null,

const Epub = @This();

pub fn init(allocator: std.mem.Allocator, metadata: Metadata) Epub {
    return .{
        .allocator = allocator,
        .metadata = metadata,
    };
}

pub fn deinit(self: *Epub) void {
    self.sections.?.deinit();
}

pub fn addSection(self: *Epub, name: []const u8, body: Body) *Epub {
    if (self.sections == null) self.sections = std.ArrayList(Section).init(self.allocator);

    self.sections.?.append(Section.create(self.allocator, name, body)) catch {
        std.log.err("Error adding section {s}", .{name});
    };
    return self;
}

pub fn addStylesheet(self: *Epub, body: Body) *Epub {
    self.stylesheet = Stylesheet.create(self.allocator, body);
    return self;
}

pub fn addImages(self: *Epub, paths: [][]const u8) *Epub {
    self.images = paths;
    return self;
}

pub fn addCover(self: *Epub, body: Body) *Epub {
    self.cover = Cover.create(self.allocator, body, null);
    return self;
}

pub fn addCoverWithImage(self: *Epub, body: Body, image_path: []const u8) *Epub {
    self.cover = Cover.create(self.allocator, body, image_path);
    return self;
}

pub fn generate(self: *Epub, epub_path: []const u8) !void {
    // TODO if stylesheet and cover are not null
    // check if name has .epub ext
    _ = self;
    _ = epub_path;
}

test "epub" {
    const allocator = testing.allocator;

    const uuid = UUID.new();
    var epub = Epub.init(allocator, .{ .title = "test", .creator = "John", .identifier = .{ .identifier_type = .UUID, .value = uuid } });
    defer epub.deinit();

    var mock_images_paths = [_][]const u8{
        "/path/to/img1.jpg",
        "/path/to/img2.jpg",
    };

    try epub
        .addStylesheet(.{ .raw = "body { background: '#808080' }" })
        .addCoverWithImage(.{ .raw = "<h1>title</h1>" }, "/path/to/img.png")
        .addImages(&mock_images_paths)
        .addSection("chapter1", .{ .raw = "<p>test</p>" })
        .addSection("chapter2", .{ .raw = "<p>test</p>" })
        .generate("MyEpub");

    try testing.expect(@TypeOf(epub) == Epub);
}
