# ZA Player Pro Web — iOS Build Guide (v1.4.17)

This folder contains the **Capacitor iOS project scaffolding** for the
iOS variant of the Web Player. Everything you need to build an
`.ipa` that installs on iPhone/iPad and can be submitted to the
App Store is here.

---

## 🚀 No Mac? Build the IPA on GitHub Actions (free, ~15 min)

If you don't own a Mac, follow **`README-GITHUB-ACTIONS.md`** in
this folder. It walks you through pushing this scaffold to a free
GitHub repository — GitHub's free macOS runner compiles the app
and gives you a downloadable unsigned `.ipa` you can sideload with
Sideloadly / AltStore.

---

## 🖥️ Got a Mac? One-command unsigned IPA

If you just want an unsigned IPA to sideload (Sideloadly / AltStore /
TrollStore / ios-app-signer), on any Mac with Xcode + CocoaPods + Node:

```bash
tar -xzf ZA-Player-Pro-Web-iOS-Scaffold-1.4.16.tar.gz
cd ios-webplayer
./build-unsigned-ipa.sh
# ->  build/ZA-Player-Pro-Web-unsigned.ipa
```

That IPA has NO code-signature and NO provisioning profile. It will
NOT install on stock iOS out of the box — re-sign it with one of:

- **Sideloadly** — https://sideloadly.io  (Win/Mac, free)
- **AltStore**   — https://altstore.io    (free Apple ID, 7-day resign)
- **TrollStore** — permanent, iOS 14–16.6.1 only
- **ios-app-signer** — https://dantheman827.github.io/ios-app-signer/

If you want a **signed** IPA for TestFlight / App Store, keep reading —
you'll do it in Xcode with your Apple Developer team selected.

---

## Prerequisites (on your Mac)

1. **macOS 13 Ventura or newer** (Xcode 15+ requires this).
2. **Xcode 15+** — free from the Mac App Store.
3. **CocoaPods** — install once: `sudo gem install cocoapods`.
4. **Node.js 18+ and yarn/npm** — for the Capacitor CLI.
5. **Apple Developer account** — $99/yr for App Store submission or
   installing on real devices.

---

## Step 1 — Copy this folder to your Mac

Copy the entire `/app/ios-webplayer/` directory from your server to
your Mac. Anywhere works — `~/Projects/za-player-web-ios/` is fine.

---

## Step 2 — Install dependencies

```bash
cd ~/Projects/za-player-web-ios
yarn install         # or `npm install`
```

## Step 3 — Generate the iOS Xcode project

```bash
mkdir -p www
touch www/index.html         # Capacitor needs a webDir to exist,
                             # but our config points at server.url —
                             # www/ is just fallback padding.
npx cap add ios
```

This creates the `ios/App/` folder with a full Xcode project.

## Step 4 — Apply our customisations

**a)** Overwrite the stock AppDelegate with ours:

```bash
cp ios-customizations/AppDelegate.swift ios/App/App/AppDelegate.swift
```

**b)** Add the custom bridge view controller:

```bash
cp ios-customizations/CustomBridgeViewController.swift \
   ios/App/App/CustomBridgeViewController.swift
```

**c)** Merge `Info.plist.additions.xml` into `ios/App/App/Info.plist`.
Open both files in a text editor and paste each additional `<key>...`
pair inside the top-level `<dict>` of Info.plist. Do NOT overwrite
the whole file — Capacitor generates required keys already.

**d)** In Xcode → open `ios/App/App/Base.lproj/Main.storyboard`. Click
the root view controller in the scene tree → Identity Inspector (right
pane) → change **Class** from `CAPBridgeViewController` to
`CustomBridgeViewController`. Save.

## Step 5 — CocoaPods

```bash
cd ios/App
pod install
```

## Step 6 — App icons

