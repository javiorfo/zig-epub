# zig-epub
*Minimal Zig library for creating EPUB files*

## Caveats
- C libs dependencies: [libzip 1.11.2](https://github.com/nih-at/libzip) 
- Required Zig version: **0.13**
- Epub version: `2.0.1`
- This library has been developed on and for `Linux` following open source philosophy.

## Overview
This library will generate an epub with the current compressed files:
- **META-INF/**
    - **container.xml**
- **OEBPS/**
    - **images/**
    - **toc.ncx**
    - **content.opf**
    - **SomeChapter.xhtml**
    - **stylesheet.css**
- **mimetype**

**NOTE:** Only one level of subchapter is available when using Table of Contents at the moment. Ex: Chapter 1 -> Chapter 1.1, Chapter 1.2, etc.

## Usage
```zig
```

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
