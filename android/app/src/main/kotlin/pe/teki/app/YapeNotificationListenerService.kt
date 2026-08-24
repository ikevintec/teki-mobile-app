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

/**
 * Escucha las notificaciones del sistema y captura las emitidas por la app de
 * Yape. Cada captura se guarda en una cola local (SharedPreferences) para que no
 * se pierda aunque la app Teki esté cerrada; el POST al backend lo realiza el
 * lado Flutter cuando la app está viva (drena la cola / recibe el evento en vivo).
 */
class YapeNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "YapeListener"
        const val PREFS = "yape_listener_prefs"
        const val QUEUE_KEY = "queue"

        /** Paquetes de la app de Yape (producción). */
        private val YAPE_PACKAGES = setOf("com.bcp.innovacxion.yapeapp")

        /** Sink del EventChannel: lo setea MainActivity mientras la app está viva. */
        @Volatile
        var eventSink: EventChannel.EventSink? = null

        private val mainHandler = Handler(Looper.getMainLooper())

        /** Devuelve la cola pendiente sin borrarla. */
        fun peekQueue(context: Context): String {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            return prefs.getString(QUEUE_KEY, "[]") ?: "[]"
        }

        /** Elimina de la cola los items cuyos ids se confirmaron (POST exitoso). */
        fun ackItems(context: Context, ids: List<String>) {
            if (ids.isEmpty()) return
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val current = JSONArray(prefs.getString(QUEUE_KEY, "[]") ?: "[]")
            val remaining = JSONArray()
            for (i in 0 until current.length()) {
                val item = current.optJSONObject(i) ?: continue
                if (!ids.contains(item.optString("id"))) remaining.put(item)
            }
            prefs.edit().putString(QUEUE_KEY, remaining.toString()).apply()
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        val notification = sbn ?: return
        if (notification.packageName !in YAPE_PACKAGES) return

        val extras = notification.notification?.extras
        val title = extras?.getCharSequence("android.title")?.toString() ?: ""
        val text = extras?.getCharSequence("android.text")?.toString() ?: ""
        val bigText = extras?.getCharSequence("android.bigText")?.toString() ?: ""

        // id estable por notificación para evitar duplicados en la cola.
        val id = "${notification.packageName}:${notification.key}:${notification.postTime}"

        val item = JSONObject().apply {
            put("id", id)
            put("package", notification.packageName)
            put("title", title)
            put("text", text)
            put("bigText", bigText)
            put("postTime", notification.postTime)
        }

        Log.d(TAG, "Yape capturado -> title='$title' text='$text' big='$bigText'")

        enqueue(item)
        // Aviso en vivo (solo si la app está abierta y registró el sink).
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
        val queue = JSONArray(prefs.getString(QUEUE_KEY, "[]") ?: "[]")
        // Evita reencolar la misma notificación.
        val id = item.optString("id")
        for (i in 0 until queue.length()) {
            if (queue.optJSONObject(i)?.optString("id") == id) return
        }
        queue.put(item)
        prefs.edit().putString(QUEUE_KEY, queue.toString()).apply()
    }
}
