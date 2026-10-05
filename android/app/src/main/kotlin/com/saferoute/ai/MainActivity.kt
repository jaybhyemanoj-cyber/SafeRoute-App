package com.saferoute.ai

import android.Manifest
import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.telephony.SmsManager
import android.view.KeyEvent
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.saferoute.ai/emergency"
    private val SMS_PERMISSION_REQ_CODE = 1001

    private var methodChannel: MethodChannel? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    // Volume sequence tracking
    private val volumePressTimestamps = mutableListOf<Long>()
    private val VOLUME_PRESS_WINDOW_MS = 3000L // 3 seconds
    private val VOLUME_PRESS_REQUIRED = 3

    // Action strings for SMS intents
    private val ACTION_SMS_SENT = "com.saferoute.ai.SMS_SENT"
    private val ACTION_SMS_DELIVERED = "com.saferoute.ai.SMS_DELIVERED"

    private var smsSentReceiver: BroadcastReceiver? = null
    private var smsDeliveredReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkSmsPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.SEND_SMS
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }
                "requestSmsPermission" -> {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED) {
                        result.success(true)
                    } else {
                        pendingPermissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.SEND_SMS),
                            SMS_PERMISSION_REQ_CODE
                        )
                    }
                }
                "sendEmergencySms" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val message = call.argument<String>("message")

                    if (phoneNumber.isNullOrEmpty() || message.isNullOrEmpty()) {
                        result.error("INVALID_ARGS", "Phone number and message are required", null)
                        return@setMethodCallHandler
                    }

                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) != PackageManager.PERMISSION_GRANTED) {
                        result.error("PERMISSION_DENIED", "SEND_SMS permission not granted", null)
                        return@setMethodCallHandler
                    }

                    sendSmsNative(phoneNumber, message, result)
                }
                "openAppSettings" -> {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", packageName, null)
                    }
                    startActivity(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun sendSmsNative(phoneNumber: String, message: String, result: MethodChannel.Result) {
        try {
            unregisterSmsReceivers()

            val sentPI = PendingIntent.getBroadcast(
                this,
                0,
                Intent(ACTION_SMS_SENT),
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_UPDATE_CURRENT
            )

            val deliveredPI = PendingIntent.getBroadcast(
                this,
                0,
                Intent(ACTION_SMS_DELIVERED),
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_UPDATE_CURRENT
            )

            smsSentReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    val statusMap = mutableMapOf<String, String>()
                    when (resultCode) {
                        Activity.RESULT_OK -> {
                            statusMap["status"] = "SENT"
                        }
                        SmsManager.RESULT_ERROR_GENERIC_FAILURE -> {
                            statusMap["status"] = "SEND_FAILED"
                            statusMap["error"] = "Generic failure (Check SIM/balance)"
                        }
                        SmsManager.RESULT_ERROR_NO_SERVICE -> {
                            statusMap["status"] = "SEND_FAILED"
                            statusMap["error"] = "No cellular network service available"
                        }
                        SmsManager.RESULT_ERROR_NULL_PDU -> {
                            statusMap["status"] = "SEND_FAILED"
                            statusMap["error"] = "Null PDU"
                        }
                        SmsManager.RESULT_ERROR_RADIO_OFF -> {
                            statusMap["status"] = "SEND_FAILED"
                            statusMap["error"] = "Airplane mode or cellular radio off"
                        }
                        else -> {
                            statusMap["status"] = "SEND_FAILED"
                            statusMap["error"] = "Failed with error code $resultCode"
                        }
                    }
                    methodChannel?.invokeMethod("onSmsStatusUpdated", statusMap)
                }
            }

            smsDeliveredReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    val statusMap = mutableMapOf<String, String>()
                    when (resultCode) {
                        Activity.RESULT_OK -> {
                            statusMap["status"] = "DELIVERED"
                        }
                        else -> {
                            statusMap["status"] = "DELIVERY_UNAVAILABLE"
                            statusMap["error"] = "Delivery status unavailable"
                        }
                    }
                    methodChannel?.invokeMethod("onSmsStatusUpdated", statusMap)
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(smsSentReceiver, IntentFilter(ACTION_SMS_SENT), Context.RECEIVER_EXPORTED)
                registerReceiver(smsDeliveredReceiver, IntentFilter(ACTION_SMS_DELIVERED), Context.RECEIVER_EXPORTED)
            } else {
                registerReceiver(smsSentReceiver, IntentFilter(ACTION_SMS_SENT))
                registerReceiver(smsDeliveredReceiver, IntentFilter(ACTION_SMS_DELIVERED))
            }

            val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                this.getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }

            val parts = smsManager.divideMessage(message)
            if (parts.size > 1) {
                val sentIntents = ArrayList<PendingIntent>()
                val deliveryIntents = ArrayList<PendingIntent>()
                for (i in parts.indices) {
                    sentIntents.add(sentPI)
                    deliveryIntents.add(deliveredPI)
                }
                smsManager.sendMultipartTextMessage(phoneNumber, null, parts, sentIntents, deliveryIntents)
            } else {
                smsManager.sendTextMessage(phoneNumber, null, message, sentPI, deliveredPI)
            }

            result.success(mapOf("status" to "SENDING", "message" to "SMS dispatch initiated"))
        } catch (e: Exception) {
            result.error("SMS_SEND_ERROR", e.localizedMessage ?: "Failed to send SMS", null)
        }
    }

    private fun unregisterSmsReceivers() {
        try {
            smsSentReceiver?.let {
                unregisterReceiver(it)
                smsSentReceiver = null
            }
            smsDeliveredReceiver?.let {
                unregisterReceiver(it)
                smsDeliveredReceiver = null
            }
        } catch (e: Exception) {
            // Ignore if already unregistered
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == SMS_PERMISSION_REQ_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    // Secondary Trigger: Volume Button Sequence Listener
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN || keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
            val now = System.currentTimeMillis()
            volumePressTimestamps.add(now)

            // Remove timestamps older than window
            volumePressTimestamps.removeAll { now - it > VOLUME_PRESS_WINDOW_MS }

            if (volumePressTimestamps.size >= VOLUME_PRESS_REQUIRED) {
                volumePressTimestamps.clear()
                runOnUiThread {
                    methodChannel?.invokeMethod("onVolumeEmergencyTriggered", null)
                }
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onDestroy() {
        unregisterSmsReceivers()
        super.onDestroy()
    }
}
