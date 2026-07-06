// ZA Player Pro Web — iOS AppDelegate (v1.4.15)
//
// Drop this into `ios/App/App/AppDelegate.swift` AFTER running
// `npx cap add ios` on your Mac — it replaces the stock AppDelegate
// that Capacitor generates. Extra behaviour vs stock:
//
//   • Landscape + portrait allowed (streams look better landscape).
//   • Immersive fullscreen (hides status bar on iPhone).
//   • Keeps screen on during playback (prevents auto-lock).
//
// Everything else — WKWebView plumbing, deep links, universal links,
// notifications — is inherited from `CAPBridgeViewController` upstream.

import UIKit
import Capacitor

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
                     -> Bool {
        // v1.4.15 — Keep the display awake during long streaming
        // sessions. IPTV users watching a 3-hour movie shouldn't have
        // to touch the screen every 15 minutes to prevent auto-lock.
        UIApplication.shared.isIdleTimerDisabled = true
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration",
                                    sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

    // v1.4.15 — Allow both orientations globally. The React player
    // handles its own fullscreen layout via CSS media queries.
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?)
                     -> UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    // Universal links — reserved for future deep-linking use.
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return ApplicationDelegateProxy.shared.application(
            application, continue: userActivity, restorationHandler: restorationHandler)
    }
}
