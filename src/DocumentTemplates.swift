import Foundation

/// Minimal blank Office Open XML documents. Other extensions are created empty.
enum DocumentTemplates {
    static func contents(forExtension fileExtension: String) -> Data {
        switch fileExtension.split(separator: ".").last?.lowercased() {
        case "docx": return zip(word)
        case "xlsx": return zip(spreadsheet)
        case "pptx": return zip(presentation)
        default: return Data()
        }
    }

    private static let header = #"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>"#
    private static let relationshipType = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    private static let officeType = "application/vnd.openxmlformats-officedocument"

    private static func contentTypes(_ overrides: [(String, String)]) -> String {
        header + #"<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">"#
            + #"<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>"#
            + #"<Default Extension="xml" ContentType="application/xml"/>"#
            + overrides.map { #"<Override PartName="/\#($0.0)" ContentType="\#(officeType).\#($0.1)"/>"# }.joined()
            + "</Types>"
    }

    private static func relationships(_ targets: [(String, String)]) -> String {
        header + #"<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">"#
            + targets.enumerated().map { index, target in
                #"<Relationship Id="rId\#(index + 1)" Type="\#(relationshipType)/\#(target.0)" Target="\#(target.1)"/>"#
            }.joined()
            + "</Relationships>"
    }

    private static var word: [(String, String)] {
        [("[Content_Types].xml", contentTypes([("word/document.xml", "wordprocessingml.document.main+xml")])),
         ("_rels/.rels", relationships([("officeDocument", "word/document.xml")])),
         ("word/document.xml", header
            + #"<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body><w:p/></w:body></w:document>"#)]
    }

    private static var spreadsheet: [(String, String)] {
        let main = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
        return [("[Content_Types].xml", contentTypes([("xl/workbook.xml", "spreadsheetml.sheet.main+xml"),
                                                      ("xl/worksheets/sheet1.xml", "spreadsheetml.worksheet+xml")])),
                ("_rels/.rels", relationships([("officeDocument", "xl/workbook.xml")])),
                ("xl/workbook.xml", header + #"<workbook xmlns="\#(main)" xmlns:r="\#(relationshipType)">"#
                    + #"<sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>"#),
                ("xl/_rels/workbook.xml.rels", relationships([("worksheet", "worksheets/sheet1.xml")])),
                ("xl/worksheets/sheet1.xml", header + #"<worksheet xmlns="\#(main)"><sheetData/></worksheet>"#)]
    }

    private static var presentation: [(String, String)] {
        let namespaces = #"xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="\#(relationshipType)" "#
            + #"xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main""#
        let shapes = #"<p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld>"#
        let colors = ["dk2": "44546A", "lt2": "E7E6E6", "accent1": "4472C4", "accent2": "ED7D31", "accent3": "A5A5A5",
                      "accent4": "FFC000", "accent5": "5B9BD5", "accent6": "70AD47", "hlink": "0563C1", "folHlink": "954F72"]
        let schemeColors = ["dk2", "lt2", "accent1", "accent2", "accent3", "accent4", "accent5", "accent6", "hlink", "folHlink"]
            .map { "<a:\($0)><a:srgbClr val=\"\(colors[$0]!)\"/></a:\($0)>" }.joined()
        let fill = #"<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>"#
        let theme = header + #"<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Office Theme"><a:themeElements>"#
            + #"<a:clrScheme name="Office"><a:dk1><a:sysClr val="windowText" lastClr="000000"/></a:dk1>"#
            + #"<a:lt1><a:sysClr val="window" lastClr="FFFFFF"/></a:lt1>"# + schemeColors + "</a:clrScheme>"
            + #"<a:fontScheme name="Office"><a:majorFont><a:latin typeface="Calibri Light"/><a:ea typeface=""/><a:cs typeface=""/></a:majorFont>"#
            + #"<a:minorFont><a:latin typeface="Calibri"/><a:ea typeface=""/><a:cs typeface=""/></a:minorFont></a:fontScheme>"#
            + #"<a:fmtScheme name="Office"><a:fillStyleLst>"# + String(repeating: fill, count: 3) + "</a:fillStyleLst><a:lnStyleLst>"
            + String(repeating: #"<a:ln w="6350">\#(fill)</a:ln>"#, count: 3) + "</a:lnStyleLst><a:effectStyleLst>"
            + String(repeating: "<a:effectStyle><a:effectLst/></a:effectStyle>", count: 3) + "</a:effectStyleLst><a:bgFillStyleLst>"
            + String(repeating: fill, count: 3) + "</a:bgFillStyleLst></a:fmtScheme></a:themeElements></a:theme>"
        let colorMap = #"<p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" "#
            + #"accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>"#
        return [("[Content_Types].xml", contentTypes([
                    ("ppt/presentation.xml", "presentationml.presentation.main+xml"),
                    ("ppt/slideMasters/slideMaster1.xml", "presentationml.slideMaster+xml"),
                    ("ppt/slideLayouts/slideLayout1.xml", "presentationml.slideLayout+xml"),
                    ("ppt/slides/slide1.xml", "presentationml.slide+xml"),
                    ("ppt/theme/theme1.xml", "theme+xml")])),
                ("_rels/.rels", relationships([("officeDocument", "ppt/presentation.xml")])),
                ("ppt/presentation.xml", header + "<p:presentation \(namespaces)>"
                    + #"<p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>"#
                    + #"<p:sldIdLst><p:sldId id="256" r:id="rId3"/></p:sldIdLst>"#
                    + #"<p:sldSz cx="12192000" cy="6858000"/><p:notesSz cx="6858000" cy="9144000"/></p:presentation>"#),
                ("ppt/_rels/presentation.xml.rels", relationships([("slideMaster", "slideMasters/slideMaster1.xml"),
                                                                   ("theme", "theme/theme1.xml"),
                                                                   ("slide", "slides/slide1.xml")])),
                ("ppt/slideMasters/slideMaster1.xml", header + "<p:sldMaster \(namespaces)>" + shapes + colorMap
                    + #"<p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rId1"/></p:sldLayoutIdLst></p:sldMaster>"#),
                ("ppt/slideMasters/_rels/slideMaster1.xml.rels", relationships([("slideLayout", "../slideLayouts/slideLayout1.xml"),
                                                                                ("theme", "../theme/theme1.xml")])),
                ("ppt/slideLayouts/slideLayout1.xml", header + #"<p:sldLayout \#(namespaces) type="blank" preserve="1">"#
                    + shapes.replacingOccurrences(of: "<p:cSld>", with: #"<p:cSld name="Blank">"#)
                    + "<p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sldLayout>"),
                ("ppt/slideLayouts/_rels/slideLayout1.xml.rels", relationships([("slideMaster", "../slideMasters/slideMaster1.xml")])),
                ("ppt/slides/slide1.xml", header + "<p:sld \(namespaces)>" + shapes
                    + "<p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>"),
                ("ppt/slides/_rels/slide1.xml.rels", relationships([("slideLayout", "../slideLayouts/slideLayout1.xml")])),
                ("ppt/theme/theme1.xml", theme)]
    }

    /// Writes an uncompressed ZIP archive, the container format used by Office documents.
    private static func zip(_ entries: [(String, String)]) -> Data {
        var archive = Data(), directory = Data()
        for (name, text) in entries {
            let path = Data(name.utf8), body = Data(text.utf8), checksum = crc32(body)
            let offset = UInt32(archive.count)
            // Version 2.0, no flags, stored, DOS date 1980-01-01.
            let fields: [UInt16] = [20, 0, 0, 0, 0x21]
            archive.append(UInt32(0x04034b50))
            fields.forEach { archive.append($0) }
            [checksum, UInt32(body.count), UInt32(body.count)].forEach { archive.append($0) }
            [UInt16(path.count), 0].forEach { archive.append($0) }
            archive.append(path)
            archive.append(body)

            directory.append(UInt32(0x02014b50))
            directory.append(UInt16(20))
            fields.forEach { directory.append($0) }
            [checksum, UInt32(body.count), UInt32(body.count)].forEach { directory.append($0) }
            [UInt16(path.count), 0, 0, 0, 0].forEach { directory.append($0) }
            [UInt32(0), offset].forEach { directory.append($0) }
            directory.append(path)
        }
        let directoryOffset = UInt32(archive.count)
        archive.append(directory)
        archive.append(UInt32(0x06054b50))
        [0, 0, UInt16(entries.count), UInt16(entries.count)].forEach { archive.append($0) }
        [UInt32(directory.count), directoryOffset].forEach { archive.append($0) }
        archive.append(UInt16(0))
        return archive
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc = ~UInt32(0)
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 { crc = crc & 1 == 1 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1 }
        }
        return ~crc
    }
}

private extension Data {
    mutating func append<T: FixedWidthInteger>(_ value: T) {
        Swift.withUnsafeBytes(of: value.littleEndian) { append(contentsOf: $0) }
    }
}
