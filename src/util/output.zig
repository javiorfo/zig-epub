const std = @import("std");
const Epub = @import("../epub/Epub.zig");
const Section = @import("../epub/Section.zig");
const xhtml = @import("xhtml.zig");

const output_folder = "epub-files";
const meta_inf_folder = output_folder ++ "/META-INF/";
const oebps_folder = output_folder ++ "/OEBPS/";
const mimetype = output_folder ++ "/mimetype";
const mimetype_content = "application/epub+zip";
const images_folder = oebps_folder ++ "images/";
const stylesheet = oebps_folder ++ "stylesheet.css";
const container = meta_inf_folder ++ "container.xml";
const content_opf = oebps_folder ++ "content.opf";
const toc = oebps_folder ++ "toc.ncx";

const container_content =
    \\<?xml version="1.0"?>
    \\<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    \\  <rootfiles>
    \\    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
    \\   </rootfiles>
    \\</container>
;

pub fn createEpubFiles(epub: *Epub) !void {
    const cwd = std.fs.cwd();

    try createOrOverrideDir(output_folder);
    try cwd.makeDir(meta_inf_folder);
    try cwd.makeDir(oebps_folder);
    try cwd.makeDir(images_folder);
    try createFileAndWrite(mimetype, mimetype_content);
    try createFileAndWrite(container, container_content);

    try createContentOpf(epub);
    try createSections(epub);
    try createToc(epub);

    std.log.debug("Generating stylesheet if set: {s}\n", .{stylesheet});
    if (epub.stylesheet) |ss| try ss.generate(stylesheet);

    std.log.debug("Copying cover image if set: {any}\n", .{epub.cover_image});
    if (epub.cover_image) |cover_image| {
        try saveToImageFolder(epub.allocator, cover_image.path);
    }

    std.log.debug("Copying images if set: {any}\n", .{epub.cover_image});
    if (epub.images) |images| {
        for (images) |img| try saveToImageFolder(epub.allocator, img);
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

fn createContentOpf(epub: *Epub) !void {
    var file = try std.fs.cwd().createFile(content_opf, .{});
    defer file.close();
    try file.writeAll(xhtml.content_opf_package_metadata);

    // METADATA
    const metadata = epub.metadata;

    const title = try std.fmt.allocPrint(epub.allocator, xhtml.content_opt_metadata_title, .{metadata.title});
    defer epub.allocator.free(title);
    try file.writeAll(title);

    const creator = try std.fmt.allocPrint(epub.allocator, xhtml.content_opt_metadata_creator, .{metadata.creator});
    defer epub.allocator.free(creator);
    try file.writeAll(creator);

    const identifier = switch (metadata.identifier.identifier_type) {
        .ISBN => try std.fmt.allocPrint(epub.allocator, xhtml.content_opt_metadata_identifier_isbn, .{metadata.identifier.value}),
        .UUID => try std.fmt.allocPrint(epub.allocator, xhtml.content_opt_metadata_identifier_uuid, .{metadata.identifier.value}),
    };
    defer epub.allocator.free(identifier);
    try file.writeAll(identifier);

    const language = try std.fmt.allocPrint(epub.allocator, xhtml.content_opt_metadata_language, .{metadata.language.toString()});
    defer epub.allocator.free(language);
    try file.writeAll(language);

    if (metadata.date) |d| {
        const date = try std.fmt.allocPrint(epub.allocator, xhtml.content_opt_metadata_date, .{d});
        defer epub.allocator.free(date);
        try file.writeAll(date);
    }

    if (metadata.publisher) |p| {
        const publisher = try std.fmt.allocPrint(epub.allocator, xhtml.content_opt_metadata_publisher, .{p});
        defer epub.allocator.free(publisher);
        try file.writeAll(publisher);
    }

    if (epub.cover_image) |_| try file.writeAll(xhtml.content_opt_metadata_cover_image);

    try file.writeAll(xhtml.content_opf_metadata_manifest);

    // MANIFEST
    if (epub.stylesheet) |_| try file.writeAll(xhtml.content_opf_manifest_css);

    if (epub.sections) |sections| {
        for (sections.items) |section| {
            const id = try std.mem.replaceOwned(u8, epub.allocator, section.title, " ", "");
            defer epub.allocator.free(id);
            const html = try std.fmt.allocPrint(epub.allocator, xhtml.content_opf_manifest_xhtml, .{ id, id });
            defer epub.allocator.free(html);
            try file.writeAll(html);
        }
    }

    if (epub.cover) |_| {
        const html = try std.fmt.allocPrint(epub.allocator, xhtml.content_opf_manifest_xhtml, .{ "cover", "cover" });
        defer epub.allocator.free(html);
        try file.writeAll(html);
    }

    if (epub.cover_image) |cover_image| {
        const img = try std.fmt.allocPrint(epub.allocator, xhtml.content_opf_manifest_cover_image, .{
            std.fs.path.basename(cover_image.path),
            cover_image.image_type.toString(),
        });

        defer epub.allocator.free(img);
        try file.writeAll(img);
    }

    try file.writeAll(xhtml.content_opf_manifest_spine);

    // SPINE
    if (epub.cover) |_| try file.writeAll(xhtml.content_opf_spine_cover);

    if (epub.sections) |sections| {
        for (sections.items) |section| {
            const id = try std.mem.replaceOwned(u8, epub.allocator, section.title, " ", "");
            defer epub.allocator.free(id);
            const idref = try std.fmt.allocPrint(epub.allocator, xhtml.content_opf_spine_item, .{id});
            defer epub.allocator.free(idref);
            try file.writeAll(idref);
        }
    }

    try file.writeAll(xhtml.content_opf_spine_guide);

    // GUIDE
    if (epub.cover) |cover| {
        const html = try std.fmt.allocPrint(epub.allocator, xhtml.content_opf_guide_reference, .{
            "cover",
            "cover",
            cover.title,
        });
        defer epub.allocator.free(html);
        try file.writeAll(html);
    }

    if (epub.sections) |sections| {
        for (sections.items) |section| {
            const id = try std.mem.replaceOwned(u8, epub.allocator, section.title, " ", "");
            defer epub.allocator.free(id);
            const html = try std.fmt.allocPrint(epub.allocator, xhtml.content_opf_guide_reference, .{
                id,
                section.reference_type.toString(),
                section.title,
            });
            defer epub.allocator.free(html);
            try file.writeAll(html);
        }
    }

    try file.writeAll(xhtml.content_opf_guide_package);
}

fn createSections(epub: *Epub) !void {
    const add_stylesheet = if (epub.stylesheet) |_| true else false;

    if (epub.cover) |cover| {
        try cover.createFile(add_stylesheet, oebps_folder, true);
    }

    if (epub.sections) |sections| {
        for (sections.items) |section| {
            try section.createFile(add_stylesheet, oebps_folder, false);
        }
    }
}

fn createToc(epub: *Epub) !void {
    var file = try std.fs.cwd().createFile(toc, .{});
    defer file.close();
    try file.writeAll(xhtml.toc_open_tag);

    const metadata = epub.metadata;

    const identifier = switch (metadata.identifier.identifier_type) {
        .ISBN => try std.fmt.allocPrint(epub.allocator, xhtml.toc_uid, .{ "isbn", metadata.identifier.value }),
        .UUID => try std.fmt.allocPrint(epub.allocator, xhtml.toc_uid, .{ "uuid", metadata.identifier.value }),
    };
    defer epub.allocator.free(identifier);
    try file.writeAll(identifier);

    try file.writeAll(xhtml.toc_doc_title);

    const title = try std.fmt.allocPrint(epub.allocator, xhtml.toc_title_text, .{metadata.title});
    defer epub.allocator.free(title);
    try file.writeAll(title);

    try file.writeAll(xhtml.toc_open_nav_map);

    var index: usize = 1;
    if (epub.cover) |cover| {
        const nav_point = try std.fmt.allocPrint(epub.allocator, xhtml.toc_nav_point, .{ index, index });
        defer epub.allocator.free(nav_point);
        try file.writeAll(nav_point);

        const nav_label = try std.fmt.allocPrint(epub.allocator, xhtml.toc_nav_point_text, .{cover.title});
        defer epub.allocator.free(nav_label);
        try file.writeAll(nav_label);

        const content = try std.fmt.allocPrint(epub.allocator, xhtml.toc_nav_point_content, .{"cover"});
        defer epub.allocator.free(content);
        try file.writeAll(content);

        try file.writeAll(xhtml.toc_close_nav_point);
        index += 1;
    }

    if (epub.sections) |sections| {
        for (sections.items) |section| {
            try createNavPoint(epub.allocator, &file, &index, section);
        }
    }

    try file.writeAll(xhtml.toc_close);
}

fn createNavPoint(allocator: std.mem.Allocator, file: *std.fs.File, index: *usize, section: Section) !void {
    const nav_point = try std.fmt.allocPrint(allocator, xhtml.toc_nav_point, .{ index.*, index.* });
    defer allocator.free(nav_point);
    try file.writeAll(nav_point);

    const nav_label = try std.fmt.allocPrint(allocator, xhtml.toc_nav_point_text, .{section.title});
    defer allocator.free(nav_label);
    try file.writeAll(nav_label);

    const src = try std.mem.replaceOwned(u8, allocator, section.title, " ", "");
    defer allocator.free(src);

    const content = try std.fmt.allocPrint(allocator, xhtml.toc_nav_point_content, .{src});
    defer allocator.free(content);
    try file.writeAll(content);

    if (section.tocs) |tocs| {
        for (tocs.items, 0..) |tc, i| {
            const parent_index = index.*;
            index.* += 1;
            const nav_point_child = try std.fmt.allocPrint(allocator, xhtml.toc_nav_point_child, .{ parent_index, i + 1, index.* });
            defer allocator.free(nav_point_child);
            try file.writeAll(nav_point_child);

            const nav_label_child = try std.fmt.allocPrint(allocator, xhtml.toc_nav_point_text_child, .{tc.text});
            defer allocator.free(nav_label_child);
            try file.writeAll(nav_label_child);

            const content_child = try std.fmt.allocPrint(allocator, xhtml.toc_nav_point_content_child, .{ src, tc.reference_id });
            defer allocator.free(content_child);
            try file.writeAll(content_child);

            try file.writeAll(xhtml.toc_close_nav_point_child);
        }
    }

    try file.writeAll(xhtml.toc_close_nav_point);
    index.* += 1;
}
