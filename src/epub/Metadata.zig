const std = @import("std");
const UUID = @import("../util/UUID.zig");

title: []const u8,
creator: []const u8,
identifier: Identifier,
language: Language = .English,
date: ?[]const u8 = null,
publisher: ?[]const u8 = null,

const Metadata = @This();

pub fn defaultIdentifier() Identifier {
    return .{
        .identifier_type = .UUID,
        .value = UUID.new(),
    };
}

const Identifier = struct {
    value: []const u8,
    identifier_type: IdentifierType,
};

const IdentifierType = enum(u2) {
    ISBN,
    UUID,
};

const Language = enum(u8) {
    Arabic,
    Chinese,
    Croatian,
    Czech,
    Dutch,
    English,
    French,
    Greek,
    German,
    Hungarian,
    Italian,
    Japanese,
    Korean,
    Polish,
    Portuguese,
    Romanian,
    Russian,
    Slovak,
    Slovenian,
    Spanish,
    Swedish,
    Turkish,

    pub fn toString(self: Language) []const u8 {
        return switch (self) {
            .Arabic => "ar",
            .Chinese => "zh",
            .Croatian => "hr",
            .Czech => "cs",
            .Dutch => "nl",
            .English => "en",
            .French => "fr",
            .Greek => "gl",
            .German => "de",
            .Hungarian => "hu",
            .Italian => "it",
            .Japanese => "ja",
            .Korean => "ko",
            .Polish => "pl",
            .Portuguese => "pt",
            .Romanian => "ro",
            .Russian => "ru",
            .Slovak => "sk",
            .Slovenian => "sl",
            .Spanish => "es",
            .Swedish => "sv",
            .Turkish => "tr",
        };
    }
};
