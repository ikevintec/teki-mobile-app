package pe.teki.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val tag = "YapeMainActivity"
    private val methodChannelName = "pe.teki.app/yape"
    private val eventChannelName = "pe.teki.app/yape/events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        YapeSyncWorker.schedulePeriodic(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isPermissionGranted" -> result.success(isNotificationAccessGranted())
                    "openSettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(true)
                    }
                    "setEnabledApps" -> {
                        val apps = (call.arguments as? List<*>)
                            ?.mapNotNull { it as? String }
                            ?: emptyList()
                        YapeNotificationListenerService.setEnabledApps(this, apps)
                        result.success(true)
                    }
                    "peekQueue" ->
                        result.success(YapeNotificationListenerService.peekQueue(this))
                    "ackItems" -> {
                        @Suppress("UNCHECKED_CAST")
                        val ids = (call.arguments as? List<String>) ?: emptyList()
                        YapeNotificationListenerService.ackItems(this, ids)
                        result.success(true)
                    }
                    "setSyncCredentials" -> {
                        val token = call.argument<String>("token")
                        val baseUrl = call.argument<String>("baseUrl")
                        if (token.isNullOrBlank() || baseUrl.isNullOrBlank()) {
                            clearSyncCredentials()
                        } else {
                            syncPrefs()
                                .edit()
                                .putString(YapeSyncWorker.TOKEN_KEY, token)
                                .putString(YapeSyncWorker.BASE_URL_KEY, baseUrl)
                                .apply()
                        }
                        result.success(true)
                    }
                    "clearSyncCredentials" -> {
                        clearSyncCredentials()
                        result.success(true)
                    }
                    "isIgnoringBatteryOptimizations" ->
                        result.success(isIgnoringBatteryOptimizations())
                    "requestIgnoreBatteryOptimizations" -> {
                        val alreadyExempt = isIgnoringBatteryOptimizations()
                        if (!alreadyExempt) requestIgnoreBatteryOptimizations()
                        result.success(alreadyExempt)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    YapeNotificationListenerService.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    YapeNotificationListenerService.eventSink = null
                }
            })
    }

    private fun syncPrefs() = getSharedPreferences(
        YapeNotificationListenerService.PREFS,
        Context.MODE_PRIVATE
    )

    private fun clearSyncCredentials() {
        syncPrefs()
            .edit()
            .remove(YapeSyncWorker.TOKEN_KEY)
            .remove(YapeSyncWorker.BASE_URL_KEY)
            .apply()
    }

    private fun isNotificationAccessGranted(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        ) ?: return false
        return enabled.contains(packageName)
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val power = getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return false
        return power.isIgnoringBatteryOptimizations(packageName)
    }

    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        try {
            startActivity(
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    .setData(Uri.parse("package:$packageName"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        } catch (e: Exception) {
            try {
                startActivity(
                    Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
            } catch (_: Exception) {
                Log.w(tag, "Sin pantalla de optimización de batería disponible")
            }
        }
    }
}
