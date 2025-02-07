const std = @import("std");
const Body = @import("body.zig").Body;
const testing = std.testing;

allocator: std.mem.Allocator,
body: Body,
image: ?[]const u8,

const Cover = @This();

const name = "cover.xhtml";

pub fn create(allocator: std.mem.Allocator, body: Body, image: ?[]const u8) Cover {
    return .{
        .allocator = allocator,
        .body = body,
        .image = image,
    };
}

pub fn generate(self: Cover) !void {
    const value = try self.body.get(self.allocator);
    defer if (self.body.isFile()) self.allocator.free(value);
    // TODO Create file and copy image if exist
}

test "cover raw" {
    const alloc = testing.allocator;

    const raw =
        \\ <h1>Title</h2>
        \\ <p>Something</p>
    ;

    var section = Cover.create(alloc, .{ .raw = raw }, null);
    try section.generate();
    try testing.expectEqualStrings(raw, try section.body.get(alloc));
}

test "cover file" {
    const alloc = testing.allocator;

    const cwd_path = try std.fs.cwd().realpathAlloc(alloc, ".");
    defer alloc.free(cwd_path);
    const absolute_path = try std.fs.path.resolve(alloc, &.{ cwd_path, "README.md" });
    defer alloc.free(absolute_path);

    var section = Cover.create(alloc, .{ .file_path = absolute_path }, null);
    const value = try section.body.get(alloc);
    defer alloc.free(value);
    try section.generate();
    try testing.expectEqualStrings("zig-epub", value[2..10]);
}

test "cover file error" {
    const alloc = testing.allocator;
    var section = Cover.create(alloc, .{ .file_path = "/no_existent.css" }, null);
    try testing.expectError(error.FileNotFound, section.body.get(alloc));
}
