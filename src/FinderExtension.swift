import Cocoa
import FinderSync

@objc(NewDocumentsExtension)
final class NewDocumentsExtension: FIFinderSync {
    private var menuTypes: [FileType] = []

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForContainer,
              FIFinderSyncController.default().targetedURL() != nil else { return nil }

        let menu = NSMenu()
        let icon = MenuIcon.make("doc.badge.plus", appearance: NSApp.effectiveAppearance)
        let new = menu.addItem(withTitle: "New", action: nil, keyEquivalent: "")
        new.image = icon
        let submenu = NSMenu(title: "New")
        new.submenu = submenu
        do {
            menuTypes = try FileTypeStore().load().filter(\.enabled)
            for (index, type) in menuTypes.enumerated() {
                let item = submenu.addItem(withTitle: "\(type.name) (.\(type.fileExtension))",
                                           action: #selector(createDocument(_:)), keyEquivalent: "")
                item.target = self
                item.tag = index
                item.image = icon
            }
            if menuTypes.isEmpty {
                let empty = submenu.addItem(withTitle: "No file types enabled", action: nil, keyEquivalent: "")
                empty.isEnabled = false
            }
        } catch {
            menuTypes = []
            let unavailable = submenu.addItem(withTitle: "File types could not be loaded", action: nil, keyEquivalent: "")
            unavailable.isEnabled = false
        }
        submenu.addItem(.separator())
        let settings = submenu.addItem(withTitle: "Manage File Types…", action: #selector(openSettings), keyEquivalent: "")
        settings.target = self
        settings.image = MenuIcon.make("gearshape", appearance: NSApp.effectiveAppearance)
        return menu
    }

    @objc private func createDocument(_ sender: NSMenuItem) {
        guard menuTypes.indices.contains(sender.tag),
              let folder = FIFinderSyncController.default().targetedURL() else { return }
        let type = menuTypes[sender.tag]
        DispatchQueue.main.async {
            do {
                guard let access = try self.authorizedFolder(containing: folder) else { return }
                defer { access.stopAccessingSecurityScopedResource() }
                let destination = try DocumentFiles.create(in: folder, type: type)
                NSWorkspace.shared.activateFileViewerSelecting([destination])
            } catch {
                let alert = NSAlert(error: error)
                alert.messageText = "Couldn’t create the document"
                alert.runModal()
            }
        }
    }

    private func authorizedFolder(containing folder: URL) throws -> URL? {
        var bookmarks = UserDefaults.standard.dictionary(forKey: "authorizedFolders") as? [String: Data] ?? [:]
        var ancestor = folder.standardizedFileURL
        while true {
            if let data = bookmarks[ancestor.path] {
                var stale = false
                if let url = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI],
                                      relativeTo: nil, bookmarkDataIsStale: &stale),
                   url.startAccessingSecurityScopedResource() {
                    if stale {
                        do {
                            bookmarks[ancestor.path] = try url.bookmarkData(options: .withSecurityScope,
                                includingResourceValuesForKeys: nil, relativeTo: nil)
                            UserDefaults.standard.set(bookmarks, forKey: "authorizedFolders")
                        } catch {
                            url.stopAccessingSecurityScopedResource()
                            throw error
                        }
                    }
                    return url
                }
            }
            guard ancestor.path != "/" else { break }
            ancestor.deleteLastPathComponent()
        }

        let panel = NSOpenPanel()
        panel.title = "Allow New Documents to create files"
        panel.message = "Choose this folder or a parent folder. Permission is remembered for future files in that folder."
        panel.prompt = "Allow"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.directoryURL = folder
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let selected = panel.url else { return nil }
        defer { selected.stopAccessingSecurityScopedResource() }
        let path = selected.standardizedFileURL.path
        guard folder.standardizedFileURL.path == path || folder.standardizedFileURL.path.hasPrefix(path == "/" ? "/" : path + "/") else {
            throw CocoaError(.fileWriteNoPermission)
        }
        let data = try selected.bookmarkData(options: .withSecurityScope,
            includingResourceValuesForKeys: nil, relativeTo: nil)
        bookmarks[path] = data
        UserDefaults.standard.set(bookmarks, forKey: "authorizedFolders")
        var stale = false
        let access = try URL(resolvingBookmarkData: data, options: .withSecurityScope,
                             relativeTo: nil, bookmarkDataIsStale: &stale)
        guard access.startAccessingSecurityScopedResource() else { throw CocoaError(.fileWriteNoPermission) }
        return access
    }

    @objc private func openSettings() {
        let app = Bundle.main.bundleURL.deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        NSWorkspace.shared.openApplication(at: app, configuration: NSWorkspace.OpenConfiguration())
    }
}
