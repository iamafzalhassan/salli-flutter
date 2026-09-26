package com.example.salli

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Parcelable
import androidx.core.content.ContextCompat
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class SmsConsentPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler, PluginRegistry.ActivityResultListener {
    companion object {
        private const val CHANNEL = "salli/sms_consent"
        private const val CONSENT_REQUEST = 4271
    }

    private var activity: Activity? = null

    private var binding: ActivityPluginBinding? = null

    private var channel: MethodChannel? = null

    private var pending: MethodChannel.Result? = null

    private var receiver: BroadcastReceiver? = null

    private fun listen(result: MethodChannel.Result) {
        val activity = activity ?: return result.success(null)
        finish(null)
        pending = result
        val consentReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action != SmsRetriever.SMS_RETRIEVED_ACTION) return
                val status = parcelable<Status>(intent, SmsRetriever.EXTRA_STATUS)
                val consent = parcelable<Intent>(intent, SmsRetriever.EXTRA_CONSENT_INTENT)
                if (status?.statusCode != CommonStatusCodes.SUCCESS || consent == null) return finish(null)
                try {
                    activity.startActivityForResult(consent, CONSENT_REQUEST)
                } catch (exception: android.content.ActivityNotFoundException) {
                    finish(null)
                }
            }
        }
        receiver = consentReceiver
        ContextCompat.registerReceiver(activity, consentReceiver, IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION), SmsRetriever.SEND_PERMISSION, null, ContextCompat.RECEIVER_EXPORTED)
        SmsRetriever.getClient(activity).startSmsUserConsent(null).addOnFailureListener { finish(null) }
    }

    private inline fun <reified T : Parcelable> parcelable(intent: Intent, key: String): T? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.extras?.getParcelable(key, T::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.extras?.getParcelable(key)
        }

    private fun finish(message: String?) {
        receiver?.let { registered -> activity?.let { runCatching { it.unregisterReceiver(registered) } } }
        receiver = null
        pending?.success(message)
        pending = null
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL).also { it.setMethodCallHandler(this) }
    }

    override fun onDetachedFromEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onAttachedToActivity(activityBinding: ActivityPluginBinding) {
        activity = activityBinding.activity
        binding = activityBinding.also { it.addActivityResultListener(this) }
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(activityBinding: ActivityPluginBinding) = onAttachedToActivity(activityBinding)

    override fun onDetachedFromActivity() {
        finish(null)
        binding?.removeActivityResultListener(this)
        binding = null
        activity = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != CONSENT_REQUEST) return false
        finish(if (resultCode == Activity.RESULT_OK) data?.getStringExtra(SmsRetriever.EXTRA_SMS_MESSAGE) else null)
        return true
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "listen" -> listen(result)
            "cancel" -> {
                finish(null)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
