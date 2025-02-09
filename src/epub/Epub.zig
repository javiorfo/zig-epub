const std = @import("std");
const UUID = @import("../util/UUID.zig");
const Section = @import("Section.zig");
const Body = @import("../util/body.zig").Body;
const output = @import("../util/output.zig");
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
    if (self.sections) |s| s.deinit();
}

pub fn addSection(self: *Epub, title: []const u8, body: Body) *Epub {
    return self.addSectionWithReferenceType(title, Section.ReferenceType.Text, body);
}

pub fn addSectionWithReferenceType(self: *Epub, title: []const u8, reference_type: Section.ReferenceType, body: Body) *Epub {
    if (self.sections == null) self.sections = std.ArrayList(Section).init(self.allocator);

    self.sections.?.append(Section.create(self.allocator, title, reference_type, body)) catch {
        std.log.err("Error adding section {s}", .{title});
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
    _ = epub_path;
    try output.createEpubFiles(self);
}

test "epub" {
    const allocator = testing.allocator;

    var epub = Epub.init(allocator, .{
        .title = "Flying Circus",
        .creator = "Johann Gambolputty",
        .identifier = Metadata.defaultIdentifier(),
    });
    defer epub.deinit();

    var mock_images_paths = [_][]const u8{
        "/path/to/img1.jpg",
        "/path/to/img2.jpg",
    };

    try epub
        .addStylesheet(.{ .raw = "body { background: '#808080' }" })
        .addCoverWithImage(.{ .raw = "<h1>title</h1>" }, "/path/to/img.png")
        .addImages(&mock_images_paths)
        .addSectionWithReferenceType("Preface", .Preface, .{ .raw = "<p>preface</p>" })
        .addSection("Chapter 1", .{ .raw = "<p>test</p>" })
        .addSection("Chapter 2", .{ .raw = "<p>test</p>" })
        .generate("MyEpub");

    try testing.expect(@TypeOf(epub) == Epub);
}
