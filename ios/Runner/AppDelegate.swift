import Flutter
import UIKit
import UserNotifications // 通知のためにこの行を追加

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // for notification
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      // 通知の許可をリクエストする
        UNUserNotificationCenter.current().requestAuthorization(
          options: [.alert, .badge, .sound]) { (granted, error) in
          if granted {
            print("通知が許可されました")
          } else {
            print("通知が拒否されました")
          }
        }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}