const std = @import("std");

pub const Body = union(enum) {
    raw: []const u8,
    file_path: []const u8,

    pub fn get(self: Body, allocator: std.mem.Allocator) ![]const u8 {
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

    pub fn isFile(self: Body) bool {
        switch (self) {
            .file_path => return true,
            .raw => return false,
        }
    }
};
