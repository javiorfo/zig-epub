const std = @import("std");
const testing = std.testing;

allocator: std.mem.Allocator,
list: std.ArrayList(u8),

const HtmlBuilder = @This();

pub fn init(allocator: std.mem.Allocator) HtmlBuilder {
    return .{
        .allocator = allocator,
        .list = std.ArrayList(u8).init(allocator),
    };
}

pub fn deinit(self: *HtmlBuilder) void {
    defer self.list.deinit();
}

pub fn add(self: *HtmlBuilder, properties: Properties, htmlTag: HtmlTag) *HtmlBuilder {
    const enclosed = htmlTag.enclose(self.allocator, properties) catch "error";
    self.list.appendSlice(enclosed) catch |err| {
        std.log.err("Error appending HTML enclosed {}", .{err});
    };
    return self;
}

pub fn build(self: *HtmlBuilder) ![]const u8 {
    return try self.list.toOwnedSlice();
}

const Properties = struct {
    text: ?[]const u8 = null,
    class: ?[]const u8 = null,
    id: ?[]const u8 = null,

    fn concatProperties(self: Properties, allocator: std.mem.Allocator, begin: []const u8, end: []const u8, new_line_after: bool) ![]const u8 {
        const text = self.text orelse "text is empty";
        const end_open_tag = if (new_line_after) "\">\n" else "\">";

        if (self.class != null and self.id != null) {
            return try std.mem.concat(allocator, u8, &.{ begin, " class=\"", self.class.?, "\" id=\"", self.id.?, end_open_tag, text, end });
        }

        if (self.class) |class| return try std.mem.concat(allocator, u8, &.{ begin, " class=\"", class, end_open_tag, text, end });

        if (self.id) |id| return try std.mem.concat(allocator, u8, &.{ begin, " id=\"", id, end_open_tag, text, end });

        return try std.mem.concat(allocator, u8, &.{ begin, if (new_line_after) ">\n" else ">", text, end });
    }
};

const HtmlTag = enum(u8) {
    Header1,
    Header2,
    Header3,
    Header4,
    Header5,
    Header6,
    Div,
    Paragraph,
    Image,

    fn enclose(self: HtmlTag, allocator: std.mem.Allocator, properties: Properties) ![]const u8 {
        return switch (self) {
            .Header1 => try properties.concatProperties(allocator, "<h1", "</h1>\n", false),
            .Header2 => try properties.concatProperties(allocator, "<h2", "</h2>\n", false),
            .Header3 => try properties.concatProperties(allocator, "<h3", "</h3>\n", false),
            .Header4 => try properties.concatProperties(allocator, "<h4", "</h4>\n", false),
            .Header5 => try properties.concatProperties(allocator, "<h5", "</h5>\n", false),
            .Header6 => try properties.concatProperties(allocator, "<h6", "</h6>\n", false),
            .Div => try properties.concatProperties(allocator, "<div", "</div>\n", true),
            .Paragraph => try properties.concatProperties(allocator, "<p", "</p>\n", false),
            .Image => try std.mem.concat(allocator, u8, &.{ "<img src=\"images/", properties.text.?, "\" alt=\"", properties.text.?, "\" />\n" }),
        };
    }
};

test "html tag" {
    const allocator = testing.allocator;
    const result = try HtmlTag.Header1.enclose(allocator, .{ .text = "hello", .id = "chapter1.1" });
    defer allocator.free(result);
    try testing.expectEqualStrings("<h1 id=\"chapter1.1\">hello</h1>\n", result);
}

test "html builder" {
    const allocator = std.heap.page_allocator;
    var builder = HtmlBuilder.init(allocator);
    defer builder.deinit();

    const inner = try builder
        .add(.{ .text = "title" }, .Header1)
        .add(.{ .text = "hello, world", .id = "p1" }, .Paragraph)
        .add(.{ .text = "cover.png" }, .Image)
        .build();

    const inside_div = try builder.add(.{ .text = inner, .class = "cover" }, .Div).build();

    const expected =
        \\<div class="cover">
        \\<h1>title</h1>
        \\<p id="p1">hello, world</p>
        \\<img src="images/cover.png" alt="cover.png" />
        \\</div>
        \\
    ;

    try testing.expectEqualStrings(expected, inside_div);
}
