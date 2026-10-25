# New Documents

Create empty text, code, and data files from a customizable **New** submenu in Finder’s right-click menu.

- **New → Text Document** creates `Untitled.txt`.
- **New → Markdown File** creates `Untitled.md`.
- Includes JSON, YAML, HTML, CSS, JavaScript, TypeScript, Python, shell, CSV, XML, and SQL.
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
2. **New Documents Setup** opens when installation finishes. If it does not, open **New Documents** from Applications.
3. Setup registers the Finder extension and requests enablement. If it reports that the extension is disabled, click **Extension Settings…** and enable **New Documents**. Depending on macOS, it appears under **New Documents** or **File Providers** in **System Settings → General → Login Items & Extensions**.
4. Return to setup and click **Check Status**.
5. If enabled but the menu is missing, wait for any file copies to finish, then click **Relaunch Finder**.
6. Right-click an empty area inside a local Finder folder, open **New**, and choose the document type.

Close setup when finished. No login item, Terminal commands, or development tools are needed to use the app.

### If macOS blocks the download

This release is locally signed and **has not been signed with Developer ID or notarized by Apple**. After attempting to open the installer, go to **System Settings → Privacy & Security → Open Anyway** for this package, then confirm.

See [Apple’s instructions for opening an app from an unidentified developer](https://support.apple.com/102445). Managed Macs may prevent this exception.

### Portable installation

Unzip `New-Documents-Universal.zip`, move **New Documents.app** into your Applications folder, and open it to register and enable the extension. Use the same **Open Anyway** process if macOS blocks the app. Keep only one installed copy to avoid conflicting extension registrations.

## Customize the New menu

Open **New → Manage File Types…**, or open **New Documents** from Applications.

- Use the **Show** checkbox to include or hide a file type.
- Click **Add File Type…**, enter a name and an extension (for example, `Configuration File` and `.toml`), then click **Add**.
- Select one or more rows and click **Remove** to delete entries from the list. This does not delete any documents.

Changes save automatically and appear the next time the New menu opens. Duplicate extensions are rejected. Compound extensions such as `config.json` are supported. Settings persist across upgrades in `~/Library/Application Support/New Documents/file-types.json`.

All types create **empty files**. Adding an extension such as `.docx`, `.xlsx`, or `.png` does not create a valid document or image; those formats require structured content or a template. No script is executed when you create a file.

## Limitations

- macOS suppresses these Finder extension menu items in **iCloud Drive and some other cloud-managed folders**, including Desktop and Documents when synced to iCloud.
- The actions appear when right-clicking the **empty area of a folder**, rather than an individual file. Special Finder views such as Recents are not normal destination folders.
- The destination folder must be writable.
- Both processor architectures are included and target macOS 13. Setup, custom file types, visibility changes, and document creation were checked on Apple Silicon. Icon rendering is regression-tested for both light and dark appearances. An Intel Mac and macOS 13 were not available for runtime testing.

## Remove

Disable **New Documents** in Extension Settings, then move **New Documents.app** from Applications to Trash. Relaunch Finder if its menu entries remain visible.

## Build from source

Requires macOS and Xcode or Apple’s Command Line Tools, including Swift, `lipo`, `codesign`, `pkgbuild`, and `productbuild`.

```sh
git clone https://github.com/cobraprojects/new-documents.git
cd new-documents
./build.sh
```

The script compiles Apple Silicon and Intel versions in parallel, combines them into universal binaries, signs the app locally, and creates:

```text
dist/New-Documents-Installer.pkg
dist/New-Documents-Universal.zip
```

No third-party runtime dependencies are required. The build uses a temporary local folder and removes it afterward.

## Tests

```sh
swift test --parallel
```

Behavior tests cover settings persistence, duplicate and invalid extensions, safe concurrent file creation, and icon contrast after image serialization in light and dark appearances.

## How it works

`src/FinderExtension.swift` builds the New submenu from a single settings read each time the menu opens. `src/FileTypes.swift` shares settings validation, persistence, and exclusive file creation between the app and extension. `src/MenuIcon.swift` resolves the semantic label color before Finder copies the icons. `src/FileTypesView.swift` provides the native file-type editor, while `src/main.swift` handles registration, enablement status, extension settings, and Finder relaunch. `src/installer/postinstall` opens setup in the logged-in user’s session after installation.

The Finder extension is sandboxed with a filesystem read/write exception so it can create files in local folders chosen in Finder. macOS privacy restrictions and filesystem permissions still apply. The app contains no networking or telemetry code.
