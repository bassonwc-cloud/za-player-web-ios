#!/usr/bin/env bash
# ------------------------------------------------------------------
# ZA Player Pro Web — Unsigned IPA builder (macOS only)
#
# Produces:  build/ZA-Player-Pro-Web-unsigned.ipa
#
# Requirements (all free):
#   - macOS 13+  (this script MUST run on a Mac)
#   - Xcode 15+  (from the Mac App Store)
#   - xcode-select --install
#   - Node 18+, npm or yarn
#   - CocoaPods: sudo gem install cocoapods
#
# The IPA this produces is UNSIGNED — it will NOT install on a
# stock iOS device out of the box. Re-sign with one of:
#   * Sideloadly       https://sideloadly.io  (Win/Mac, free)
#   * AltStore         https://altstore.io    (free Apple ID, 7-day)
#   * TrollStore       (permanent, iOS 14–16.6.1)
#   * ios-app-signer   https://dantheman827.github.io/ios-app-signer/
# ------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> [1/8] Sanity check: macOS + Xcode + CocoaPods"
if [[ "$(uname)" != "Darwin" ]]; then
  echo "ERROR: This script must run on macOS. You are on $(uname)." >&2
  exit 1
fi
command -v xcodebuild >/dev/null || { echo "ERROR: Xcode not installed." >&2; exit 1; }
command -v pod        >/dev/null || { echo "ERROR: run: sudo gem install cocoapods" >&2; exit 1; }
command -v node       >/dev/null || { echo "ERROR: install Node.js 18+" >&2; exit 1; }
if command -v yarn >/dev/null 2>&1; then PKG="yarn"; PKGX="yarn"; else PKG="npm"; PKGX="npx"; fi

echo "==> [2/8] Installing Capacitor CLI deps"
$PKG install --silent

echo "==> [3/8] Ensuring www/ is populated (bundled React build v1.4.15)"
if [[ ! -f www/index.html ]]; then
  echo "    WARNING: www/index.html missing — creating a placeholder."
  echo "    This scaffold ships with a full production www/ — if you"
  echo "    see this warning it means the folder wasn't uploaded."
  mkdir -p www
  echo "<!doctype html><title>ZA Player Pro Web</title>" > www/index.html
else
  SIZE=$(du -sh www | cut -f1)
  echo "    Bundled web player found: www/  ($SIZE)"
fi

echo "==> [4/8] Generating ios/App Xcode project (idempotent)"
if [[ ! -d ios/App ]]; then
  $PKGX cap add ios
else
  echo "    ios/App exists — reusing"
fi

echo "==> [5/8] Applying ZA Player customisations"
cp -f ios-customizations/AppDelegate.swift              ios/App/App/AppDelegate.swift
cp -f ios-customizations/CustomBridgeViewController.swift ios/App/App/CustomBridgeViewController.swift

INFO_PLIST="ios/App/App/Info.plist"
ADDITIONS="ios-customizations/Info.plist.additions.xml"
if [[ -f "$ADDITIONS" ]] && ! grep -q "NSAllowsArbitraryLoads" "$INFO_PLIST" 2>/dev/null; then
  echo "    Merging Info.plist additions"
  python3 - "$ADDITIONS" "$INFO_PLIST" <<'PYEOF'
import sys, plistlib
add_path, dst_path = sys.argv[1], sys.argv[2]
raw = open(add_path,'rb').read().strip()
if not raw.startswith(b'<?xml'):
    raw = (b'<?xml version="1.0" encoding="UTF-8"?>'
           b'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
           b'<plist version="1.0"><dict>' + raw + b'</dict></plist>')
try:
    add = plistlib.loads(raw)
except Exception as e:
    print("    WARN: additions.xml not a valid plist fragment: " + str(e), file=sys.stderr)
    sys.exit(0)
with open(dst_path,'rb') as f: dst = plistlib.load(f)
dst.update(add)
with open(dst_path,'wb') as f: plistlib.dump(dst, f)
print("    Merged", len(add), "keys into Info.plist")
PYEOF
fi

STORY="ios/App/App/Base.lproj/Main.storyboard"
if [[ -f "$STORY" ]] && ! grep -q 'CustomBridgeViewController' "$STORY"; then
  echo "    Rewriting root VC -> CustomBridgeViewController"
  /usr/bin/sed -i '' 's/customClass="CAPBridgeViewController"/customClass="CustomBridgeViewController"/g' "$STORY"
fi

echo "==> [6/8] pod install"
( cd ios/App && pod install --silent )

echo "==> [7/8] xcodebuild archive (CODE SIGNING DISABLED)"
mkdir -p build
ARCHIVE="$SCRIPT_DIR/build/App.xcarchive"
rm -rf "$ARCHIVE"
xcodebuild \
  -workspace ios/App/App.xcworkspace \
  -scheme App \
  -configuration Release \
  -sdk iphoneos \
  -archivePath "$ARCHIVE" \
  -destination 'generic/platform=iOS' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  archive

if [[ ! -d "$ARCHIVE/Products/Applications" ]]; then
  echo "ERROR: archive missing Products/Applications." >&2
  exit 1
fi

echo "==> [8/8] Packaging unsigned .ipa"
STAGE="$SCRIPT_DIR/build/stage"
IPA="$SCRIPT_DIR/build/ZA-Player-Pro-Web-unsigned.ipa"
rm -rf "$STAGE" "$IPA"
mkdir -p "$STAGE/Payload"
cp -R "$ARCHIVE/Products/Applications/"*.app "$STAGE/Payload/"
( cd "$STAGE" && zip -qr "$IPA" Payload )
rm -rf "$STAGE"

SIZE=$(du -h "$IPA" | cut -f1)
echo ""
echo "============================================================"
echo "  DONE - Unsigned IPA:  $IPA  ($SIZE)"
echo ""
echo "  This file has NO code-signature. To install on a real"
echo "  device, re-sign with Sideloadly / AltStore / TrollStore /"
echo "  ios-app-signer.  See script header for links."
echo "============================================================"
