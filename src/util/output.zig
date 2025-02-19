const std = @import("std");
const Epub = @import("../epub/Epub.zig");
const Section = @import("../epub/Section.zig");
const xhtml = @import("xhtml.zig");
const c = @cImport({
    @cInclude("zip.h");
});

const oebps_folder = "OEBPS/";
const images_folder = oebps_folder ++ "images/";
const stylesheet_file = oebps_folder ++ "stylesheet.css";
const content_opf_file = oebps_folder ++ "content.opf";
const toc_file = oebps_folder ++ "toc.ncx";

const container_content =
    \\<?xml version="1.0"?>
    \\<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    \\  <rootfiles>
    \\    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
    \\   </rootfiles>
    \\</container>
;

/// Function wrapper to create epub
pub fn createEpubFiles(epub: *Epub, epub_path: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    var err: c_int = 0;
    const za: ?*c.zip_t = c.zip_open(epub_path.ptr, c.ZIP_CREATE, &err);
    if (za == null) {
        var zip_err: c.zip_error_t = undefined;
        c.zip_error_init_with_code(&zip_err, err);
        std.log.debug("cannot create epub archive {s}: {any}\n", .{ epub_path, c.zip_error_strerror(&zip_err) });
        c.zip_error_fini(&zip_err);
        return error.EpubFileCreateError;
    }

    try addFileToEpub(za.?, "mimetype", "application/epub+zip");
    try addFileToEpub(za.?, "META-INF/container.xml", container_content);

    // content opf
    try createContentOpf(allocator, epub, &list);
    const content_opf_file_content = try list.toOwnedSlice();
    try addFileToEpub(za.?, content_opf_file, content_opf_file_content);

    // toc ncx
    try createToc(allocator, epub, &list);
    const toc_file_content = try list.toOwnedSlice();
    try addFileToEpub(za.?, toc_file, toc_file_content);

    // sections xhtml
    var map = std.StringHashMap([]const u8).init(allocator);
    defer map.deinit();

    try createSections(allocator, epub, &map);
    var it = map.iterator();
    while (it.next()) |entry| {
        const content = entry.value_ptr.*;
        const xhtml_name = try std.fmt.allocPrintZ(allocator, "{s}", .{entry.key_ptr.*});
        try addFileToEpub(za.?, xhtml_name, content);
    }

    // stylesheet
    if (epub.stylesheet) |ss| {
        const content = try ss.get(allocator);
        defer if (ss.isFile()) allocator.free(content);
        try addFileToEpub(za.?, stylesheet_file, content);
    }

    // cover image
    if (epub.cover_image) |cover_image| try addImageToEpub(allocator, za.?, cover_image.path);

    // images
    if (epub.images) |images| for (images) |img| try addImageToEpub(allocator, za.?, img);

    if (c.zip_close(za) < 0) {
        c.zip_discard(za);
        return error.EpubFileCloseError;
    }
}

/// Adds a file to the epub using libzip
fn addFileToEpub(za: *c.zip_t, filepath: [*c]const u8, content: []const u8) !void {
    const src = c.zip_source_buffer(za, content.ptr, content.len, 0);
    if (c.zip_file_add(za, filepath, src, c.ZIP_FL_OVERWRITE) < 0) {
        std.log.debug("cannot add file {s}: {s}\n", .{ filepath, c.zip_strerror(za) });
        c.zip_source_free(src);

        if (c.zip_close(za) < 0) {
            c.zip_discard(za);
            return error.EpubFileCloseError;
        }

        return error.EpubFileContentError;
    }
}

/// Adds an image to the epub using libzip
fn addImageToEpub(allocator: std.mem.Allocator, za: *c.zip_t, filepath: []const u8) !void {
    var file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    const size: i64 = @intCast(try file.getEndPos());

    const epub_image_path: []const u8 = try std.mem.concat(allocator, u8, &.{ images_folder, std.fs.path.basename(filepath) });

    const src = c.zip_source_file(za, filepath.ptr, 0, size);
    if (c.zip_file_add(za, epub_image_path.ptr, src, c.ZIP_FL_OVERWRITE) < 0) {
        std.log.debug("cannot add image {s}: {s}\n", .{ filepath, c.zip_strerror(za) });
        c.zip_source_free(src);

        if (c.zip_close(za) < 0) {
            c.zip_discard(za);
            return error.EpubFileCloseError;
        }

        return error.EpubImageFileError;
    }
}

