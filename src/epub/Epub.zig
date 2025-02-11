const std = @import("std");
const Section = @import("Section.zig");
const Body = @import("../util/body.zig").Body;
const output = @import("../util/output.zig");
const Stylesheet = @import("Stylesheet.zig");
const CoverImage = @import("CoverImage.zig");
const Metadata = @import("Metadata.zig");
const testing = std.testing;

allocator: std.mem.Allocator,
metadata: Metadata,
sections: ?std.ArrayList(Section) = null,
stylesheet: ?Stylesheet = null,
cover: ?Section = null,
cover_image: ?CoverImage = null,
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
    return self.addSectionType(title, body, Section.ReferenceType.Text);
}

pub fn addSectionType(self: *Epub, title: []const u8, body: Body, reference_type: Section.ReferenceType) *Epub {
    if (self.sections == null) self.sections = std.ArrayList(Section).init(self.allocator);

    const section = Section{
        .allocator = self.allocator,
        .title = title,
        .body = body,
        .reference_type = reference_type,
    };

    self.sections.?.append(section) catch {
        std.log.err("Error adding section {s}", .{title});
    };
    return self;
}

pub fn add(self: *Epub, section: Section) *Epub {
    if (self.sections == null) self.sections = std.ArrayList(Section).init(self.allocator);

    self.sections.?.append(section) catch {
        std.log.err("Error adding section {s}", .{section.title});
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
    self.cover = .{
        .allocator = self.allocator,
        .title = self.metadata.title,
        .body = body,
        .reference_type = .Cover,
    };
    return self;
}

pub fn addCoverImage(self: *Epub, cover_image: CoverImage) *Epub {
    self.cover_image = cover_image;
    return self;
}

pub fn generate(self: *Epub, epub_path: []const u8) !void {
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
        "/home/javier/Downloads/cats.jpg",
        "/home/javier/Downloads/cats.jpg",
    };

    var section = Section.init(allocator, "Chapter 1", .{ .raw = "<h1>Chapter 1</h1>\n<p>Hello</p>\n<h1 id=\"chapter1.1\">Chapter 1.1</h1>" });
    defer section.deinit();

    try epub
        .addStylesheet(.{ .raw = "body { background: '#808080' }" })
        .addCoverImage(.{ .path = "/home/javier/Downloads/cats.jpg", .image_type = .jpg })
        .addImages(&mock_images_paths)
        .addCover(.{ .raw = "<div class=\"cover\"><img src=\"images/cats.jpg\" alt=\"Cover Image\"/></div>" })
        .addSectionType("Preface", .{ .raw = "<p>preface</p>\n" }, .Preface)
        .add(section.addToc(.{ .text = "Chapter 1.1", .reference_id = "chapter1.1" }).build())
        .addSection("Chapter 2", .{ .raw = "<h1>Chapter 2</h1>\n<p>Bye</p>\n" })
        .generate("MyEpub");

    try testing.expect(@TypeOf(epub) == Epub);
}
