import Cocoa

final class FileTypesView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    private let store = FileTypeStore()
    private var types: [FileType] = []
    private let table = NSTableView()
    private let remove = NSButton(title: "Remove", target: nil, action: nil)

    override init(frame: NSRect) {
        super.init(frame: frame)
        table.dataSource = self
        table.delegate = self
        table.usesAlternatingRowBackgroundColors = true
        table.allowsMultipleSelection = true
        table.rowHeight = 28
        for (id, title, width) in [("enabled", "Show", 52.0), ("name", "File type", 270.0), ("extension", "Extension", 160.0)] {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
            column.title = title
            column.width = width
            table.addTableColumn(column)
        }
        table.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        let buttons = NSStackView()
        buttons.spacing = 10
        buttons.addArrangedSubview(NSButton(title: "Add File Type…", target: self, action: #selector(addType)))
        remove.target = self
        remove.action = #selector(removeTypes)
        remove.isEnabled = false
        buttons.addArrangedSubview(remove)
        let note = NSTextField(wrappingLabelWithString: "Changes save automatically and apply the next time you open Finder’s New menu. Each type creates an empty file; document formats such as .docx need a template to be valid.")
        note.font = .systemFont(ofSize: 12)
        note.textColor = .secondaryLabelColor
        let stack = NSStackView(views: [scroll, buttons, note])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            scroll.widthAnchor.constraint(equalTo: stack.widthAnchor),
            scroll.heightAnchor.constraint(equalToConstant: 220),
            note.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func load() {
        do {
            types = try store.load()
            table.reloadData()
        } catch { NSAlert(error: error).runModal() }
    }

    func numberOfRows(in tableView: NSTableView) -> Int { types.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let type = types[row]
        if tableColumn?.identifier.rawValue == "enabled" {
            let checkbox = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleType(_:)))
            checkbox.setAccessibilityLabel("Show \(type.name)")
            checkbox.state = type.enabled ? .on : .off
            checkbox.tag = row
            return checkbox
        }
        let text = tableColumn?.identifier.rawValue == "name" ? type.name : ".\(type.fileExtension)"
        return NSTextField(labelWithString: text)
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        remove.isEnabled = !table.selectedRowIndexes.isEmpty
    }

    @objc private func toggleType(_ sender: NSButton) {
        var updated = types
        updated[sender.tag].enabled = sender.state == .on
        persist(updated)
    }

    @objc private func removeTypes() {
        let selected = table.selectedRowIndexes
        persist(types.enumerated().filter { !selected.contains($0.offset) }.map(\.element))
    }

    @objc private func addType() {
        let alert = NSAlert()
        alert.messageText = "Add File Type"
        alert.informativeText = "Choose the name shown in Finder and the filename extension."
        let name = NSTextField(string: "")
        name.placeholderString = "e.g. Configuration File"
        name.setAccessibilityLabel("File type name")
        let fileExtension = NSTextField(string: "")
        fileExtension.placeholderString = "e.g. toml"
        fileExtension.setAccessibilityLabel("Filename extension")
        let fields = NSStackView(views: [NSTextField(labelWithString: "Name"), name,
                                       NSTextField(labelWithString: "Extension"), fileExtension])
        fields.orientation = .vertical
        fields.alignment = .leading
        fields.spacing = 6
        fields.frame = NSRect(x: 0, y: 0, width: 340, height: 110)
        name.widthAnchor.constraint(equalToConstant: 340).isActive = true
        fileExtension.widthAnchor.constraint(equalToConstant: 340).isActive = true
        alert.accessoryView = fields
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = name
        while alert.runModal() == .alertFirstButtonReturn {
            do {
                let type = try FileType(name: name.stringValue, fileExtension: fileExtension.stringValue)
                try store.save(types + [type])
                types.append(type)
                table.reloadData()
                return
            } catch { NSAlert(error: error).runModal() }
        }
    }

    private func persist(_ updated: [FileType]) {
        do {
            try store.save(updated)
            types = updated
        } catch { NSAlert(error: error).runModal() }
        table.reloadData()
        remove.isEnabled = !table.selectedRowIndexes.isEmpty
    }
}
