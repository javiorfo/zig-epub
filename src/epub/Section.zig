const std = @import("std");
const Body = @import("../util/body.zig").Body;
const testing = std.testing;

name: []const u8,
body: Body,
allocator: std.mem.Allocator,

const Section = @This();

pub fn create(allocator: std.mem.Allocator, name: []const u8, body: Body) Section {
    return .{
        .allocator = allocator,
        .name = name,
        .body = body,
    };
}

pub fn generate(self: Section) !void {
    const value = try self.body.get(self.allocator);
    defer if (self.body.isFile()) self.allocator.free(value);
    // TODO Create file
    // If name does not have .xhtml or html, add it
}

test "section raw" {
    const alloc = testing.allocator;

    const raw =
        \\ <h1>Title</h2>
        \\ <p>Something</p>
    ;

    var section = Section.create(alloc, "chapter1", .{ .raw = raw });
    try section.generate();
    try testing.expectEqualStrings(raw, try section.body.get(alloc));
}

test "section file" {
    const alloc = testing.allocator;

    const cwd_path = try std.fs.cwd().realpathAlloc(alloc, ".");
    defer alloc.free(cwd_path);
    const absolute_path = try std.fs.path.resolve(alloc, &.{ cwd_path, "README.md" });
    defer alloc.free(absolute_path);

    var section = Section.create(alloc, "chapter2", .{ .file_path = absolute_path });
    const value = try section.body.get(alloc);
    defer alloc.free(value);
    try section.generate();
    try testing.expectEqualStrings("zig-epub", value[2..10]);
}

test "section file error" {
    const alloc = testing.allocator;
    var section = Section.create(alloc, "chapter3", .{ .file_path = "/no_existent" });
    try testing.expectError(error.FileNotFound, section.body.get(alloc));
}
