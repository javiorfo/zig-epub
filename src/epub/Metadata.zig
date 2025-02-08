const std = @import("std");

const uuid_ident_template =
    \\<dc:identifier id="bookid">urn:uuid:{s}</dc:identifier>
;
const isbn_ident_template =
    \\<dc:identifier id="isbn">{s}</dc:identifier>
;

title: []const u8,
creator: []const u8,
identifier: Identifier,
language: []const u8 = "en",
date: ?[]const u8 = null,
publisher: ?[]const u8 = null,

const Metadata = @This();

const Identifier = struct {
    value: []const u8,
    identifier_type: IdentifierType,

    fn createIdentifierTag(self: Identifier) []const u8 {
        _ = self;
        return "";
    }
};

const IdentifierType = enum(u2) {
    ISBN,
    UUID,
};
