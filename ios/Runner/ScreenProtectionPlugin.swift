import Flutter
import UIKit

final class ScreenProtectionPlugin: NSObject, FlutterPlugin {
  private static let captureChangedMethod = "captureChanged"
  private static let channelName = "salli/screen_protection"
  private static let isCapturedMethod = "isCaptured"

  private let channel: FlutterMethodChannel

  private var observers: [NSObjectProtocol] = []

  init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
  }

  deinit {
    observers.forEach { NotificationCenter.default.removeObserver($0) }
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = ScreenProtectionPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    instance.observe()
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case ScreenProtectionPlugin.isCapturedMethod:
      result(ScreenProtectionPlugin.isCaptured())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func observe() {
    let center = NotificationCenter.default
    observers.append(center.addObserver(forName: UIScreen.capturedDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
      self?.publish()
    })
    observers.append(center.addObserver(forName: UIScene.didActivateNotification, object: nil, queue: .main) { [weak self] _ in
      self?.publish()
    })
  }

  private func publish() {
    channel.invokeMethod(ScreenProtectionPlugin.captureChangedMethod, arguments: ScreenProtectionPlugin.isCaptured())
  }

  private static func isCaptured() -> Bool {
    UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.contains { $0.screen.isCaptured }
  }
}
