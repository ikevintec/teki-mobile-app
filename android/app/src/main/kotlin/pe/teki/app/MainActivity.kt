package pe.teki.app

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val methodChannelName = "pe.teki.app/yape"
    private val eventChannelName = "pe.teki.app/yape/events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
                    "setListenerEnabled" -> {
                        val enabled = call.arguments as? Boolean ?: false
                        YapeNotificationListenerService.setListenerEnabled(this, enabled)
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

    private fun isNotificationAccessGranted(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        ) ?: return false
        return enabled.contains(packageName)
    }
}
