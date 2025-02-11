const std = @import("std");
const Body = @import("../util/body.zig").Body;
const xhtml = @import("../util/xhtml.zig");
const testing = std.testing;

title: []const u8,
body: Body,
allocator: std.mem.Allocator,
reference_type: ReferenceType = .Text,
tocs: ?std.ArrayList(Toc) = null,

const Section = @This();

pub fn init(allocator: std.mem.Allocator, title: []const u8, body: Body) Section {
    return .{
        .allocator = allocator,
        .title = title,
        .body = body,
    };
}

pub fn deinit(self: *Section) void {
    if (self.tocs) |s| s.deinit();
}

pub fn withReferenceType(self: *Section, reference_type: ReferenceType) *Section {
    self.reference_type = reference_type;
    return self;
}

pub fn addToc(self: *Section, toc: Toc) *Section {
    if (self.tocs == null) self.tocs = std.ArrayList(Toc).init(self.allocator);

    self.tocs.?.append(toc) catch {
        std.log.err("Error adding toc {s}", .{toc.text});
    };
    return self;
}

pub fn build(self: *Section) Section {
    return self.*;
}

pub fn createFile(self: Section, add_stylesheet: bool, output_folder: []const u8, is_cover: bool) !void {
    const value = try self.body.get(self.allocator);
    defer if (self.body.isFile()) self.allocator.free(value);

    const filename = try std.mem.replaceOwned(u8, self.allocator, self.title, " ", "");
    defer self.allocator.free(filename);

    const dest = try std.mem.concat(self.allocator, u8, &.{ output_folder, if (is_cover) "cover" else filename, ".xhtml" });
    defer self.allocator.free(dest);

    var file = try std.fs.cwd().createFile(dest, .{});
    defer file.close();
    try file.writeAll(xhtml.items_xhtml_open_tag);

    const title = try std.fmt.allocPrint(self.allocator, xhtml.items_xhtml_title, .{self.title});
    defer self.allocator.free(title);
    try file.writeAll(title);

    if (add_stylesheet) try file.writeAll(xhtml.items_xhtml_stylesheet);

    try file.writeAll(xhtml.items_xhtml_open_body);
    try file.writeAll(value);
    try file.writeAll(xhtml.items_xhtml_close_body);
}

pub const Toc = struct {
    text: []const u8,
    reference_id: []const u8,
};

pub const ReferenceType = enum(u8) {
    Acknowledgements,
    Bibliography,
    Colophon,
    Copyright,
    Cover,
    Dedication,
    Epigraph,
    Foreword,
    Glossary,
    Index,
    Loi,
    Lot,
    Notes,
    Preface,
    Text,
    TitlePage,
    Toc,

    pub fn toString(self: ReferenceType) []const u8 {
        return switch (self) {
            inline else => |tag| tag.toLower(),
        };
    }

    fn toLower(self: ReferenceType) []const u8 {
        var buffer: [20]u8 = undefined;
        const output = std.ascii.lowerString(&buffer, @tagName(self));
        return output;
    }
};

test "section raw" {
    const alloc = testing.allocator;

    const raw =
        \\ <h1>Title</h2>
        \\ <p>Something</p>
    ;

    var section = Section.init(alloc, "Chapter 1", .{ .raw = raw });
    defer section.deinit();
    try testing.expectEqualStrings(raw, try section.body.get(alloc));
}

test "section file" {
    const alloc = testing.allocator;

    const cwd_path = try std.fs.cwd().realpathAlloc(alloc, ".");
    defer alloc.free(cwd_path);
    const absolute_path = try std.fs.path.resolve(alloc, &.{ cwd_path, "README.md" });
    defer alloc.free(absolute_path);

    var section = Section.init(alloc, "Chapter 2", .{ .file_path = absolute_path });
    defer section.deinit();
    const value = try section.body.get(alloc);
    defer alloc.free(value);
    try testing.expectEqualStrings("zig-epub", value[2..10]);
}

test "section file error" {
    const alloc = testing.allocator;
    var section = Section.init(alloc, "Chapter 3", .{ .file_path = "/no_existent" });
    defer section.deinit();
    try testing.expectError(error.FileNotFound, section.body.get(alloc));
}

test "reference type" {
    try testing.expectEqualStrings("cover", ReferenceType.Cover.toString());
}
