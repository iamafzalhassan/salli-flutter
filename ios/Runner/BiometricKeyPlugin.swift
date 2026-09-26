import Flutter
import Foundation
import LocalAuthentication
import Security

final class BiometricKeyPlugin: NSObject, FlutterPlugin {
  private static let channelName = "salli/biometric_keys"
  private static let keySizeInBits = 256

  private func availability() -> String {
    let context = LAContext()
    var error: NSError?
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) { return "available" }
    return error?.code == LAError.biometryNotEnrolled.rawValue ? "notEnrolled" : "unavailable"
  }

  private func generate(alias: String) throws -> String {
    delete(alias: alias)
    var error: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateRandomKey(attributes(alias: alias) as CFDictionary, &error) else {
      throw error!.takeRetainedValue() as Error
    }
    guard let publicKey = SecKeyCopyPublicKey(privateKey), let data = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
      throw DeviceKeyError.missingKey
    }
    return data.base64EncodedString()
  }

  private func attributes(alias: String) -> [String: Any] {
    #if targetEnvironment(simulator)
      let flags: SecAccessControlCreateFlags = [.biometryCurrentSet]
    #else
      let flags: SecAccessControlCreateFlags = [.privateKeyUsage, .biometryCurrentSet]
    #endif
    let accessControl = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, flags, nil)!
    var attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: BiometricKeyPlugin.keySizeInBits,
      kSecPrivateKeyAttrs as String: [
        kSecAttrIsPermanent as String: true,
        kSecAttrApplicationTag as String: Data(alias.utf8),
        kSecAttrAccessControl as String: accessControl,
      ],
    ]
    #if !targetEnvironment(simulator)
      attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
    #endif
    return attributes
  }

  private func sign(alias: String, payload: String, title: String, cancel: String, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      let reply: Any
      do {
        reply = try self.signature(alias: alias, payload: payload, title: title, cancel: cancel)
      } catch let error as LAError {
        reply = FlutterError(code: self.errorCode(for: error), message: nil, details: nil)
      } catch DeviceKeyError.missingKey {
        reply = FlutterError(code: "invalidated", message: nil, details: nil)
      } catch {
        reply = FlutterError(code: "unavailable", message: String(describing: type(of: error)), details: nil)
      }
      DispatchQueue.main.async { result(reply) }
    }
  }

  private func signature(alias: String, payload: String, title: String, cancel: String) throws -> String {
    let context = LAContext()
    context.localizedCancelTitle = cancel
    context.localizedReason = title
    var query = query(alias: alias)
    query[kSecReturnRef as String] = true
    query[kSecUseAuthenticationContext as String] = context
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let item else { throw DeviceKeyError.missingKey }
    guard let data = Data(base64Encoded: payload) else { throw DeviceKeyError.invalidPayload }
    var error: Unmanaged<CFError>?
    guard let signature = SecKeyCreateSignature(item as! SecKey, .ecdsaSignatureMessageX962SHA256, data as CFData, &error) as Data? else {
      let failure = error!.takeRetainedValue() as Error
      throw (failure as NSError).domain == LAErrorDomain ? LAError(_nsError: failure as NSError) : failure
    }
    return signature.base64EncodedString()
  }

  private func errorCode(for error: LAError) -> String {
    switch error.code {
    case .appCancel, .systemCancel, .userCancel, .userFallback:
      return "cancelled"
    case .biometryLockout:
      return "lockout"
    default:
      return "unavailable"
    }
  }

  private func delete(alias: String) {
    SecItemDelete(query(alias: alias) as CFDictionary)
  }

  private func query(alias: String) -> [String: Any] {
    [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: Data(alias.utf8),
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
    ]
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(BiometricKeyPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]
    let alias = arguments["alias"] as? String ?? ""
    do {
      switch call.method {
      case "availability":
        result(availability())
      case "delete":
        delete(alias: alias)
        result(nil)
      case "generate":
        result(try generate(alias: alias))
      case "sign":
        sign(alias: alias, payload: arguments["payload"] as? String ?? "", title: arguments["title"] as? String ?? "", cancel: arguments["cancel"] as? String ?? "", result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch {
      result(FlutterError(code: "unavailable", message: String(describing: type(of: error)), details: nil))
    }
  }
}
