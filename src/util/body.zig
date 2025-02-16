const std = @import("std");

pub const Body = union(enum) {
    raw: []const u8,
    filepath: []const u8,

    pub fn get(self: Body, allocator: std.mem.Allocator) ![]const u8 {
        return switch (self) {
            .file_path => |f| try readFileToString(allocator, f),
            .raw => |r| r,
        };
    }

    fn readFileToString(allocator: std.mem.Allocator, filepath: []const u8) ![]const u8 {
        var file = try std.fs.cwd().openFile(filepath, .{});
        defer file.close();

        const file_size = try file.getEndPos();
        var buffer = try allocator.alloc(u8, file_size);
        errdefer allocator.free(buffer);

        const read = try file.readAll(buffer);
        return buffer[0..read];
    }

    pub fn isFile(self: Body) bool {
        return switch (self) {
            .file_path => true,
            .raw => false,
        };
    }
};
