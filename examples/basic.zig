const std = @import("std");
const epub = @import("epub");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() != .ok) @panic("leak");
    const allocator = gpa.allocator();

    var my_epub = epub.Epub.init(allocator, .{
        .title = "Flying Circus",
        .creator = "Johann Gambolputty",
        .identifier = .{
            .identifier_type = .UUID,
            .value = "d5b2b585-566a-4b9c-9c5d-f99436e3a588",
        },
    });
    defer my_epub.deinit();

    var image_paths = [_][]const u8{
        "/home/user/Downloads/image.jpg",
        "/home/user/Downloads/image2.png",
    };

    var section = epub.Section.init(allocator, "Chapter 1", .{ .raw = "<h1>Chapter 1</h1>\n<p>Hello</p>\n<h1 id=\"chapter1.1\">Chapter 1.1</h1>" });
    defer section.deinit();

    try my_epub
        .setStylesheet(.{ .raw = "body { background-color: #000000 }" })
        .setCoverImage(.{ .path = "/home/user/Downloads/cats.jpg", .image_type = .jpg })
        .setImages(&image_paths)
        .setCover(.{ .raw = "<div class=\"cover\"><img src=\"images/cats.jpg\" alt=\"Cover Image\"/></div>" })
        .addSectionType("Preface", .{ .raw = "<p>preface</p>\n" }, .Preface)
        .add(section.addToc(.{ .text = "Chapter 1.1", .reference_id = "chapter1.1" }).build())
        .addSection("Chapter 2", .{ .raw = "<h1>Chapter 2</h1>\n<p>Bye</p>\n" })
        .generate("book.epub");
}
