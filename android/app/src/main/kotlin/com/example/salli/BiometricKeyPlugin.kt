package com.example.salli

import android.content.Context
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.Signature
import java.security.spec.ECGenParameterSpec

class BiometricKeyPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
    companion object {
        private const val ANDROID_KEY_STORE = "AndroidKeyStore"
        private const val AUTHENTICATORS = BiometricManager.Authenticators.BIOMETRIC_STRONG
        private const val CHANNEL = "salli/biometric_keys"
        private const val CURVE = "secp256r1"
        private const val RAW_PUBLIC_KEY_LENGTH = 65
        private const val SIGNATURE_ALGORITHM = "SHA256withECDSA"
    }

    private var activity: FragmentActivity? = null

    private var channel: MethodChannel? = null

    private var context: Context? = null

    private fun availability(): String {
        val context = context ?: return "unavailable"
        return when (BiometricManager.from(context).canAuthenticate(AUTHENTICATORS)) {
            BiometricManager.BIOMETRIC_SUCCESS -> "available"
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> "notEnrolled"
            else -> "unavailable"
        }
    }

    @Suppress("DEPRECATION")
    private fun generate(alias: String): String {
        keyStore().deleteEntry(alias)
        val builder = KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_SIGN)
            .setAlgorithmParameterSpec(ECGenParameterSpec(CURVE))
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setUserAuthenticationRequired(true)
            .setInvalidatedByBiometricEnrollment(true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            builder.setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)
        } else {
            builder.setUserAuthenticationValidityDurationSeconds(-1)
        }
        val publicKey = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, ANDROID_KEY_STORE).apply { initialize(builder.build()) }.generateKeyPair().public
        val encoded = publicKey.encoded
        return Base64.encodeToString(encoded.copyOfRange(encoded.size - RAW_PUBLIC_KEY_LENGTH, encoded.size), Base64.NO_WRAP)
    }

    private fun sign(alias: String, payload: String, title: String, cancel: String, result: MethodChannel.Result) {
        val activity = activity ?: return result.error("unavailable", null, null)
        val signature = try {
            val privateKey = keyStore().getKey(alias, null) as? PrivateKey ?: return result.error("invalidated", null, null)
            Signature.getInstance(SIGNATURE_ALGORITHM).apply { initSign(privateKey) }
        } catch (exception: KeyPermanentlyInvalidatedException) {
            keyStore().deleteEntry(alias)
            return result.error("invalidated", null, null)
        } catch (exception: Exception) {
            return result.error("unavailable", exception.javaClass.simpleName, null)
        }
        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                result.error(errorCodeFor(errorCode), null, null)
            }

            override fun onAuthenticationSucceeded(authenticationResult: BiometricPrompt.AuthenticationResult) {
                val signer = authenticationResult.cryptoObject?.signature ?: return result.error("unavailable", null, null)
                val signed = try {
                    signer.update(Base64.decode(payload, Base64.NO_WRAP))
                    signer.sign()
                } catch (exception: Exception) {
                    return result.error("unavailable", exception.javaClass.simpleName, null)
                }
                result.success(Base64.encodeToString(signed, Base64.NO_WRAP))
            }
        }
        val promptInfo = BiometricPrompt.PromptInfo.Builder().setAllowedAuthenticators(AUTHENTICATORS).setNegativeButtonText(cancel).setTitle(title).build()
        BiometricPrompt(activity, ContextCompat.getMainExecutor(activity), callback).authenticate(promptInfo, BiometricPrompt.CryptoObject(signature))
    }

    private fun errorCodeFor(errorCode: Int): String = when (errorCode) {
        BiometricPrompt.ERROR_CANCELED, BiometricPrompt.ERROR_NEGATIVE_BUTTON, BiometricPrompt.ERROR_USER_CANCELED -> "cancelled"
        BiometricPrompt.ERROR_LOCKOUT, BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> "lockout"
        else -> "unavailable"
    }

    private fun keyStore(): KeyStore = KeyStore.getInstance(ANDROID_KEY_STORE).apply { load(null) }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).also { it.setMethodCallHandler(this) }
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "availability" -> result.success(availability())
                "delete" -> {
                    keyStore().deleteEntry(call.argument<String>("alias").orEmpty())
                    result.success(null)
                }
                "generate" -> result.success(generate(call.argument<String>("alias").orEmpty()))
                "sign" -> sign(
                    call.argument<String>("alias").orEmpty(),
                    call.argument<String>("payload").orEmpty(),
                    call.argument<String>("title").orEmpty(),
                    call.argument<String>("cancel").orEmpty(),
                    result,
                )
                else -> result.notImplemented()
            }
        } catch (exception: Exception) {
            result.error("unavailable", exception.javaClass.simpleName, null)
        }
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity
    }
}
