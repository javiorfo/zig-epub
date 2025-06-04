# zig-epub
*Minimal Zig library for creating EPUB files*

## Caveats
- C libs dependencies: [libzip 1.11](https://github.com/nih-at/libzip) 
- Required Zig version: **0.14.1**
- Epub version: `2.0.1`
- This library has been developed on and for `Linux` following open source philosophy.

## Overview
This library will generate an epub with the following compressed files:
- **META-INF/**
    - **container.xml**
- **OEBPS/**
    - **images/**
        - **some_image.png**
    - **toc.ncx**
    - **content.opf**
    - **SomeChapter.xhtml**
    - **stylesheet.css**
- **mimetype**


## Usage
- Simple example. More [examples here](https://github.com/javiorfo/zig-epub/tree/master/examples)
```zig
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
        .generate("book.epub"); // This could be a existent path to some folder (absolute or relative). Ex: "/path/to/book.epub"
}
```

## Some info
- Only one level of subsection is available when using Table of Contents at the moment. Ex: Chapter 1 -> Chapter 1.1, Chapter 1.2, etc.
- An Epub is just a compressed file. Using a tool like `unzip` or similar could be useful to see the content and files generated.
- Every **xhtml** (cover and sections) will have the **<body>** tag with an id formed by the name of the section without spaces plus **-body**. Helpful when using some **css** on it.
    - Ex: Section named "Chapter 1" will have `<body id="Chapter1-body">`

## Installation
#### In `build.zig.zon`:
```zig
.dependencies = .{
    .epub = .{
        .url = "https://github.com/javiorfo/zig-epub/archive/refs/heads/master.tar.gz",            
        // .hash = "hash suggested",
        // the hash will be suggested by zig build
    },
}
```

#### In `build.zig`:
```zig
const dep = b.dependency("epub", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("epub", dep.module("epub"));

exe.linkLibC();
exe.linkSystemLibrary("zip");
```

---

### Donate
- **Bitcoin** [(QR)](https://raw.githubusercontent.com/javiorfo/img/master/crypto/bitcoin.png)  `1GqdJ63RDPE4eJKujHi166FAyigvHu5R7v`
- [Paypal](https://www.paypal.com/donate/?hosted_button_id=FA7SGLSCT2H8G)
