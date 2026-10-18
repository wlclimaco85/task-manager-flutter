import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    NSLog("[BOOT-NATIVE] didFinishLaunching start")
    GeneratedPluginRegistrant.register(with: self)
    NSLog("[BOOT-NATIVE] plugins registered")
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    NSLog("[BOOT-NATIVE] didFinishLaunching end")
    return result
  }
}
