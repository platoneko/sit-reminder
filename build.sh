#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"

# -s is only applied when creating a new applet bundle, not when overwriting.
rm -rf "久坐提醒.app"
osacompile -s -o "久坐提醒.app" sit-reminder.applescript

plist="久坐提醒.app/Contents/Info.plist"
set_or_add() {
  local key="$1" type="$2" value="$3"
  /usr/libexec/PlistBuddy -c "Set :${key} ${value}" "$plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :${key} ${type} ${value}" "$plist"
}
set_or_add CFBundleIdentifier string local.sit-reminder
set_or_add CFBundleName string 久坐提醒
set_or_add CFBundleShortVersionString string 1.5
set_or_add CFBundleVersion string 1.5
set_or_add NSHighResolutionCapable bool true
set_or_add LSMinimumSystemVersion string 14.0

if [[ -f assets/AppIcon.icns ]]; then
  cp assets/AppIcon.icns "久坐提醒.app/Contents/Resources/applet.icns"
  cp assets/AppIcon.icns "久坐提醒.app/Contents/Resources/AppIcon.icns"
  set_or_add CFBundleIconFile string AppIcon
  set_or_add CFBundleIconName string AppIcon
fi

# Re-seal after plist/icon edits, otherwise Finder keeps the signed-in old icon.
codesign --force --deep --sign - "久坐提醒.app"

dest="$HOME/Applications/久坐提醒.app"
mkdir -p "$HOME/Applications"
rm -rf "$dest"
ditto "久坐提醒.app" "$dest"
codesign --force --deep --sign - "$dest"

echo "built: $(pwd)/久坐提醒.app"
echo "installed: $dest"
