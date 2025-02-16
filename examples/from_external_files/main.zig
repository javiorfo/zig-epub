const std = @import("std");
const epub = @import("epub");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() != .ok) @panic("leak");
    const allocator = gpa.allocator();

    var my_epub = epub.Epub.init(allocator, .{
        .title = "From Files",
        .creator = "Johann Gambolputty",
        .identifier = .{
            .identifier_type = .UUID,
            .value = "d5b2b585-566a-4b9c-9c5d-f99436e3a588",
        },
    });
    defer my_epub.deinit();

    try my_epub
        .addStylesheet(.{ .filepath = "style.css" })
        .addCoverImage(.{ .path = "/home/user/Downloads/cats.jpg", .image_type = .jpg })
        .addCover(.{ .filepath = "cover.xml" })
        .addSectionType("Preface", .{ .filepath = "preface.xml" }, .Preface)
        .addSection("Chapter 1", .{ .filepath = "chapter1.xml" })
        .generate("book.epub");
}