/// Creates content.opf and store it in an ArrayList
fn createContentOpf(allocator: std.mem.Allocator, epub: *Epub, list: *std.ArrayList(u8)) !void {
    try list.appendSlice(xhtml.content_opf_package_metadata);

    // METADATA
    const metadata = epub.metadata;

    const title = try std.fmt.allocPrint(allocator, xhtml.content_opt_metadata_title, .{metadata.title});
    try list.appendSlice(title);

    const creator = try std.fmt.allocPrint(allocator, xhtml.content_opt_metadata_creator, .{metadata.creator});
    try list.appendSlice(creator);

    const identifier = switch (metadata.identifier.identifier_type) {
        .ISBN => try std.fmt.allocPrint(allocator, xhtml.content_opt_metadata_identifier_isbn, .{metadata.identifier.value}),
        .UUID => try std.fmt.allocPrint(allocator, xhtml.content_opt_metadata_identifier_uuid, .{metadata.identifier.value}),
    };
    try list.appendSlice(identifier);

    const language = try std.fmt.allocPrint(allocator, xhtml.content_opt_metadata_language, .{metadata.language.toString()});
    try list.appendSlice(language);

    if (metadata.date) |d| {
        const date = try std.fmt.allocPrint(allocator, xhtml.content_opt_metadata_date, .{d});
        try list.appendSlice(date);
    }

    if (metadata.publisher) |p| {
        const publisher = try std.fmt.allocPrint(allocator, xhtml.content_opt_metadata_publisher, .{p});
        try list.appendSlice(publisher);
    }

    if (epub.cover_image) |_| try list.appendSlice(xhtml.content_opt_metadata_cover_image);

    try list.appendSlice(xhtml.content_opf_metadata_manifest);

    // MANIFEST
    if (epub.stylesheet) |_| try list.appendSlice(xhtml.content_opf_manifest_css);

    if (epub.sections) |sections| {
        for (sections.items) |section| {
            const id = try std.mem.replaceOwned(u8, allocator, section.title, " ", "");
            const html = try std.fmt.allocPrint(allocator, xhtml.content_opf_manifest_xhtml, .{ id, id });
            try list.appendSlice(html);
        }
    }

    if (epub.cover) |_| {
        const html = try std.fmt.allocPrint(allocator, xhtml.content_opf_manifest_xhtml, .{ "cover", "cover" });
        try list.appendSlice(html);
    }

    if (epub.cover_image) |cover_image| {
        const img = try std.fmt.allocPrint(allocator, xhtml.content_opf_manifest_cover_image, .{
            std.fs.path.basename(cover_image.path),
            cover_image.image_type.toString(),
        });

        try list.appendSlice(img);
    }

    try list.appendSlice(xhtml.content_opf_manifest_spine);

    // SPINE
    if (epub.cover) |_| try list.appendSlice(xhtml.content_opf_spine_cover);

    if (epub.sections) |sections| {
        for (sections.items) |section| {
            const id = try std.mem.replaceOwned(u8, allocator, section.title, " ", "");
            const idref = try std.fmt.allocPrint(allocator, xhtml.content_opf_spine_item, .{id});
            try list.appendSlice(idref);
        }
    }

    try list.appendSlice(xhtml.content_opf_spine_guide);

    // GUIDE
    if (epub.cover) |cover| {
        const html = try std.fmt.allocPrint(allocator, xhtml.content_opf_guide_reference, .{
            "cover",
            "cover",
            cover.title,
        });
        try list.appendSlice(html);
    }

    if (epub.sections) |sections| {
        for (sections.items) |section| {
            const id = try std.mem.replaceOwned(u8, allocator, section.title, " ", "");
            const ref_type = try std.mem.Allocator.dupe(allocator, u8, section.reference_type.toString());
            const html = try std.fmt.allocPrint(allocator, xhtml.content_opf_guide_reference, .{
                id,
                ref_type,
                section.title,
            });
            try list.appendSlice(html);
        }
    }

    try list.appendSlice(xhtml.content_opf_guide_package);
}

/// Creates sections and store them in an StringHashMap
fn createSections(allocator: std.mem.Allocator, epub: *Epub, map: *std.StringHashMap([]const u8)) !void {
    const add_stylesheet = if (epub.stylesheet) |_| true else false;

    if (epub.cover) |cover| {
        try createSectionFile(allocator, cover, map, add_stylesheet, true);
    }

    if (epub.sections) |sections| {
        for (sections.items) |section| {
            try createSectionFile(allocator, section, map, add_stylesheet, false);
        }
    }
}

