const std = @import("std");

/// Represents the body content of a section in an EPUB document.
pub const Body = union(enum) {
    /// The raw text content of the body.
    raw: []const u8,

    /// The file path of the body content.
    filepath: []const u8,

    /// Retrieves the body content as a byte slice.
    ///
    /// If the body content is stored in a file, the file is read and its contents are returned.
    /// If the body content is stored as raw text, the raw text is returned.
    pub fn get(self: Body, allocator: std.mem.Allocator) ![]const u8 {
        return switch (self) {
            .filepath => |f| try readFileToString(allocator, f),
            .raw => |r| r,
        };
    }

    /// Checks if the body content is stored in a file.
    pub fn isFile(self: Body) bool {
        return switch (self) {
            .filepath => true,
            .raw => false,
        };
    }

    /// Reads the contents of a file and returns it as a byte slice.
    fn readFileToString(allocator: std.mem.Allocator, filepath: []const u8) ![]const u8 {
        var file = try std.fs.cwd().openFile(filepath, .{});
        defer file.close();

        const file_size = try file.getEndPos();
        var buffer = try allocator.alloc(u8, file_size);
        errdefer allocator.free(buffer);

        const read = try file.readAll(buffer);
        return buffer[0..read];
    }
};