Drop your app icons into
`ios/App/App/Assets.xcassets/AppIcon.appiconset/`. Required sizes:
20/29/40/60/76/83.5/1024 px @1x/@2x/@3x — Xcode's Assets editor lists
them all. Easiest: generate the whole set with a tool like
[appicon.co](https://appicon.co) from a single 1024×1024 PNG.

## Step 7 — Open in Xcode

```bash
open ios/App/App.xcworkspace
```

**Important:** open `App.xcworkspace`, NOT `App.xcodeproj`. CocoaPods
requires the workspace.

In Xcode:

1. Select the **App** target in the left pane.
2. **Signing & Capabilities** tab → check "Automatically manage signing"
   → select your Apple Developer team.
3. Under **Info**, verify the app name is "ZA Player Pro Web" and the
   bundle id is `tv.zaplayer.pro.web`.
4. **General → Deployment Info** → set minimum iOS to 14.0 (matches
   Capacitor 6's floor).

## Step 8 — Test on a real device

1. Plug in an iPhone/iPad via USB.
2. Trust the computer on the device if prompted.
3. In Xcode, pick your device from the top device selector.
4. Cmd+R to build & run.
5. First launch will show the activation screen (fresh install — no
   cached activation key). Enter your activation key and go.

## Step 9 — Archive for App Store submission

1. In Xcode: **Product → Archive**.
2. When the Organizer opens: **Distribute App → App Store Connect →
   Upload**.
3. Wait for the upload to complete (~5-10 min).
4. Go to https://appstoreconnect.apple.com → your app → **TestFlight**
   for beta, or **App Store** for public release.

### App Store review notes

Fill in the app privacy questionnaire in App Store Connect. Because
our Info.plist declares `NSAllowsArbitraryLoads=true`, Apple will
require a justification. Copy-paste this in the review notes field:

> ZA Player Pro Web is a client for user-owned IPTV subscriptions.
> The app connects to third-party IPTV providers chosen by the user
> using URLs the user configures themselves. IPTV providers routinely
> ship media streams over plain HTTP (`http://...`), so the app must
> allow arbitrary loads to display those streams. The app collects no
> personal data, contains no advertising, and does not use any of the
> user's IPTV credentials for any purpose other than fetching their
> chosen content.

Also mention the app is a **thin WebView wrapper** that loads the same
`https://zaplayerpro.club/admin/webplayer` served over HTTPS — this
tends to speed up Apple review because they can see the entire client
behaviour from a browser too.

---

## Version bumping later

- `capacitor.config.json` — nothing here needs bumping; it points at
  the live URL, and every JS/CSS deploy on `zaplayerpro.club` is picked
  up automatically.
- `ios/App/App/Info.plist` → `CFBundleShortVersionString` (marketing
  version) + `CFBundleVersion` (build number). App Store wants unique
  `CFBundleVersion` per upload.

---

## Troubleshooting

- **"Failed to load webpage" on launch** — check the Mac is online.
  The app fetches everything from `zaplayerpro.club` on first launch.
- **Activation lost after update** — WKWebView's data store can be
  wiped by iOS on major upgrades. Users just re-activate.
- **Streams don't play** — same codec caveats as the browser Web
  Player: iOS Safari supports H.264/AAC and HLS `.m3u8` natively.
  MKV / HEVC HDR / AC3 audio fail. There's no mpv/ExoPlayer equivalent
  on iOS unless we bundle a native player like VLCKit — that's a
  bigger integration (~40 MB IPA, ~1 week of Swift work).

---

## What lives where

| File / Folder | Purpose |
|---|---|
| `package.json` | Capacitor CLI + iOS deps |
| `capacitor.config.json` | Wraps `zaplayerpro.club/admin/webplayer` |
| `ios-customizations/AppDelegate.swift` | Keep-awake + orientation |
| `ios-customizations/CustomBridgeViewController.swift` | Cache-wipe + fullscreen video |
| `ios-customizations/Info.plist.additions.xml` | Merge these keys into Info.plist |
| `README.md` | This guide |

---

_ZA Player Pro Web iOS v1.4.17 — parity with Android Web Player v1.4.15._
