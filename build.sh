#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")" && pwd)"
cd "$repo_dir"
mode="${1:-development}"
case "$mode" in
    development|app-store) ;;
    *) printf 'Usage: %s [development|app-store]\n' "$0" >&2; exit 1 ;;
esac
command -v xcodegen >/dev/null || { echo 'Install XcodeGen: brew install xcodegen' >&2; exit 1; }
mkdir -p dist
xcodegen generate
archive="$repo_dir/dist/New Documents.xcarchive"
xcodebuild -project NewDocuments.xcodeproj -scheme NewDocuments -configuration Release \
    -destination 'generic/platform=macOS' -archivePath "$archive" \
    -allowProvisioningUpdates archive
if [[ "$mode" == app-store ]]; then
    xcodebuild -exportArchive -archivePath "$archive" \
        -exportOptionsPlist AppStoreExportOptions.plist \
        -exportPath "$repo_dir/dist/AppStore" -allowProvisioningUpdates
else
    app="$archive/Products/Applications/New Documents.app"
    codesign --verify --deep --strict "$app"
    ditto -c -k --sequesterRsrc --keepParent "$app" dist/New-Documents-Universal.zip
fi
printf 'Created %s build in %s/dist\n' "$mode" "$repo_dir"
