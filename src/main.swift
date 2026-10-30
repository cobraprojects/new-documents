import Cocoa
import FinderSync

final class SetupController: NSObject, NSApplicationDelegate {
    private let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 620, height: 700),
                                  styleMask: [.titled, .closable], backing: .buffered, defer: false)
    private let status = NSTextField(wrappingLabelWithString: "Finder extension status")

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
        stack.addArrangedSubview(buttons)
        let note = NSTextField(wrappingLabelWithString:
            "If needed, turn on New Documents in System Settings → General → Login Items & Extensions. Look under New Documents or File Providers. If New does not appear, hold Option, right-click Finder in the Dock, and choose Relaunch.\n\nWhen prompted, click Allow to grant access to your Home folder. Folders outside Home may need separate approval. macOS may hide New in iCloud Drive and some other cloud-managed folders.")
        note.textColor = .secondaryLabelColor
        note.font = .systemFont(ofSize: 12)
        stack.addArrangedSubview(note)
        let done = NSButton(title: "Done", target: self, action: #selector(quit))
        done.keyEquivalent = "\r"
        let footer = NSStackView(views: [done,
            NSButton(title: "Privacy Policy", target: self, action: #selector(openPrivacyPolicy))])
        footer.spacing = 10
        stack.addArrangedSubview(footer)
        window.contentView!.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 24)
        ])
        window.makeKeyAndOrderFront(nil)
        fileTypes.load()
        NSApp.activate(ignoringOtherApps: true)
        refresh()
    }

    func applicationDidBecomeActive(_ notification: Notification) { refresh() }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        window.makeKeyAndOrderFront(nil)
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    @objc private func refresh() {
        status.stringValue = FIFinderSyncController.isExtensionEnabled
            ? "✓ Finder extension is enabled. You can close this window."
            : "Enable New Documents in Extension Settings, then check again."
    }

    @objc private func openSettings() { FIFinderSyncController.showExtensionManagementInterface() }

    @objc private func openPrivacyPolicy() {
        NSWorkspace.shared.open(URL(string: "https://cobraprojects.github.io/new-documents/privacy.html")!)
    }

    @objc private func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let setup = SetupController()
app.delegate = setup
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
