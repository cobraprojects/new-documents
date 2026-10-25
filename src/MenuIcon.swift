import Cocoa

enum MenuIcon {
    static func make(_ name: String, appearance: NSAppearance) -> NSImage? {
        guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil) else { return nil }
        // Finder copies extension icons without reliably preserving template rendering.
        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.lockFocus()
        appearance.performAsCurrentDrawingAppearance {
            symbol.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16))
            NSColor.labelColor.setFill()
            NSRect(x: 0, y: 0, width: 16, height: 16).fill(using: .sourceIn)
        }
        image.unlockFocus()
        return image
    }

}
