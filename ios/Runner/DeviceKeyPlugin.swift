import Flutter
import Foundation
import Security

enum DeviceKeyError: Error {
  case missingKey
  case invalidPayload
}

final class DeviceKeyPlugin: NSObject, FlutterPlugin {
  private static let channelName = "salli/device_keys"
  private static let keySizeInBits = 256

  private func generate(alias: String) throws -> String {
    delete(alias: alias)
    var error: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateRandomKey(attributes(alias: alias) as CFDictionary, &error) else {
      throw error!.takeRetainedValue() as Error
    }
    return try export(privateKey)
  }

  private func attributes(alias: String) -> [String: Any] {
    var attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: DeviceKeyPlugin.keySizeInBits,
      kSecPrivateKeyAttrs as String: [
        kSecAttrIsPermanent as String: true,
        kSecAttrApplicationTag as String: Data(alias.utf8),
        kSecAttrAccessControl as String: accessControl(),
      ],
    ]
    #if !targetEnvironment(simulator)
      attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
    #endif
    return attributes
  }

  private func accessControl() -> SecAccessControl {
    #if targetEnvironment(simulator)
      let flags: SecAccessControlCreateFlags = []
    #else
      let flags: SecAccessControlCreateFlags = .privateKeyUsage
    #endif
    return SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, flags, nil)!
  }

  private func publicKey(alias: String) throws -> String? {
    guard let privateKey = find(alias: alias) else { return nil }
    return try export(privateKey)
  }

  private func export(_ privateKey: SecKey) throws -> String {
    guard let publicKey = SecKeyCopyPublicKey(privateKey) else { throw DeviceKeyError.missingKey }
    var error: Unmanaged<CFError>?
    guard let data = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
      throw error!.takeRetainedValue() as Error
    }
    return data.base64EncodedString()
  }

  private func sign(alias: String, payload: String) throws -> String {
    guard let privateKey = find(alias: alias) else { throw DeviceKeyError.missingKey }
    guard let data = Data(base64Encoded: payload) else { throw DeviceKeyError.invalidPayload }
    var error: Unmanaged<CFError>?
    guard let signature = SecKeyCreateSignature(privateKey, .ecdsaSignatureMessageX962SHA256, data as CFData, &error) as Data? else {
      throw error!.takeRetainedValue() as Error
    }
    return signature.base64EncodedString()
  }

  private func find(alias: String) -> SecKey? {
    var query = query(alias: alias)
    query[kSecReturnRef as String] = true
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let item else { return nil }
    return (item as! SecKey)
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
    registrar.addMethodCallDelegate(DeviceKeyPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any], let alias = arguments["alias"] as? String else {
      result(FlutterError(code: "invalid_arguments", message: nil, details: nil))
      return
    }
    do {
      switch call.method {
      case "delete":
        delete(alias: alias)
        result(nil)
      case "generate":
        result(try generate(alias: alias))
      case "publicKey":
        result(try publicKey(alias: alias))
      case "sign":
        result(try sign(alias: alias, payload: arguments["payload"] as? String ?? ""))
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch {
      result(FlutterError(code: "device_key_failure", message: String(describing: type(of: error)), details: nil))
    }
  }
}
