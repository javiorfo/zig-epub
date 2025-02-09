const std = @import("std");
const Epub = @import("../epub/Epub.zig");

const output_folder = "epub-files";
const meta_inf_folder = output_folder ++ "/META-INF";
const oebps_folder = output_folder ++ "/OEBPS";
const mimetype = output_folder ++ "/mimetype";
const mimetype_content = "application/epub+zip";
const images_folder = oebps_folder ++ "/images";
const stylesheet = oebps_folder ++ "/stylesheet.css";
const container = meta_inf_folder ++ "/container.xml";
const container_content =
    \\<?xml version="1.0"?>
    \\<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    \\  <rootfiles>
    \\    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml" />
    \\   </rootfiles>
    \\</container>
;

pub fn createEpubFiles(epub: *Epub) !void {
    try createOrOverrideDir(output_folder);
    try std.fs.cwd().makeDir(meta_inf_folder);
    try std.fs.cwd().makeDir(oebps_folder);
    try std.fs.cwd().makeDir(images_folder);
    try createFileAndWrite(mimetype, mimetype_content);
    try createFileAndWrite(container, container_content);

    std.log.debug("Generating stylesheet if set: {s}\n", .{stylesheet});
    if (epub.stylesheet) |ss| try ss.generate(stylesheet);
}

fn createFileAndWrite(filename: []const u8, content: []const u8) !void {
    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();

    try file.writeAll(content);
}

fn createOrOverrideDir(dirname: []const u8) !void {
    std.fs.cwd().makeDir(dirname) catch |err| {
        if (err == error.PathAlreadyExists) {
            std.log.debug("Deleting and creating existent dir: {s}\n", .{dirname});
            try std.fs.cwd().deleteTree(dirname);
            try std.fs.cwd().makeDir(dirname);
        } else {
            return err;
        }
    };
}
