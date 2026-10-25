#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")" && pwd)"
source_dir="$repo_dir/src"
output_dir="$repo_dir/dist"
mkdir -p "$output_dir"
build_dir="$(mktemp -d /private/tmp/new-documents-build.XXXXXX)"
trap 'rm -rf "$build_dir"' EXIT
app="$build_dir/payload/Applications/New Documents.app"
extension="$app/Contents/PlugIns/NewDocumentsExtension.appex"
mkdir -p "$app/Contents/MacOS" "$extension/Contents/MacOS" "$build_dir/packages" "$build_dir/resources"
cp "$source_dir/NewDocuments-Info.plist" "$app/Contents/Info.plist"
cp "$source_dir/NewDocumentsExtension-Info.plist" "$extension/Contents/Info.plist"
for plist in "$app/Contents/Info.plist" "$extension/Contents/Info.plist"; do
    /usr/libexec/PlistBuddy -c 'Set :CFBundleShortVersionString 1.2' "$plist"
    /usr/libexec/PlistBuddy -c 'Set :CFBundleVersion 3' "$plist"
done
compile_arch() {
    arch="$1"
    xcrun swiftc -O -target "$arch-apple-macos13.0" "$source_dir/main.swift" "$source_dir/FileTypesView.swift" "$source_dir/FileTypes.swift" \
        -framework Cocoa -framework FinderSync -o "$build_dir/host-$arch"
    xcrun swiftc -O -target "$arch-apple-macos13.0" "$source_dir/FinderExtension.swift" "$source_dir/FileTypes.swift" "$source_dir/MenuIcon.swift" \
        -parse-as-library -module-name NewDocumentsExtension -framework Cocoa -framework FinderSync \
        -Xlinker -e -Xlinker _NSExtensionMain -o "$build_dir/extension-$arch"
}
compile_arch arm64 &
arm_pid=$!
compile_arch x86_64 &
intel_pid=$!
wait "$arm_pid"
wait "$intel_pid"
xcrun lipo -create "$build_dir/host-arm64" "$build_dir/host-x86_64" -output "$app/Contents/MacOS/NewDocuments"
xcrun lipo -create "$build_dir/extension-arm64" "$build_dir/extension-x86_64" -output "$extension/Contents/MacOS/NewDocumentsExtension"
codesign --force --sign - --timestamp=none --entitlements "$source_dir/extension.entitlements" "$extension"
codesign --force --sign - --timestamp=none "$app"
codesign --verify --deep --strict "$app"
xcrun lipo "$app/Contents/MacOS/NewDocuments" -verify_arch arm64
xcrun lipo "$extension/Contents/MacOS/NewDocumentsExtension" -verify_arch arm64
xcrun lipo "$app/Contents/MacOS/NewDocuments" -verify_arch x86_64
xcrun lipo "$extension/Contents/MacOS/NewDocumentsExtension" -verify_arch x86_64
pkgbuild --root "$build_dir/payload" --identifier local.codex.NewDocuments.installer \
    --version 1.2 --scripts "$source_dir/installer" --install-location / \
    "$build_dir/packages/NewDocuments-component.pkg"
cat > "$build_dir/distribution.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
  <title>New Documents</title>
  <welcome file="welcome.html"/>
  <conclusion file="conclusion.html"/>
  <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
  <allowed-os-versions><os-version min="13.0"/></allowed-os-versions>
  <domains enable_localSystem="true" enable_currentUserHome="false" enable_anywhere="false"/>
  <choices-outline><line choice="default"/></choices-outline>
  <choice id="default" visible="false"><pkg-ref id="local.codex.NewDocuments.installer"/></choice>
  <pkg-ref id="local.codex.NewDocuments.installer" version="1.2" onConclusion="none">NewDocuments-component.pkg</pkg-ref>
</installer-gui-script>
XML
cat > "$build_dir/resources/welcome.html" <<'HTML'
<html><body style="font:14px -apple-system"><h1>New Documents</h1><p>Add a customizable <b>New</b> submenu to Finder’s right-click menu. Enable text, Markdown, code, and data file types, or add your own extensions.</p><p>Works on Apple Silicon and Intel Macs running macOS Ventura 13 or later. Installs New Documents.app in Applications.</p><p>Setup opens after installation to register the extension and show whether it is enabled.</p><p>Existing files are preserved. New files are named Untitled.txt or Untitled.md, with a number added when necessary.</p><p>macOS hides these extension menus in iCloud Drive and some other cloud-managed folders.</p></body></html>
HTML
cat > "$build_dir/resources/conclusion.html" <<'HTML'
<html><body style="font:14px -apple-system"><h1>Finish setup</h1><ol><li>Open <b>New Documents</b> from Applications if its setup window hasn’t opened.</li><li>If the status says the extension is disabled, click <b>Extension Settings</b> and turn on New Documents. It may be listed under File Providers.</li><li>Click <b>Check Status</b>. If the menu is missing, use <b>Relaunch Finder</b> after file copies finish.</li><li>Right-click an empty area in a local Finder folder and open <b>New</b>. Use <b>Manage File Types</b> to customize the list.</li></ol><p>You can close setup after enabling the extension. No login item is needed.</p></body></html>
HTML
productbuild --distribution "$build_dir/distribution.xml" --resources "$build_dir/resources" \
    --package-path "$build_dir/packages" "$build_dir/New-Documents-Installer.pkg"
cp "$build_dir/New-Documents-Installer.pkg" "$output_dir/New-Documents-Installer.pkg"
# A portable copy is useful when an administrator cannot install into /Applications.
ditto -c -k --sequesterRsrc --keepParent "$app" "$output_dir/New-Documents-Universal.zip"
printf 'Created universal installer and portable app in %s\n' "$output_dir"
