import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private static let appGroup = "group.com.dodopok.lume"
  private static let pendingURLKey = "pending_shared_url"
  private static let pendingAtKey = "pending_shared_url_at"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.dodopok.lume/share",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "consumePendingUrl" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let defaults = UserDefaults(suiteName: Self.appGroup)
        let value = defaults?.string(forKey: Self.pendingURLKey)
        defaults?.removeObject(forKey: Self.pendingURLKey)
        defaults?.removeObject(forKey: Self.pendingAtKey)
        result(value)
      }
    }
    return didFinish
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme?.lowercased() == "lume" {
      return true
    }
    return super.application(app, open: url, options: options)
  }
}
