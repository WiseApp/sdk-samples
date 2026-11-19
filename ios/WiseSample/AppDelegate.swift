import UIKit
import WiseLiveSDK

// LensAppDelegate forwards app lifecycle events to the SDK (Zoom needs them).
// LensSDK presents the meeting from this window's root view controller.
// `@objc` is required: the UIApplicationDelegate conformance is inherited from the SDK framework,
// so Swift doesn't expose these to UIKit on its own (without it the app shows a black screen).
@main
class AppDelegate: LensAppDelegate {
    @objc var window: UIWindow?

    @objc func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: ViewController())
        window?.makeKeyAndVisible()
        return true
    }
}
