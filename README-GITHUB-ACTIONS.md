# Build an unsigned IPA with GitHub Actions (no Mac needed)

This scaffold ships with a workflow at
`.github/workflows/build-ios.yml` that runs on GitHub's **free
macOS runner** and produces `ZA-Player-Pro-Web-unsigned.ipa` as a
downloadable artifact. You never touch a Mac.

---

## Step 1 — Create a GitHub account (if you don't already have one)

Go to https://github.com/signup — free, ~1 minute.

---

## Step 2 — Create a new repository

1. Top-right → **+** → **New repository**
2. Repository name: `za-player-web-ios` (or anything you like)
3. **Visibility:** `Public` recommended → unlimited free macOS build minutes.
   (Private also works, but you only get 2000 macOS minutes/month
   on the free plan.)
4. Do **not** add a README, .gitignore, or license — we're pushing
   our own files.
5. Click **Create repository**.

---

## Step 3 — Push this folder to your repo

You can do this two ways. Pick whichever is easier for you.

### Option A — GitHub website (no command line, easiest)

1. On your empty repo's page, click **uploading an existing file**.
2. Drag the **contents** of the extracted `ios-webplayer/` folder
   (not the folder itself — its contents) into the upload area:
   - `package.json`
   - `capacitor.config.json`
   - `yarn.lock`
   - `build-unsigned-ipa.sh`
   - `README.md`
   - `README-GITHUB-ACTIONS.md`
   - `ios-customizations/` (folder)
   - `.github/` (folder — **make sure this hidden folder is uploaded**;
     on macOS press `Cmd+Shift+.` in Finder to reveal hidden folders,
     on Windows enable "Show hidden files" in File Explorer)
3. Scroll down → **Commit changes**.

### Option B — Git command line

```bash
cd ios-webplayer
git init
git add .
git commit -m "Initial commit: ZA Player Pro Web iOS scaffold"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/za-player-web-ios.git
git push -u origin main
```

---

## Step 4 — Wait for the build (or trigger it manually)

Once files are pushed, GitHub Actions starts the build automatically.

1. Go to the **Actions** tab of your repo.
2. You'll see a run titled **"Build Unsigned iOS IPA"** with a
   yellow spinner (queued/running).
3. Click into it. First run takes ~10–15 minutes (installs
   CocoaPods, downloads Xcode caches, runs `xcodebuild archive`).
4. When the run shows a green tick, scroll to the **Artifacts**
   section at the bottom of the run summary page.
5. Click **`ZA-Player-Pro-Web-unsigned-ipa`** to download a `.zip`
   containing your `.ipa` file.

If the build fails, click into the failing step to see the log.
Common causes: pod install network hiccup (re-run), Xcode
version mismatch (edit `.github/workflows/build-ios.yml`).

### Trigger a build manually any time

Actions tab → **Build Unsigned iOS IPA** (left sidebar) →
**Run workflow** button (right) → pick the branch → **Run
workflow**. New IPA in 10–15 min.

---

## Step 5 — Sideload the unsigned IPA onto your device

The `.ipa` GitHub Actions produced has NO code signature. Use one
of these to install it on your iPhone/iPad:

| Tool | OS | Cost | Notes |
|---|---|---|---|
| **[Sideloadly](https://sideloadly.io)** | Win / Mac | Free | Easiest. Free Apple ID → 7-day install. |
| **[AltStore](https://altstore.io)** | Win / Mac | Free | Free Apple ID → 7-day. Auto-refresh on Wi-Fi. |
| **[TrollStore](https://github.com/opa334/TrollStore)** | any | Free | Permanent install, but only for iOS 14.0 – 16.6.1 (some 17.x support). |
| **[ios-app-signer](https://dantheman827.github.io/ios-app-signer/)** | Mac | Free | If you already have a `.mobileprovision` file. |

### Sideloadly quickstart (Windows PC → iPhone)

1. Install iTunes from Apple's site (needed for USB device drivers).
2. Download & install Sideloadly.
3. Plug your iPhone in via USB, trust the computer.
4. Open Sideloadly → drag the `.ipa` into the window.
5. Enter your Apple ID email + app-specific password
   ([create one here](https://appleid.apple.com/account/manage) →
   "Sign-in and Security" → "App-specific passwords").
6. Click **Start**. In 60 seconds the app is on your device.
7. On the iPhone: **Settings → General → VPN & Device Management**
   → tap your Apple ID → **Trust**.
8. Launch the app.

**The app expires after 7 days on a free Apple ID.** Reconnect
to Sideloadly to re-sign as often as you like. A paid Apple
Developer account bumps this to 1 year.

---

## Step 6 — Cutting a release (optional)

If you tag a commit (e.g. `git tag v1.4.16 && git push --tags`),
the workflow also attaches the IPA to a **GitHub Release** so you
can share a public download link with testers.

---

## Troubleshooting

**Build fails at "pod install"**
- Usually a transient CocoaPods CDN issue. Re-run the workflow.

**Build fails at "xcodebuild archive"**
- Open the failing step, expand the log, look for the first `error:`
  line. Copy that error into a GitHub Issue or paste it back to me.

**"Xcode 15.4 not found"**
- GitHub occasionally rotates Xcode versions on their runners. Edit
  `.github/workflows/build-ios.yml` → change `Xcode_15.4.app` to
  whatever version is listed at
  https://github.com/actions/runner-images/blob/main/images/macos/macos-14-Readme.md

**IPA installs but crashes on launch**
- 99% of the time this is the sideloading provisioning profile,
  not the IPA itself. Re-run Sideloadly.
