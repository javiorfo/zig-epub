const std = @import("std");
const Section = @import("Section.zig");
const Body = @import("../util/body.zig").Body;
const output = @import("../util/output.zig");
const CoverImage = @import("CoverImage.zig");
const Metadata = @import("Metadata.zig");
const testing = std.testing;

/// The memory allocator used by the EPUB document.
allocator: std.mem.Allocator,

/// The metadata associated with the EPUB document.
metadata: Metadata,

/// The sections of the EPUB document, stored in a dynamic array.
sections: ?std.ArrayList(Section) = null,

/// The stylesheet associated with the EPUB document.
stylesheet: ?Body = null,

/// The cover section of the EPUB document.
cover: ?Section = null,

/// The cover image associated with the EPUB document.
cover_image: ?CoverImage = null,

/// The image files associated with the EPUB document.
images: ?[][]const u8 = null,

const Epub = @This();

/// Initializes a new `Epub` struct with the provided `allocator` and `metadata`.
pub fn init(allocator: std.mem.Allocator, metadata: Metadata) Epub {
    return .{
        .allocator = allocator,
        .metadata = metadata,
    };
}

/// Deinitializes the `Epub` struct, including any associated sections.
pub fn deinit(self: *Epub) void {
    if (self.sections) |s| s.deinit();
}

/// Adds a std.ArrayList of sections to the `Epub` struct.
pub fn addSections(self: *Epub, sections: std.ArrayList(Section)) *Epub {
    self.sections = sections;
    return self;
}

/// Adds a new section with the provided `title` and `body` to the `Epub` struct.
pub fn addSection(self: *Epub, title: []const u8, body: Body) *Epub {
    return self.addSectionType(title, body, Section.ReferenceType.Text);
}

/// Adds a new section with the provided `title`, `body`, and `reference_type` to the `Epub` struct.
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

/// Adds a new `Section` to the `Epub` struct.
pub fn add(self: *Epub, section: Section) *Epub {
    if (self.sections == null) self.sections = std.ArrayList(Section).init(self.allocator);

    self.sections.?.append(section) catch {
        std.log.err("Error adding section {s}", .{section.title});
    };
    return self;
}

/// Sets the stylesheet for the `Epub` struct.
pub fn setStylesheet(self: *Epub, body: Body) *Epub {
    self.stylesheet = body;
    return self;
}

/// Sets the image files associated with the `Epub` struct.
pub fn setImages(self: *Epub, paths: [][]const u8) *Epub {
    self.images = paths;
    return self;
}

/// Sets the cover section for the `Epub` struct.
pub fn setCover(self: *Epub, body: Body) *Epub {
    self.cover = .{
        .allocator = self.allocator,
        .title = self.metadata.title,
        .body = body,
        .reference_type = .Cover,
    };
    return self;
}

/// Sets the cover image for the `Epub` struct.
pub fn setCoverImage(self: *Epub, cover_image: CoverImage) *Epub {
    self.cover_image = cover_image;
    return self;
}

/// Generates the EPUB files and saves them to the specified `epub_path`.
pub fn generate(self: *Epub, epub_path: []const u8) !void {
    try output.createEpubFiles(self, epub_path);
}

test "epub" {
    const allocator = testing.allocator;

    var epub = Epub.init(allocator, .{
        .title = "Flying Circus",
        .creator = "Johann Gambolputty",
        .identifier = .{
            .identifier_type = .UUID,
            .value = "d5b2b585-566a-4b9c-9c5d-f99436e3a588",
        },
    });
    defer epub.deinit();

    var mock_images_paths = [_][]const u8{
        "cats.jpg",
        "cats2.jpg",
    };

    var section = Section.init(allocator, "Chapter 1", .{ .raw = "<h1>Chapter 1</h1>\n<p>Hello</p>\n<h1 id=\"chapter1.1\">Chapter 1.1</h1>" });
    defer section.deinit();

    _ = epub
        .setStylesheet(.{ .raw = "body { background-color: #808080 }" })
        .setCoverImage(.{ .path = "cats.png", .image_type = .png })
        .setImages(&mock_images_paths)
        .setCover(.{ .raw = "<div class=\"cover\"><img src=\"images/cats.png\" alt=\"Cover Image\"/></div>" })
        .addSectionType("Preface", .{ .raw = "<p>preface</p>\n" }, .Preface)
        .add(section.addToc(.{ .text = "Chapter 1.1", .reference_id = "chapter1.1" }).build())
        .addSection("Chapter 2", .{ .raw = "<h1>Chapter 2</h1>\n<p>Bye</p>\n" });

    try testing.expect(@TypeOf(epub) == Epub);
}
