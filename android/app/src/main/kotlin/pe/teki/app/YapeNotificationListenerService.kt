package pe.teki.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject

/** Ver README.md de este paquete. */
class YapeNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "YapeListener"
        const val PREFS = "yape_listener_prefs"
        const val QUEUE_KEY = "queue"
        const val ENABLED_APPS_KEY = "enabled_apps"

        val QUEUE_LOCK = Any()

        private val APP_PACKAGES = mapOf(
            "com.bcp.innovacxion.yapeapp" to "YAPE",
            "com.bbva.nxt_peru" to "BBVA",
            "pe.com.interbank.mobilebanking" to "INTERBANK"
        )

        @Volatile
        var eventSink: EventChannel.EventSink? = null

        private val mainHandler = Handler(Looper.getMainLooper())

        fun peekQueue(context: Context): String {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            return synchronized(QUEUE_LOCK) {
                prefs.getString(QUEUE_KEY, "[]") ?: "[]"
            }
        }

        fun setEnabledApps(context: Context, apps: List<String>) {
            val enabled = apps.filter { APP_PACKAGES.containsValue(it) }.toSet()
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            synchronized(QUEUE_LOCK) {
                prefs
                    .edit()
                    .putString(ENABLED_APPS_KEY, enabled.joinToString(","))
                    .apply()
                filterQueueLocked(prefs, enabled)
            }
        }

        private fun filterQueueLocked(
            prefs: android.content.SharedPreferences,
            enabled: Set<String>
        ) {
            val current = JSONArray(prefs.getString(QUEUE_KEY, "[]") ?: "[]")
            val remaining = JSONArray()
            for (i in 0 until current.length()) {
                val item = current.optJSONObject(i) ?: continue
                val type = item.optString("tipoApp", "YAPE")
                if (type in enabled) remaining.put(item)
            }
            prefs.edit().putString(QUEUE_KEY, remaining.toString()).apply()
        }

        fun ackItems(context: Context, ids: List<String>) {
            if (ids.isEmpty()) return
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            synchronized(QUEUE_LOCK) {
                val current = JSONArray(prefs.getString(QUEUE_KEY, "[]") ?: "[]")
                val remaining = JSONArray()
                for (i in 0 until current.length()) {
                    val item = current.optJSONObject(i) ?: continue
                    if (!ids.contains(item.optString("id"))) remaining.put(item)
                }
                prefs.edit().putString(QUEUE_KEY, remaining.toString()).apply()
            }
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "Listener conectado, se programa el envío del backlog")
        YapeSyncWorker.schedule(applicationContext)
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        val notification = sbn ?: return
        val typeApp = APP_PACKAGES[notification.packageName] ?: return
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val enabled = prefs.getString(ENABLED_APPS_KEY, "")
            ?.split(",")
            ?.filter { it.isNotBlank() }
            ?.toSet()
            ?: emptySet()
        if (typeApp !in enabled) return

        val extras = notification.notification?.extras
        val title = extras?.getCharSequence("android.title")?.toString() ?: ""
        val text = extras?.getCharSequence("android.text")?.toString() ?: ""
        val bigText = extras?.getCharSequence("android.bigText")?.toString() ?: ""

        val id = "${notification.packageName}:${notification.key}:${notification.postTime}"

        val item = JSONObject().apply {
            put("id", id)
            put("package", notification.packageName)
            put("title", title)
            put("text", text)
            put("bigText", bigText)
            put("tipoApp", typeApp)
            put("postTime", notification.postTime)
        }

        Log.d(TAG, "$typeApp capturado -> title='$title' text='$text' big='$bigText'")

        enqueue(item)
        YapeSyncWorker.schedule(applicationContext)
        mainHandler.post {
            try {
                eventSink?.success(item.toString())
            } catch (e: Exception) {
                Log.w(TAG, "No se pudo emitir evento en vivo: ${e.message}")
            }
        }
    }

    private fun enqueue(item: JSONObject) {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        synchronized(QUEUE_LOCK) {
            val queue = JSONArray(prefs.getString(QUEUE_KEY, "[]") ?: "[]")
            val id = item.optString("id")
            for (i in 0 until queue.length()) {
                if (queue.optJSONObject(i)?.optString("id") == id) return
            }
            queue.put(item)
            prefs.edit().putString(QUEUE_KEY, queue.toString()).apply()
        }
    }
}
