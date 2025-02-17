const std = @import("std");
const Body = @import("../util/body.zig").Body;
const xhtml = @import("../util/xhtml.zig");
const testing = std.testing;

/// The title of the section.
title: []const u8,

/// The body content of the section.
body: Body,

/// The memory allocator used by the section.
allocator: std.mem.Allocator,

/// The reference type of the section.
reference_type: ReferenceType = .Text,

/// The table of contents entries associated with the section.
tocs: ?std.ArrayList(Toc) = null,

const Section = @This();

/// Initializes a new `Section` with the provided `allocator`, `title`, and `body`.
pub fn init(allocator: std.mem.Allocator, title: []const u8, body: Body) Section {
    return .{
        .allocator = allocator,
        .title = title,
        .body = body,
    };
}

/// Deinitializes the `Section`, including any associated table of contents entries.
pub fn deinit(self: *Section) void {
    if (self.tocs) |s| s.deinit();
}

/// Sets the reference type of the `Section`.
pub fn withReferenceType(self: *Section, reference_type: ReferenceType) *Section {
    self.reference_type = reference_type;
    return self;
}

/// Adds a new table of contents entry to the `Section`.
pub fn addToc(self: *Section, toc: Toc) *Section {
    if (self.tocs == null) self.tocs = std.ArrayList(Toc).init(self.allocator);

    self.tocs.?.append(toc) catch {
        std.log.err("Error adding toc {s}", .{toc.text});
    };
    return self;
}

/// Returns a copy of the `Section`.
pub fn build(self: *Section) Section {
    return self.*;
}

/// Represents a table of contents entry for a `Section`.
pub const Toc = struct {
    /// The text of the table of contents entry.
    text: []const u8,

    /// The reference ID of the table of contents entry.
    reference_id: []const u8,
};

/// Represents the different reference types for a `Section`.
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

    /// Returns the lowercase string representation of the reference type.
    pub fn toString(self: ReferenceType) []const u8 {
        return switch (self) {
            inline else => |tag| tag.toLower(),
        };
    }

    /// Converts the reference type to a lowercase string.
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

    var section = Section.init(alloc, "Chapter 2", .{ .filepath = absolute_path });
    defer section.deinit();
    const value = try section.body.get(alloc);
    defer alloc.free(value);
    try testing.expectEqualStrings("zig-epub", value[2..10]);
}

test "section file error" {
    const alloc = testing.allocator;
    var section = Section.init(alloc, "Chapter 3", .{ .filepath = "/no_existent" });
    defer section.deinit();
    try testing.expectError(error.FileNotFound, section.body.get(alloc));
}

test "reference type" {
    try testing.expectEqualStrings("cover", ReferenceType.Cover.toString());
}
