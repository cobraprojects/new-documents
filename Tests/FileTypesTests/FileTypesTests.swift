import XCTest
import AppKit
@testable import NewDocumentsCore

final class FileTypesTests: XCTestCase {
    private var folder: URL!

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: folder)
    }

    func testMenuIconsFollowTextContrastAfterSerialization() throws {
        for (appearanceName, isDark) in [(NSAppearance.Name.aqua, false), (.darkAqua, true)] {
            let appearance = try XCTUnwrap(NSAppearance(named: appearanceName))
            let image = try XCTUnwrap(MenuIcon.make("doc.badge.plus", appearance: appearance))
            let data = try XCTUnwrap(image.tiffRepresentation)
            let bitmap = try XCTUnwrap(NSBitmapImageRep(data: data))
            var opaquePixels = 0
            for y in 0..<bitmap.pixelsHigh {
                for x in 0..<bitmap.pixelsWide {
                    guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB),
                          color.alphaComponent > 0.5 else { continue }
                    opaquePixels += 1
                    let brightness = (color.redComponent + color.greenComponent + color.blueComponent) / 3
                    if isDark { XCTAssertGreaterThan(brightness, 0.6) }
                    else { XCTAssertLessThan(brightness, 0.4) }
                }
            }
            XCTAssertGreaterThan(opaquePixels, 0)
        }
    }

    func testNewInstallIncludesEverydayFileTypes() throws {
        let types = try FileTypeStore(url: folder.appendingPathComponent("settings.json")).load()
        XCTAssertEqual(types.map(\.fileExtension), ["txt", "md", "docx", "xlsx", "pptx", "csv"])
        XCTAssertTrue(types.allSatisfy(\.enabled))
    }

    func testOfficeDocumentsAreValidArchivesOfWellFormedXML() throws {
        for ext in ["docx", "xlsx", "pptx", "report.DOCX"] {
            let url = try DocumentFiles.create(in: folder, type: FileType(name: "Office", fileExtension: ext))
            XCTAssertEqual(try unzip(["-tq", url.path]).contains("No errors"), true, ext)
            let parts = try unzip(["-Z1", url.path]).split(separator: "\n").map(String.init)
            XCTAssertTrue(parts.contains("[Content_Types].xml"), ext)
            for part in parts {
                XCTAssertNoThrow(try XMLDocument(data: Data(unzip(["-p", url.path, part.replacingOccurrences(of: "[", with: "[[]")]).utf8)), "\(ext) \(part)")
            }
        }
    }

    private func unzip(_ arguments: [String]) throws -> String {
        let process = Process(), pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = arguments
        process.standardOutput = pipe
        try process.run()
        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0, arguments.joined(separator: " "))
        return String(decoding: output, as: UTF8.self)
    }

    func testCustomizedTypesAndVisibilityPersist() throws {
        let url = folder.appendingPathComponent("preferences/settings.json")
        let types = [try FileType(name: "Text", fileExtension: "txt", enabled: false),
                     try FileType(name: "Configuration", fileExtension: ".toml")]
        try FileTypeStore(url: url).save(types)
        let loaded = try FileTypeStore(url: url).load()
        XCTAssertEqual(loaded, types)
        XCTAssertEqual(loaded.filter(\.enabled).map(\.fileExtension), ["toml"])
        try FileTypeStore(url: url).save([])
        XCTAssertEqual(try FileTypeStore(url: url).load(), [])
    }

    func testDuplicateExtensionsAreRejectedWithoutReplacingSettings() throws {
        let store = FileTypeStore(url: folder.appendingPathComponent("settings.json"))
        let original = [try FileType(name: "Text", fileExtension: "txt")]
        try store.save(original)
        XCTAssertThrowsError(try store.save(original + [FileType(name: "Duplicate", fileExtension: "TXT")]))
        XCTAssertEqual(try store.load(), original)
    }

    func testExtensionsCannotEscapeDestinationOrBeEmpty() throws {
        for ext in ["", ".", "../escape", "txt/escape", "txt\\escape", "a:b", "txt\nsh"] {
            XCTAssertThrowsError(try FileType(name: "Unsafe", fileExtension: ext), ext)
        }
        XCTAssertThrowsError(try FileType(name: "  ", fileExtension: "txt"))
    }

    func testCreationPreservesExistingFilesAndUsesSelectedCompoundExtension() throws {
        let original = folder.appendingPathComponent("Untitled.config.json")
        let content = Data("keep me".utf8)
        try content.write(to: original)
        let type = try FileType(name: "Config", fileExtension: "config.json")
        let second = try DocumentFiles.create(in: folder, type: type)
        let third = try DocumentFiles.create(in: folder, type: type)
        XCTAssertEqual(second.lastPathComponent, "Untitled 2.config.json")
        XCTAssertEqual(third.lastPathComponent, "Untitled 3.config.json")
        XCTAssertEqual(try Data(contentsOf: original), content)
        XCTAssertTrue(try Data(contentsOf: second).isEmpty)
    }

    func testConcurrentCreationNeverOverwritesAnotherDocument() throws {
        let type = try FileType(name: "Markdown", fileExtension: "md")
        let lock = NSLock()
        var created: [URL] = []
        var errors: [Error] = []
        DispatchQueue.concurrentPerform(iterations: 16) { _ in
            do {
                let url = try DocumentFiles.create(in: folder, type: type)
                lock.lock()
                created.append(url)
                lock.unlock()
            } catch {
                lock.lock()
                errors.append(error)
                lock.unlock()
            }
        }
        XCTAssertTrue(errors.isEmpty)
        XCTAssertEqual(Set(created).count, 16)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil).count, 16)
    }
}
