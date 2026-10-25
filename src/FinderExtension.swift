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
        do {
            let destination = try DocumentFiles.create(in: folder, type: menuTypes[sender.tag])
            NSWorkspace.shared.activateFileViewerSelecting([destination])
        } catch {
            let alert = NSAlert(error: error)
            alert.messageText = "Couldn’t create the document"
            alert.runModal()
        }
    }

    @objc private func openSettings() {
        let app = Bundle.main.bundleURL.deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        NSWorkspace.shared.openApplication(at: app, configuration: NSWorkspace.OpenConfiguration())
    }
}
