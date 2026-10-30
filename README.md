# New Documents

<img src="assets/AppIcon.png" width="128" alt="New Documents app icon">

Create new text, Markdown, Office, and CSV files from a customizable **New** submenu in Finder’s right-click menu.

- **New → Text Document** creates `Untitled.txt`.
- **New → Markdown File** creates `Untitled.md`.
- Also includes Word (`.docx`), Excel (`.xlsx`), PowerPoint (`.pptx`), and CSV. Add any other extension in **Manage File Types…**.
- **New → Manage File Types…** lets you show or hide entries and add or remove custom extensions.
- Menu icons use macOS’s text color for the current light or dark appearance.
- Existing files are preserved: filenames increment to `Untitled 2.md`, and so on.
- The created file is selected. Press **Return** to rename it.

Supports **Apple Silicon and Intel Macs running macOS Ventura 13 or later**.

## Download

[Download the latest installer](https://github.com/cobraprojects/new-documents/releases/latest/download/New-Documents-Installer.pkg)

A [portable app ZIP](https://github.com/cobraprojects/new-documents/releases/latest/download/New-Documents-Universal.zip) is also available. The [release page](https://github.com/cobraprojects/new-documents/releases/latest) includes checksums and release notes.

## Install and enable

1. Open `New-Documents-Installer.pkg` and follow the installer. An administrator password is required; the app installs into `/Applications`.
2. Open **New Documents** from Applications.
3. Click **Extension Settings…** and enable **New Documents** if it is disabled. Depending on macOS, it appears under **New Documents** or **File Providers** in **System Settings → General → Login Items & Extensions**.
4. Return to setup and click **Check Status**.
5. Right-click an empty area inside a local Finder folder, open **New**, and choose the document type.

Close setup when finished. No login item, Terminal commands, or development tools are needed to use the app.

If **New** does not appear after installing or updating, hold **Option**, right-click Finder in the Dock, and choose **Relaunch**.

### If macOS blocks the download

This release is locally signed and **has not been signed with Developer ID or notarized by Apple**. After attempting to open the installer, go to **System Settings → Privacy & Security → Open Anyway** for this package, then confirm.

See [Apple’s instructions for opening an app from an unidentified developer](https://support.apple.com/102445). Managed Macs may prevent this exception.

### Portable installation

Unzip `New-Documents-Universal.zip`, move **New Documents.app** into `/Applications`, and open it to enable the extension in macOS settings. Use the same **Open Anyway** process if macOS blocks the app. Keep only one installed copy to avoid conflicting extension registrations.

## Customize the New menu

Open **New → Manage File Types…**, or open **New Documents** from Applications.

- Use the **Show** checkbox to include or hide a file type.
- Click **Add File Type…**, enter a name and an extension (for example, `Configuration File` and `.toml`), then click **Add**.
- Select one or more rows and click **Remove** to delete entries from the list. This does not delete any documents.

Changes save automatically and appear the next time the New menu opens. When an update adds a new built-in file type, it is added once to your saved list; types you removed stay removed. Updating from 1.4.0 build 9 or earlier also removes the old built-in developer types (JSON, YAML, HTML, CSS, JavaScript, TypeScript, Python, shell, XML, SQL); add any of them back with **Add File Type…**. Duplicate extensions are rejected. Compound extensions such as `config.json` are supported. App Store builds store settings in their shared App Group container. Earlier GitHub releases used `~/Library/Application Support/New Documents/file-types.json`; their custom settings are separate from the App Store installation.

`.docx`, `.xlsx`, and `.pptx` files start as minimal blank documents that open in Microsoft Office, Pages, Numbers, Keynote, and Quick Look. All other types create **empty files**, so adding an extension such as `.png` or `.pdf` does not create a valid image or document; those formats require structured content. No script is executed when you create a file.

## Limitations

- macOS suppresses these Finder extension menu items in **iCloud Drive and some other cloud-managed folders**, including Desktop and Documents when synced to iCloud.
- The actions appear when right-clicking a folder’s empty area or any file in it; the new file is created in the folder you are viewing. Special Finder views such as Recents are not normal destination folders.
- The destination folder must be writable.
- Both processor architectures are included and target macOS 13. Setup, custom file types, visibility changes, and document creation were checked on Apple Silicon. Icon rendering is regression-tested for both light and dark appearances. An Intel Mac and macOS 13 were not available for runtime testing.

## Remove

Disable **New Documents** in Extension Settings, then move **New Documents.app** from Applications to Trash. Relaunch Finder if its menu entries remain visible.

## Build from source

Requires macOS, Xcode, an Apple Developer team configured in Xcode Settings → Accounts, and [XcodeGen](https://github.com/yonaskolb/XcodeGen). Install XcodeGen with `brew install xcodegen`.

```sh
git clone https://github.com/cobraprojects/new-documents.git
cd new-documents
./build.sh
```

`project.yml` defines the app and Finder extension targets. The script generates the Xcode project, archives a universal Apple Silicon/Intel app, and creates a development-signed ZIP in `dist/`. Development builds require the Mac to be registered on the selected team; they are for testing and are not a replacement for the public GitHub installers above.

For Mac App Store distribution:

```sh
./build.sh app-store
```

This exports the signed package to `dist/AppStore/New Documents.pkg`. Upload it using Xcode Organizer or Transporter. The team is configured in `project.yml` and `AppStoreExportOptions.plist`; publishing under another team also requires unique bundle and App Group identifiers. The checked-in icon asset catalog contains all required Mac icon sizes.

## App Store setup and privacy

Both targets use App Sandbox and share file-type preferences through an App Group. The Finder extension asks the user to select a destination folder or a parent folder before creating its first file there. Security-scoped bookmarks remember this permission across launches. File creation never uses a broad filesystem exception.

macOS requires users to enable the Finder extension once in System Settings. The app opens that settings page directly. No login item is installed.

The app has no networking, telemetry, advertising, or third-party runtime dependencies. [Privacy policy](https://cobraprojects.github.io/new-documents/privacy.html). Its source is `docs/privacy.html`, served through GitHub Pages from the `docs` directory.

## Tests

```sh
swift test --parallel
```

Behavior tests cover settings persistence, valid blank Office documents, duplicate and invalid extensions, safe concurrent file creation, and icon contrast after image serialization in light and dark appearances.

## How it works

`src/FinderExtension.swift` builds the New submenu from a single settings read each time the menu opens. `src/FileTypes.swift` shares settings validation, persistence, and exclusive file creation between the app and extension. `src/DocumentTemplates.swift` generates the blank Office documents. `src/MenuIcon.swift` resolves the semantic label color before Finder copies the icons. `src/FileTypesView.swift` provides the native file-type editor, while `src/main.swift` uses AppKit’s normal application lifecycle and Finder Sync’s native extension settings and status APIs. The installer places the app in `/Applications` without post-install scripts. The compiled asset catalog supplies the icon to Finder, Dock, Spotlight, and launchers; no runtime icon override is used.

Both the app and Finder extension are sandboxed. The extension uses user-selected folder access and persistent security-scoped bookmarks. macOS privacy restrictions and filesystem permissions still apply.
