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
    \\<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
    \\<html xmlns="http://www.w3.org/1999/xhtml">
    \\<head>
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
    \\<body id="{s}-body">
    \\
;

pub const items_xhtml_close_body =
    \\</body>
    \\</html>
;

// --------------------------------
// Table of Contents xhtml
// --------------------------------
pub const toc_open_tag =
    \\<?xml version='1.0' encoding='utf-8'?>
    \\<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
    \\<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
    \\  <head>
    \\
;

pub const toc_uid =
    \\    <meta name="dtb:uid" content="urn:{s}:{s}"/>
    \\
;

pub const toc_doc_title =
    \\    <meta name="dtb:depth" content="1"/>
    \\    <meta name="dtb:totalPageCount" content="0"/>
    \\    <meta name="dtb:maxPageNumber" content="0"/>
    \\  </head>
    \\  <docTitle>
    \\
;

pub const toc_title_text =
    \\    <text>{s}</text>
    \\
;

pub const toc_open_nav_map =
    \\  </docTitle>
    \\  <navMap>
    \\
;

pub const toc_nav_point =
    \\    <navPoint id="navPoint-{d}" playOrder="{d}">
    \\
;

pub const toc_nav_point_text =
    \\      <navLabel><text>{s}</text></navLabel>
    \\
;

pub const toc_nav_point_content =
    \\      <content src="{s}.xhtml"/>
    \\
;

pub const toc_close_nav_point =
    \\    </navPoint>
    \\
;

pub const toc_nav_point_child =
    \\      <navPoint id="navPoint-{d}.{d}" playOrder="{d}">
    \\
;

pub const toc_nav_point_text_child =
    \\        <navLabel><text>{s}</text></navLabel>
    \\
;

pub const toc_nav_point_content_child =
    \\        <content src="{s}.xhtml#{s}"/>
    \\
;

pub const toc_close_nav_point_child =
    \\      </navPoint>
    \\
;

pub const toc_close =
    \\  </navMap>
    \\</ncx>
;
