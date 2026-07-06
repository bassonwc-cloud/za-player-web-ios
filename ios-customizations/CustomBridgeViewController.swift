// ZA Player Pro Web — iOS Custom Bridge View Controller (v1.4.15)
//
// Drop into `ios/App/App/CustomBridgeViewController.swift` (create the
// file). Then in `Main.storyboard`, change the root view controller's
// class from `CAPBridgeViewController` to `CustomBridgeViewController`.
//
// Adds two things the stock Capacitor bridge doesn't do:
//
//   1. Clears the WKWebView data store on every launch. iOS caches
//      `index.html` aggressively when the server doesn't send explicit
//      `Cache-Control` — same problem we hit on Android. localStorage
//      + IndexedDB are preserved (activation key survives).
//
//   2. Prefers fullscreen HTML5 video with inline playback OFF. This
//      lets the native iOS video player take over when the user taps
//      a stream — which is what iPhone/iPad users expect (rotate,
//      AirPlay, PiP all wired up automatically).

import UIKit
import Capacitor
import WebKit

class CustomBridgeViewController: CAPBridgeViewController {

    override open func capacitorDidLoad() {
        // v1.4.15 — Nuke HTTP disk cache on every launch. Mirrors the
        // Windows + Android Web Player behaviour. Keeps localStorage +
        // IndexedDB (activation key, playlist cache) intact.
        let types: Set<String> = [
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeMemoryCache,
            WKWebsiteDataTypeOfflineWebApplicationCache,
        ]
        let modifiedSince = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: types,
                                                modifiedSince: modifiedSince) {
            // no-op — completion just to be a good citizen
        }
    }

    override open func instanceDescriptor() -> InstanceDescriptor {
        let descriptor = super.instanceDescriptor()
        // Force fullscreen native video — iOS Safari plays inline in
        // <video> by default, which strips users of the fullscreen
        // controls, AirPlay button, PiP, etc. Turn that OFF so tapping
        // a stream opens the native player over the WebView.
        descriptor.iosPreferences?["allowsInlineMediaPlayback"] = false
        descriptor.iosPreferences?["allowInlineMediaPlayback"] = false
        return descriptor
    }
}