/// Creates a sections file and store it in an StringHashMap. Key => filename, Value => content
fn createSectionFile(allocator: std.mem.Allocator, section: Section, map: *std.StringHashMap([]const u8), add_stylesheet: bool, is_cover: bool) !void {
    var list = std.ArrayList(u8).init(std.heap.page_allocator);
    defer list.deinit();

    const value = try section.body.get(allocator);

    const filename = try std.mem.replaceOwned(u8, allocator, section.title, " ", "");
    const name = if (is_cover) "cover" else filename;
    const dest = try std.mem.concat(allocator, u8, &.{ oebps_folder, name, ".xhtml" });

    try list.appendSlice(xhtml.items_xhtml_open_tag);

    const title = try std.fmt.allocPrint(allocator, xhtml.items_xhtml_title, .{section.title});
    try list.appendSlice(title);

    if (add_stylesheet) try list.appendSlice(xhtml.items_xhtml_stylesheet);

    const body = try std.fmt.allocPrint(allocator, xhtml.items_xhtml_open_body, .{name});
    try list.appendSlice(body);
    try list.appendSlice(value);
    try list.appendSlice(xhtml.items_xhtml_close_body);

    try map.put(dest, try list.toOwnedSlice());
}

/// Creates toc.ncx and store it in an ArrayList
fn createToc(allocator: std.mem.Allocator, epub: *Epub, list: *std.ArrayList(u8)) !void {
    try list.appendSlice(xhtml.toc_open_tag);

    const metadata = epub.metadata;

    const identifier = switch (metadata.identifier.identifier_type) {
        .ISBN => try std.fmt.allocPrint(allocator, xhtml.toc_uid, .{ "isbn", metadata.identifier.value }),
        .UUID => try std.fmt.allocPrint(allocator, xhtml.toc_uid, .{ "uuid", metadata.identifier.value }),
    };
    try list.appendSlice(identifier);

    try list.appendSlice(xhtml.toc_doc_title);

    const title = try std.fmt.allocPrint(allocator, xhtml.toc_title_text, .{metadata.title});
    try list.appendSlice(title);

    try list.appendSlice(xhtml.toc_open_nav_map);

    var play_order: usize = 1;
    var nav_point_id: usize = 1;
    if (epub.cover) |cover| {
        const nav_point = try std.fmt.allocPrint(allocator, xhtml.toc_nav_point, .{ nav_point_id, play_order });
        try list.appendSlice(nav_point);

        const nav_label = try std.fmt.allocPrint(allocator, xhtml.toc_nav_point_text, .{cover.title});
        try list.appendSlice(nav_label);

        const content = try std.fmt.allocPrint(allocator, xhtml.toc_nav_point_content, .{"cover"});
        try list.appendSlice(content);

        try list.appendSlice(xhtml.toc_close_nav_point);
        play_order += 1;
        nav_point_id += 1;
    }

    if (epub.sections) |sections| {
        for (sections.items) |section| {
            try createNavPoint(allocator, list, &play_order, &nav_point_id, section);
        }
    }

    try list.appendSlice(xhtml.toc_close);
}

fn createNavPoint(allocator: std.mem.Allocator, list: *std.ArrayList(u8), play_order: *usize, nav_point_id: *usize, section: Section) !void {
    const nav_point = try std.fmt.allocPrint(allocator, xhtml.toc_nav_point, .{ nav_point_id.*, play_order.* });
    try list.appendSlice(nav_point);

    const nav_label = try std.fmt.allocPrint(allocator, xhtml.toc_nav_point_text, .{section.title});
    try list.appendSlice(nav_label);

    const src = try std.mem.replaceOwned(u8, allocator, section.title, " ", "");

    const content = try std.fmt.allocPrint(allocator, xhtml.toc_nav_point_content, .{src});
    try list.appendSlice(content);

    if (section.tocs) |tocs| {
        for (tocs.items, 0..) |tc, i| {
            play_order.* += 1;
            const nav_point_child = try std.fmt.allocPrint(allocator, xhtml.toc_nav_point_child, .{ nav_point_id.*, i + 1, play_order.* });
            try list.appendSlice(nav_point_child);

            const nav_label_child = try std.fmt.allocPrint(allocator, xhtml.toc_nav_point_text_child, .{tc.text});
            try list.appendSlice(nav_label_child);

            const content_child = try std.fmt.allocPrint(allocator, xhtml.toc_nav_point_content_child, .{ src, tc.reference_id });
            try list.appendSlice(content_child);

            try list.appendSlice(xhtml.toc_close_nav_point_child);
        }
    }

    try list.appendSlice(xhtml.toc_close_nav_point);
    play_order.* += 1;
    nav_point_id.* += 1;
}
