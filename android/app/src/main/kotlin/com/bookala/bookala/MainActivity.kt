package com.bookala.bookala

import android.telephony.SmsManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.bookala.bookala/sms"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "sendSms") {
                val phone = call.argument<String>("phone")
                val message = call.argument<String>("message")

                if (phone != null && message != null) {
                    sendSms(phone, message, result)
                } else {
                    result.error("INVALID_ARGS", "Phone or message missing", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun sendSms(phone: String, message: String, result: MethodChannel.Result) {
        try {
            val smsManager: SmsManager = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                context.getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }
            
            val parts = smsManager.divideMessage(message)
            smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
            result.success("sent")
        } catch (e: Exception) {
            result.error("SEND_FAILED", e.message, null)
        }
    }
}
