import Cocoa
import FinderSync

@objc(NewDocumentsExtension)
final class NewDocumentsExtension: FIFinderSync {
    private var menuTypes: [FileType] = []
    private var permissionPanel: NSOpenPanel?

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        // Also offer the menu on items: in full List view windows there is no empty space to click.
        guard menuKind == .contextualMenuForContainer || menuKind == .contextualMenuForItems,
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
        if let permissionPanel {
            permissionPanel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        guard menuTypes.indices.contains(sender.tag),
              let folder = FIFinderSyncController.default().targetedURL() else { return }
        let type = menuTypes[sender.tag]
        Task { @MainActor in
            do {
                guard let access = try await self.authorizedFolder(containing: folder) else { return }
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

    @MainActor private func authorizedFolder(containing folder: URL) async throws -> URL? {
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

        // Offer the real Home folder (not the sandbox container) so one approval covers most folders.
        let home = getpwuid(getuid()).flatMap { URL(fileURLWithPath: String(cString: $0.pointee.pw_dir)) }
        let inHome = home.map { folder.standardizedFileURL.path.hasPrefix($0.standardizedFileURL.path + "/") } ?? false
        let panel = NSOpenPanel()
        panel.title = "Allow New Documents to create files"
        panel.message = inHome
            ? "Click Allow to let New Documents create files anywhere in your Home folder. You’ll only be asked once."
            : "Click Allow to let New Documents create files in this folder. You’ll only be asked once for it."
        panel.prompt = "Allow"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.directoryURL = inHome ? home : folder
        permissionPanel = panel
        defer { permissionPanel = nil }
        let response = await withCheckedContinuation { continuation in
            panel.begin { continuation.resume(returning: $0) }
            panel.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
        }
        guard response == .OK, let selected = panel.url else { return nil }
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
