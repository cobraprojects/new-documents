import Cocoa
import FinderSync

@objc(NewDocumentsExtension)
final class NewDocumentsExtension: FIFinderSync {
    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForContainer,
              FIFinderSyncController.default().targetedURL() != nil else { return nil }

        let menu = NSMenu()
        for (title, fileExtension) in [("New Text Document", "txt"), ("New Markdown File", "md")] {
            let item = menu.addItem(withTitle: title, action: #selector(createDocument(_:)), keyEquivalent: "")
            item.target = self
            item.tag = fileExtension == "md" ? 1 : 0
            item.image = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil)
        }
        return menu
    }

    @objc private func createDocument(_ sender: NSMenuItem) {
        guard let folder = FIFinderSyncController.default().targetedURL() else { return }
        let original = folder.appendingPathComponent(sender.tag == 1 ? "Untitled.md" : "Untitled.txt")
        var destination = original
        var suffix = 2
        do {
            while true {
                do {
                    try Data().write(to: destination, options: .withoutOverwriting)
                    break
                } catch CocoaError.fileWriteFileExists {
                    destination = original.deletingLastPathComponent()
                        .appendingPathComponent("Untitled \(suffix).\(original.pathExtension)")
                    suffix += 1
                }
            }
            NSWorkspace.shared.activateFileViewerSelecting([destination])
        } catch {
            let alert = NSAlert(error: error)
            alert.messageText = "Couldn’t create the document"
            alert.runModal()
        }
    }
}
