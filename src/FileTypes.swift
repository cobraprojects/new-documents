import Foundation

struct FileType: Codable, Equatable {
    var name: String
    var fileExtension: String
    var enabled = true

    init(name: String, fileExtension: String, enabled: Bool = true) throws {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.fileExtension = fileExtension.trimmingCharacters(in: .whitespacesAndNewlines)
        if self.fileExtension.hasPrefix(".") { self.fileExtension.removeFirst() }
        self.enabled = enabled
        try validate()
    }

    func validate() throws {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-+"))
        guard !name.isEmpty, name.utf8.count <= 100,
              !name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
              !fileExtension.isEmpty, fileExtension.utf8.count <= 100,
              !fileExtension.hasPrefix("."), !fileExtension.hasSuffix("."),
              fileExtension.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            throw FileTypeError.invalidType
        }
    }
}

enum FileTypeError: LocalizedError {
    case invalidType, duplicateExtension

    var errorDescription: String? {
        switch self {
        case .invalidType:
            return "Enter a name and an extension such as txt, md, or config.json. Extensions can contain letters, numbers, dots, underscores, plus signs, and hyphens."
        case .duplicateExtension:
            return "That extension is already in the list. Enable its existing entry instead."
        }
    }
}

struct FileTypeStore {
    private let customURL: URL?

    init(url: URL? = nil) {
        customURL = url
    }

    private var url: URL {
        get throws {
            if let customURL { return customURL }
            guard let group = Bundle.main.object(forInfoDictionaryKey: "NewDocumentsAppGroup") as? String,
                  let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
                throw CocoaError(.fileReadNoPermission)
            }
            return container.appendingPathComponent("file-types.json")
        }
    }

    static var defaults: [FileType] {
        let types = [("Text Document", "txt"), ("Markdown File", "md"), ("Word Document", "docx"),
                     ("Excel Spreadsheet", "xlsx"), ("PowerPoint Presentation", "pptx"), ("CSV File", "csv")]
        return types.map { try! FileType(name: $0.0, fileExtension: $0.1) }
    }

    func load() throws -> [FileType] {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch CocoaError.fileReadNoSuchFile {
            return Self.defaults
        }
        let types = try JSONDecoder().decode([FileType].self, from: data)
        try validate(types)
        return types
    }

    func save(_ types: [FileType]) throws {
        try validate(types)
        let data = try JSONEncoder().encode(types)
        let url = try url
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    private func validate(_ types: [FileType]) throws {
        var extensions = Set<String>()
        for type in types {
            try type.validate()
            guard extensions.insert(type.fileExtension.lowercased()).inserted else {
                throw FileTypeError.duplicateExtension
            }
        }
    }
}

enum DocumentFiles {
    static func create(in folder: URL, type: FileType) throws -> URL {
        try type.validate()
        let contents = DocumentTemplates.contents(forExtension: type.fileExtension)
        var suffix = 1
        while true {
            let name = suffix == 1 ? "Untitled" : "Untitled \(suffix)"
            let destination = folder.appendingPathComponent("\(name).\(type.fileExtension)")
            do {
                try contents.write(to: destination, options: .withoutOverwriting)
                return destination
            } catch CocoaError.fileWriteFileExists {
                suffix += 1
            }
        }
    }
}
