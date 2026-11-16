import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// NIX-430: APNs bridge state. Events that fire before the Flutter engine
  /// finishes initializing (cold-launch taps, early token registration) are
  /// parked and replayed once the method channel exists.
  private var pushChannel: FlutterMethodChannel?
  private var pendingTokenHex: String?
  private var pendingTapUserInfo: [AnyHashable: Any]?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // The delegate must be installed before any notification arrives so both
    // cold-launch taps and foreground presentation route through this class.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PushBridge") {
      pushChannel = FlutterMethodChannel(name: "app/push", binaryMessenger: registrar.messenger())
      pushChannel?.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(FlutterError(code: "detached", message: "app delegate released", details: nil))
          return
        }
        switch call.method {
        case "requestAuthorization":
          self.requestPushAuthorization { granted in result(granted) }
        case "requestToken":
          // didRegisterForRemoteNotificationsWithDeviceToken answers via onToken.
          UIApplication.shared.registerForRemoteNotifications()
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
      // Replay events parked during engine initialization.
      if let token = pendingTokenHex {
        pendingTokenHex = nil
        emitToken(hex: token)
      }
      if let tap = pendingTapUserInfo {
        pendingTapUserInfo = nil
        emitTap(userInfo: tap)
      }
    }
  }

  private func requestPushAuthorization(completion: @escaping (Bool) -> Void) {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
      DispatchQueue.main.async {
        if granted {
          UIApplication.shared.registerForRemoteNotifications()
        }
        completion(granted)
      }
    }
  }

  private func emitToken(hex: String) {
    pushChannel?.invokeMethod("onToken", arguments: hex)
  }

  private func emitTap(userInfo: [AnyHashable: Any]) {
    // Custom keys ride the userInfo; alertId is the deep-link anchor.
    var payload: [String: Any] = [:]
    if let alertId = userInfo["alertId"] {
      payload["alertId"] = alertId
    }
    pushChannel?.invokeMethod("onTap", arguments: payload)
  }

  // MARK: - APNs registration outcome

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
    if pushChannel != nil {
      emitToken(hex: hex)
    } else {
      pendingTokenHex = hex
    }
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("[push] APNs registration failed: %@", error.localizedDescription)
  }

  // MARK: - UNUserNotificationCenterDelegate

  /// Foreground: present the system banner instead of dropping the push.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }

  /// Tapped notification (foreground, background or cold launch).
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    if pushChannel != nil {
      emitTap(userInfo: userInfo)
    } else {
      pendingTapUserInfo = userInfo
    }
    completionHandler()
  }
}
