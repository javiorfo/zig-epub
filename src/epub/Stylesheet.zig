const std = @import("std");
const Body = @import("../util/body.zig").Body;
const testing = std.testing;

body: Body,
allocator: std.mem.Allocator,

const Stylesheet = @This();

const name = "stylesheet.css";

pub fn create(allocator: std.mem.Allocator, body: Body) Stylesheet {
    return .{
        .allocator = allocator,
        .body = body,
    };
}

pub fn generate(self: Stylesheet) !void {
    const value = try self.body.get(self.allocator);
    defer if (self.body.isFile()) self.allocator.free(value);
    // TODO Create file
}

test "stylesheet raw" {
    const alloc = testing.allocator;

    const raw =
        \\ <h1>Title</h2>
        \\ <p>Something</p>
    ;

    var section = Stylesheet.create(alloc, .{ .raw = raw });
    try section.generate();
    try testing.expectEqualStrings(raw, try section.body.get(alloc));
}

test "stylesheet file" {
    const alloc = testing.allocator;

    const cwd_path = try std.fs.cwd().realpathAlloc(alloc, ".");
    defer alloc.free(cwd_path);
    const absolute_path = try std.fs.path.resolve(alloc, &.{ cwd_path, "README.md" });
    defer alloc.free(absolute_path);

    var section = Stylesheet.create(alloc, .{ .file_path = absolute_path });
    const value = try section.body.get(alloc);
    defer alloc.free(value);
    try section.generate();
    try testing.expectEqualStrings("zig-epub", value[2..10]);
}

test "stylesheet file error" {
    const alloc = testing.allocator;
    var section = Stylesheet.create(alloc, .{ .file_path = "/no_existent.css" });
    try testing.expectError(error.FileNotFound, section.body.get(alloc));
}
