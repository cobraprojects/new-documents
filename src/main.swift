import Cocoa
import FinderSync

final class SetupController: NSObject, NSApplicationDelegate {
    private let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 620, height: 700),
                                  styleMask: [.titled, .closable], backing: .buffered, defer: false)
    private let status = NSTextField(wrappingLabelWithString: "Registering Finder extension…")

    func applicationDidFinishLaunching(_ notification: Notification) {
        window.title = "New Documents"
        window.center()
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        let title = NSTextField(labelWithString: "New files, right in Finder")
        title.font = .boldSystemFont(ofSize: 22)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(NSTextField(wrappingLabelWithString:
            "Right-click an empty area in a local Finder folder, open New, and choose a file type. Press Return to rename the new file."))
        status.font = .boldSystemFont(ofSize: 13)
        let fileTypesTitle = NSTextField(labelWithString: "File Types")
        fileTypesTitle.font = .boldSystemFont(ofSize: 15)
        stack.addArrangedSubview(fileTypesTitle)
        let fileTypes = FileTypesView()
        stack.addArrangedSubview(fileTypes)
        fileTypes.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        stack.addArrangedSubview(status)
        let buttons = NSStackView()
        buttons.spacing = 10
        buttons.addArrangedSubview(NSButton(title: "Extension Settings…", target: self, action: #selector(openSettings)))
        buttons.addArrangedSubview(NSButton(title: "Check Status", target: self, action: #selector(refresh)))
        buttons.addArrangedSubview(NSButton(title: "Relaunch Finder", target: self, action: #selector(relaunchFinder)))
        stack.addArrangedSubview(buttons)
        let note = NSTextField(wrappingLabelWithString:
            "If needed, turn on New Documents in System Settings → General → Login Items & Extensions. Look under New Documents or File Providers.\n\nmacOS hides these menu items in iCloud Drive and some other cloud-managed folders.")
        note.textColor = .secondaryLabelColor
        note.font = .systemFont(ofSize: 12)
        stack.addArrangedSubview(note)
        let done = NSButton(title: "Done", target: self, action: #selector(quit))
        done.keyEquivalent = "\r"
        stack.addArrangedSubview(done)
        window.contentView!.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 24)
        ])
        window.makeKeyAndOrderFront(nil)
        fileTypes.load()
        NSApp.activate(ignoringOtherApps: true)
        let appPath = Bundle.main.bundleURL.path
        let extensionPath = Bundle.main.bundleURL.appendingPathComponent("Contents/PlugIns/NewDocumentsExtension.appex").path
        DispatchQueue.global(qos: .userInitiated).async {
            _ = Self.run("/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister", ["-f", appPath])
            let registered = Self.run("/usr/bin/pluginkit", ["-a", extensionPath]) != nil
            let enabled = registered && Self.run("/usr/bin/pluginkit", ["-e", "use", "-i", "local.codex.NewDocuments.FinderExtension"]) != nil
            DispatchQueue.main.async {
                self.refresh()
                if !enabled { self.status.stringValue = "Open Extension Settings to enable New Documents." }
            }
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) { refresh() }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        window.makeKeyAndOrderFront(nil)
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    @objc private func refresh() {
        let listing = Self.run("/usr/bin/pluginkit", ["-m", "-A", "-D", "-v", "-i", "local.codex.NewDocuments.FinderExtension"]) ?? ""
        let extensionPath = Bundle.main.bundleURL.appendingPathComponent("Contents/PlugIns/NewDocumentsExtension.appex").path
        let enabled = listing.split(separator: "\n").contains {
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("+") && $0.contains(extensionPath)
        }
        status.stringValue = enabled
            ? "✓ Finder extension is enabled. You can close this window."
            : "Enable New Documents in Extension Settings, then check again."
    }

    @objc private func openSettings() { FIFinderSyncController.showExtensionManagementInterface() }

    @objc private func relaunchFinder() {
        let alert = NSAlert()
        alert.messageText = "Relaunch Finder?"
        alert.informativeText = "Finder windows will briefly close and reopen. Wait for any file copies to finish first."
        alert.addButton(withTitle: "Relaunch Finder")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            _ = Self.run("/usr/bin/killall", ["Finder"])
        }
    }

    @objc private func quit() { NSApp.terminate(nil) }

    private static func run(_ executable: String, _ arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            let data = output.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return process.terminationStatus == 0 ? String(decoding: data, as: UTF8.self) : nil
        } catch { return nil }
    }
}

let app = NSApplication.shared
let setup = SetupController()
app.delegate = setup
if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
   let icon = NSImage(contentsOf: iconURL) {
    app.applicationIconImage = icon
}
app.run()
