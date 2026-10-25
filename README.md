# New Documents

Create empty text and Markdown files from Finder’s right-click menu.

- **New Text Document** creates `Untitled.txt`.
- **New Markdown File** creates `Untitled.md`.
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
6. Right-click an empty area inside a local Finder folder and choose the document type.

Close setup when finished. No login item, Terminal commands, or development tools are needed to use the app.

### If macOS blocks the download

This release is locally signed and **has not been signed with Developer ID or notarized by Apple**. After attempting to open the installer, go to **System Settings → Privacy & Security → Open Anyway** for this package, then confirm.

See [Apple’s instructions for opening an app from an unidentified developer](https://support.apple.com/102445). Managed Macs may prevent this exception.

### Portable installation

Unzip `New-Documents-Universal.zip`, move **New Documents.app** into your Applications folder, and open it to register and enable the extension. Use the same **Open Anyway** process if macOS blocks the app. Keep only one installed copy to avoid conflicting extension registrations.

## Limitations

- macOS suppresses these Finder extension menu items in **iCloud Drive and some other cloud-managed folders**, including Desktop and Documents when synced to iCloud.
- The actions appear when right-clicking the **empty area of a folder**, rather than an individual file. Special Finder views such as Recents are not normal destination folders.
- The destination folder must be writable.
- Both processor architectures are included and target macOS 13. Setup and document creation were checked on Apple Silicon. An Intel Mac and macOS 13 were not available for runtime testing.

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

## How it works

`src/FinderExtension.swift` implements the two Finder menu items. File creation uses exclusive writes so an existing document is never overwritten. `src/main.swift` provides registration, enablement status, extension settings, and a Finder relaunch control. `src/installer/postinstall` opens setup in the logged-in user’s session after installation.

The Finder extension is sandboxed with a filesystem read/write exception so it can create files in local folders chosen in Finder. macOS privacy restrictions and filesystem permissions still apply. The app contains no networking or telemetry code.
