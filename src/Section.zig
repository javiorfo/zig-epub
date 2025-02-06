const std = @import("std");
const testing = std.testing;

name: []const u8,
content: Content,
allocator: std.mem.Allocator,

const Section = @This();

pub fn init(allocator: std.mem.Allocator, name: []const u8, content: Content) Section {
    return .{
        .allocator = allocator,
        .name = name,
        .content = content,
    };
}

const Content = union(enum) {
    raw: []const u8,
    file_path: []const u8,

    pub fn get(self: Content, allocator: std.mem.Allocator) ![]const u8 {
        switch (self) {
            .file_path => |f| return try readFileToString(allocator, f),
            .raw => |r| return r,
        }
    }

    fn readFileToString(allocator: std.mem.Allocator, file_path: []const u8) ![]const u8 {
        var file = try std.fs.openFileAbsolute(file_path, .{});
        defer file.close();

        const file_size = try file.getEndPos();
        var buffer = try allocator.alloc(u8, file_size);
        errdefer allocator.free(buffer);

        const read = try file.readAll(buffer);
        return buffer[0..read];
    }

    pub fn isFile(self: Content) bool {
        switch (self) {
            .file_path => return true,
            .raw => return false,
        }
    }
};

test "section raw" {
    const alloc = testing.allocator;

    const raw =
        \\ <h1>Title</h2>
        \\ <p>Something</p>
    ;

    var section = Section.init(alloc, "chapter1", .{ .raw = raw });
    try testing.expectEqualStrings(raw, try section.content.get(alloc));
}

test "section file" {
    const alloc = testing.allocator;

    const cwd_path = try std.fs.cwd().realpathAlloc(alloc, ".");
    defer alloc.free(cwd_path);
    const absolute_path = try std.fs.path.resolve(alloc, &.{ cwd_path, "README.md" });
    defer alloc.free(absolute_path);

    var section = Section.init(alloc, "chapter2", .{ .file_path = absolute_path });
    const value = try section.content.get(alloc);
    defer alloc.free(value);
    try testing.expectEqualStrings("zig-epub", value[2..10]);
}

test "section file error" {
    const alloc = testing.allocator;
    var section = Section.init(alloc, "chapter3", .{ .file_path = "/no_existent" });
    try testing.expectError(error.FileNotFound, section.content.get(alloc));
}
