const std = @import("std");
const Epub = @import("../epub/Epub.zig");
const Section = @import("../epub/Section.zig");
const xhtml = @import("xhtml.zig");
const c = @cImport({
    @cInclude("zip.h");
});

const meta_inf_folder = "META-INF/";
const oebps_folder = "OEBPS/";
const mimetype = "mimetype";
const images_folder = oebps_folder ++ "images/";
const stylesheet = oebps_folder ++ "stylesheet.css";
const container = meta_inf_folder ++ "container.xml";
const content_opf = oebps_folder ++ "content.opf";
const toc = oebps_folder ++ "toc.ncx";

const mimetype_content = "application/epub+zip";
const container_content =
    \\<?xml version="1.0"?>
    \\<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    \\  <rootfiles>
    \\    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
    \\   </rootfiles>
    \\</container>
;

pub fn createEpubFiles(epub: *Epub, epub_path: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();
    var map = std.StringHashMap([]const u8).init(allocator);
    defer map.deinit();

    var err: c_int = 0;
    const za: ?*c.zip_t = c.zip_open(epub_path.ptr, c.ZIP_CREATE, &err);
    if (za == null) {
        var zip_err: c.zip_error_t = undefined;
        c.zip_error_init_with_code(&zip_err, err);
        std.debug.print("cannot open zip archive {any}: {any}\n", .{ "err", c.zip_error_strerror(&zip_err) });
        c.zip_error_fini(&zip_err);
        return error.EpubFileCreateError;
    }

    // mimetype
    try addFileToEpub(za.?, mimetype, mimetype_content);

    // container.xml
    try addFileToEpub(za.?, container, container_content);

    // content.opf
    try createContentOpf(allocator, epub, &list);
    const content_opf_file_content = try list.toOwnedSlice();
    try addFileToEpub(za.?, content_opf, content_opf_file_content);

    // toc.ncx
    try createToc(allocator, epub, &list);
    const toc_file_content = try list.toOwnedSlice();
    try addFileToEpub(za.?, toc, toc_file_content);

    // sections xhtml
    try createSections(allocator, epub, &map);
    var it = map.iterator();
    while (it.next()) |entry| {
        const ptr = try std.fmt.allocPrintZ(allocator, "{s}", .{entry.key_ptr.*});
        try addFileToEpub(za.?, ptr, entry.value_ptr.*);
    }

    std.log.debug("Generating stylesheet if set: {s}\n", .{stylesheet});
    if (epub.stylesheet) |ss| {
        const value = try ss.get(allocator);
        defer if (ss.isFile()) allocator.free(value);
        try addFileToEpub(za.?, stylesheet, value);
    }

    std.log.debug("Copying cover image if set: {any}\n", .{epub.cover_image});
    if (epub.cover_image) |cover_image| {
        try addImageToEpub(allocator, za.?, cover_image.path);
    }

    std.log.debug("Copying images if set: {any}\n", .{epub.cover_image});
    if (epub.images) |images| {
        for (images) |img| try addImageToEpub(allocator, za.?, img);
    }

    if (c.zip_close(za) < 0) {
        std.debug.print("zip_close: {any}\n", .{c.zip_strerror(za).*});
        c.zip_discard(za);
        return error.EpubFileCloseError;
    }
}

fn addFileToEpub(za: *c.zip_t, filename: [*c]const u8, content: []const u8) !void {
    const src = c.zip_source_buffer(za, content.ptr, content.len, 0);
    if (c.zip_file_add(za, filename, src, c.ZIP_FL_OVERWRITE) < 0) {
        std.log.err("zip_source_buffer mime: {any}\n", .{c.zip_strerror(za).*});
        c.zip_source_free(src);
        _ = c.zip_close(za);
        return error.EpubFileContentError;
    }
}

fn addImageToEpub(allocator: std.mem.Allocator, za: *c.zip_t, filepath: []const u8) !void {
    var file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    const size: i64 = @intCast(try file.getEndPos());

    const epub_image_path: []const u8 = try std.mem.concat(allocator, u8, &.{ images_folder, std.fs.path.basename(filepath) });

    const src = c.zip_source_file(za, filepath.ptr, 0, size);
    if (c.zip_file_add(za, epub_image_path.ptr, src, c.ZIP_FL_OVERWRITE) < 0) {
        std.log.err("zip_source_buffer image: {any}\n", .{c.zip_strerror(za).*});
        c.zip_source_free(src);
        _ = c.zip_close(za);
        return error.EpubFileContentError;
    }
}

fn saveToImageFolder(allocator: std.mem.Allocator, from: []const u8) !void {
    const cwd = std.fs.cwd();
    const epub_image_path = try std.mem.concat(allocator, u8, &.{ images_folder, std.fs.path.basename(from) });
    defer allocator.free(epub_image_path);
    try cwd.copyFile(from, cwd, epub_image_path, .{});
}

fn createFileAndWrite(filename: []const u8, content: []const u8) !void {
    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();

    try file.writeAll(content);
}

fn createOrOverrideDir(dirname: []const u8) !void {
    const cwd = std.fs.cwd();

    cwd.makeDir(dirname) catch |err| {
        if (err == error.PathAlreadyExists) {
            std.log.debug("Deleting and creating existent dir: {s}\n", .{dirname});
            try cwd.deleteTree(dirname);
            try cwd.makeDir(dirname);
        } else {
            return err;
        }
    };
}

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

fn createSectionFile(allocator: std.mem.Allocator, section: Section, map: *std.StringHashMap([]const u8), add_stylesheet: bool, is_cover: bool) !void {
    var list = std.ArrayList(u8).init(std.heap.page_allocator);
    defer list.deinit();

    const value = try section.body.get(allocator);

    const filename = try std.mem.replaceOwned(u8, allocator, section.title, " ", "");

    const dest = try std.mem.concat(allocator, u8, &.{ oebps_folder, if (is_cover) "cover" else filename, ".xhtml" });

    try list.appendSlice(xhtml.items_xhtml_open_tag);

    const title = try std.fmt.allocPrint(allocator, xhtml.items_xhtml_title, .{section.title});
    try list.appendSlice(title);

    if (add_stylesheet) try list.appendSlice(xhtml.items_xhtml_stylesheet);

    try list.appendSlice(xhtml.items_xhtml_open_body);
    try list.appendSlice(value);
    try list.appendSlice(xhtml.items_xhtml_close_body);

    try map.put(dest, try list.toOwnedSlice());
}

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
