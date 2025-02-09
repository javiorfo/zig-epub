const std = @import("std");
const Body = @import("../util/body.zig").Body;
const testing = std.testing;

title: []const u8,
body: Body,
allocator: std.mem.Allocator,
reference_type: ReferenceType = .Text,

const Section = @This();

pub fn create(allocator: std.mem.Allocator, title: []const u8, reference_type: ReferenceType, body: Body) Section {
    return .{
        .allocator = allocator,
        .title = title,
        .reference_type = reference_type,
        .body = body,
    };
}

pub fn generate(self: Section) !void {
    const value = try self.body.get(self.allocator);
    defer if (self.body.isFile()) self.allocator.free(value);
    // TODO Create file
    // If name does not have .xhtml or html, add it
}

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

    var section = Section.create(alloc, "Chapter 1", .Text, .{ .raw = raw });
    try section.generate();
    try testing.expectEqualStrings(raw, try section.body.get(alloc));
}

test "section file" {
    const alloc = testing.allocator;

    const cwd_path = try std.fs.cwd().realpathAlloc(alloc, ".");
    defer alloc.free(cwd_path);
    const absolute_path = try std.fs.path.resolve(alloc, &.{ cwd_path, "README.md" });
    defer alloc.free(absolute_path);

    var section = Section.create(alloc, "Chapter 2", .Text, .{ .file_path = absolute_path });
    const value = try section.body.get(alloc);
    defer alloc.free(value);
    try section.generate();
    try testing.expectEqualStrings("zig-epub", value[2..10]);
}

test "section file error" {
    const alloc = testing.allocator;
    var section = Section.create(alloc, "Chapter 3", .Text, .{ .file_path = "/no_existent" });
    try testing.expectError(error.FileNotFound, section.body.get(alloc));
}

test "reference type" {
    try testing.expectEqualStrings("cover", ReferenceType.Cover.toString());
}
