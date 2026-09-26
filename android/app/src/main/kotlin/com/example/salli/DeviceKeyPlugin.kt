package com.example.salli

import android.content.pm.PackageManager
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.ProviderException
import java.security.PublicKey
import java.security.Signature
import java.security.spec.ECGenParameterSpec

class DeviceKeyPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    companion object {
        private const val ANDROID_KEY_STORE = "AndroidKeyStore"
        private const val CHANNEL = "salli/device_keys"
        private const val CURVE = "secp256r1"
        private const val RAW_PUBLIC_KEY_LENGTH = 65
        private const val SIGNATURE_ALGORITHM = "SHA256withECDSA"
    }

    private var hasStrongBox = false

    private var channel: MethodChannel? = null

    private fun generate(alias: String): String {
        keyStore().deleteEntry(alias)
        val publicKey = try {
            createKeyPair(alias, hasStrongBox)
        } catch (exception: ProviderException) {
            if (!hasStrongBox) throw exception
            createKeyPair(alias, false)
        }
        return encode(publicKey)
    }

    private fun createKeyPair(alias: String, isStrongBoxBacked: Boolean): PublicKey {
        val spec = KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_SIGN)
            .setAlgorithmParameterSpec(ECGenParameterSpec(CURVE))
            .setDigests(KeyProperties.DIGEST_SHA256)
            .apply { if (isStrongBoxBacked && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) setIsStrongBoxBacked(true) }
            .build()
        return KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, ANDROID_KEY_STORE).apply { initialize(spec) }.generateKeyPair().public
    }

    private fun publicKey(alias: String): String? = keyStore().getCertificate(alias)?.publicKey?.let(::encode)

    private fun encode(publicKey: PublicKey): String {
        val encoded = publicKey.encoded
        return Base64.encodeToString(encoded.copyOfRange(encoded.size - RAW_PUBLIC_KEY_LENGTH, encoded.size), Base64.NO_WRAP)
    }

    private fun sign(alias: String, payload: String): String {
        val privateKey = keyStore().getKey(alias, null) as PrivateKey
        val signature = Signature.getInstance(SIGNATURE_ALGORITHM).apply {
            initSign(privateKey)
            update(Base64.decode(payload, Base64.NO_WRAP))
        }
        return Base64.encodeToString(signature.sign(), Base64.NO_WRAP)
    }

    private fun keyStore(): KeyStore = KeyStore.getInstance(ANDROID_KEY_STORE).apply { load(null) }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        hasStrongBox = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && binding.applicationContext.packageManager.hasSystemFeature(PackageManager.FEATURE_STRONGBOX_KEYSTORE)
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).also { it.setMethodCallHandler(this) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val alias = call.argument<String>("alias")
        if (alias == null) {
            result.error("invalid_arguments", null, null)
            return
        }
        try {
            when (call.method) {
                "delete" -> {
                    keyStore().deleteEntry(alias)
                    result.success(null)
                }
                "generate" -> result.success(generate(alias))
                "publicKey" -> result.success(publicKey(alias))
                "sign" -> result.success(sign(alias, call.argument<String>("payload").orEmpty()))
                else -> result.notImplemented()
            }
        } catch (exception: Exception) {
            result.error("device_key_failure", exception.javaClass.simpleName, null)
        }
    }
}
