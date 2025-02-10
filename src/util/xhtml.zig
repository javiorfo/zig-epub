const std = @import("std");

// --------------------------------
// CONTENT OPF
// --------------------------------
pub const content_opf_package_metadata =
    \\<?xml version='1.0' encoding='utf-8'?>
    \\<package xmlns="http://www.idpf.org/2007/opf"
    \\        xmlns:dc="http://purl.org/dc/elements/1.1/"
    \\        unique-identifier="bookid" version="2.0">
    \\  <metadata>
    \\
;

pub const content_opf_metadata_manifest =
    \\  </metadata>
    \\  <manifest>
    \\    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    \\
;

pub const content_opf_manifest_spine =
    \\  </manifest>
    \\  <spine toc="ncx">
    \\
;

pub const content_opf_spine_guide =
    \\  </spine>
    \\  <guide>
    \\
;

pub const content_opf_guide_package =
    \\  </guide>
    \\</package>
    \\
;

// content.opf metadata tags
pub const content_opt_metadata_title =
    \\    <dc:title>{s}</dc:title>
    \\
;

pub const content_opt_metadata_creator =
    \\    <dc:creator>{s}</dc:creator>
    \\
;

pub const content_opt_metadata_language =
    \\    <dc:language>{s}</dc:language>
    \\
;

pub const content_opt_metadata_date =
    \\    <dc:date>{s}</dc:date>
    \\
;

pub const content_opt_metadata_publisher =
    \\    <dc:publisher>{s}</dc:publisher>
    \\
;

pub const content_opt_metadata_identifier_uuid =
    \\    <dc:identifier id="bookid">urn:uuid:{s}</dc:identifier>
    \\
;

pub const content_opt_metadata_identifier_isbn =
    \\    <dc:identifier id="bookid">urn:isbn:{s}</dc:identifier>
    \\
;

pub const content_opt_metadata_cover_image =
    \\    <meta name="cover" content="cover-image" />
    \\
;

// content.opf manifest tags
pub const content_opf_manifest_xhtml =
    \\    <item id="{s}" href="{s}.xhtml" media-type="application/xhtml+xml"/>
    \\
;

pub const content_opf_manifest_css =
    \\    <item id="css" href="stylesheet.css" media-type="text/css"/>
    \\
;

pub const content_opf_manifest_cover_image =
    \\    <item id="cover-image" href="images/{s}" media-type="image/{s}"/>
    \\
;

// content.opf spine tags
pub const content_opf_spine_cover =
    \\    <itemref idref="cover" linear="no"/>
    \\
;

pub const content_opf_spine_item =
    \\    <itemref idref="{s}"/>
    \\
;

// content.opf guide tags
pub const content_opf_guide_reference =
    \\    <reference href="{s}.xhtml" type="{s}" title="{s}"/>
    \\
;

// --------------------------------
// ITEMS xhtml
// --------------------------------
pub const items_xhtml_open_tag =
    \\<!DOCTYPE html>
    \\<html xmlns="http://www.w3.org/1999/xhtml">
    \\<head>
    \\  <meta charset="utf-8"/>
    \\
;

pub const items_xhtml_title =
    \\  <title>{s}</title>
    \\
;

pub const items_xhtml_stylesheet =
    \\  <link rel="stylesheet" type="text/css" href="stylesheet.css"/>
    \\
;

pub const items_xhtml_open_body =
    \\</head>
    \\<body>
    \\
;

pub const items_xhtml_close_body =
    \\</body>
    \\</html>
;
