import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "easyrec/screen_recorder",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "startRecording":
          result(
            FlutterError(
              code: "WINDSWIFT_NOT_INTEGRATED",
              message: "WindSwift SDK is not integrated yet. Add the WindSwift iOS SDK and implement startRecording in AppDelegate.swift.",
              details: nil
            )
          )
        case "stopRecording":
          result(
            FlutterError(
              code: "WINDSWIFT_NOT_INTEGRATED",
              message: "WindSwift SDK is not integrated yet. Implement stopRecording to return the saved file path.",
              details: nil
            )
          )
        case "pauseRecording":
          result(
            FlutterError(
              code: "WINDSWIFT_NOT_INTEGRATED",
              message: "WindSwift SDK is not integrated yet. Implement pauseRecording.",
              details: nil
            )
          )
        case "resumeRecording":
          result(
            FlutterError(
              code: "WINDSWIFT_NOT_INTEGRATED",
              message: "WindSwift SDK is not integrated yet. Implement resumeRecording.",
              details: nil
            )
          )
        case "getStatus":
          result("idle")
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
