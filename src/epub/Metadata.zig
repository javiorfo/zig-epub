const std = @import("std");

/// The title of the EPUB document.
title: []const u8,

/// The creator(s) of the EPUB document.
creator: []const u8,

/// The identifier for the EPUB document. (UUID or ISBN)
identifier: Identifier,

/// The language of the EPUB document.
language: Language = .English,

/// The date associated with the EPUB document.
date: ?[]const u8 = null,

/// The publisher of the EPUB document.
publisher: ?[]const u8 = null,

const Metadata = @This();

/// Represents an identifier for an EPUB document.
const Identifier = struct {
    value: []const u8,
    identifier_type: IdentifierType,
};

/// Represents the different types of identifiers for an EPUB document.
const IdentifierType = enum(u2) {
    /// ISBN (International Standard Book Number) identifier.
    ISBN,

    /// UUID (Universally Unique Identifier) identifier.
    UUID,
};

/// Represents the different languages supported for an EPUB document.
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

    /// Returns the ISO 639-1 language code for the current language.
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
