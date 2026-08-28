package pe.teki.app

import android.content.Context
import android.os.Build
import android.util.Log
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.TimeUnit

class YapeSyncWorker(
    appContext: Context,
    params: WorkerParameters
) : CoroutineWorker(appContext, params) {

    companion object {
        const val TAG = "YapeSyncWorker"
        const val TOKEN_KEY = "sync_token"
        const val BASE_URL_KEY = "sync_base_url"

        private const val UNIQUE_WORK = "yape-sync"
        private const val UNIQUE_PERIODIC_WORK = "yape-sync-periodic"
        private const val TIMEOUT_MS = 15_000

        private fun networkConstraints() = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        fun schedule(context: Context) {
            val builder = OneTimeWorkRequestBuilder<YapeSyncWorker>()
                .setConstraints(networkConstraints())
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 10, TimeUnit.SECONDS)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                builder.setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            }
            try {
                WorkManager.getInstance(context).enqueueUniqueWork(
                    UNIQUE_WORK,
                    ExistingWorkPolicy.APPEND_OR_REPLACE,
                    builder.build()
                )
            } catch (e: Exception) {
                Log.w(TAG, "No se pudo encolar el envío inmediato: ${e.message}")
            }
        }

        fun schedulePeriodic(context: Context) {
            val request = PeriodicWorkRequestBuilder<YapeSyncWorker>(15, TimeUnit.MINUTES)
                .setConstraints(networkConstraints())
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 10, TimeUnit.SECONDS)
                .build()
            try {
                WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                    UNIQUE_PERIODIC_WORK,
                    ExistingPeriodicWorkPolicy.KEEP,
                    request
                )
            } catch (e: Exception) {
                Log.w(TAG, "No se pudo encolar el respaldo periódico: ${e.message}")
            }
        }
    }

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val prefs = applicationContext.getSharedPreferences(
            YapeNotificationListenerService.PREFS,
            Context.MODE_PRIVATE
        )

        val token = prefs.getString(TOKEN_KEY, null)?.takeIf { it.isNotBlank() }
        val baseUrl = prefs.getString(BASE_URL_KEY, null)?.takeIf { it.isNotBlank() }
        if (token == null || baseUrl == null) {
            Log.d(TAG, "Sin credenciales espejadas, la app enviará la cola al abrirse")
            return@withContext Result.success()
        }

        val enabled = prefs.getString(YapeNotificationListenerService.ENABLED_APPS_KEY, "")
            ?.split(",")
            ?.filter { it.isNotBlank() }
            ?.toSet()
            ?: emptySet()

        val queue = synchronized(YapeNotificationListenerService.QUEUE_LOCK) {
            JSONArray(prefs.getString(YapeNotificationListenerService.QUEUE_KEY, "[]") ?: "[]")
        }
        if (queue.length() == 0) return@withContext Result.success()

        val ackIds = mutableListOf<String>()
        var needsRetry = false
        var unauthorized = false

        for (i in 0 until queue.length()) {
            val item = queue.optJSONObject(i) ?: continue
            val id = item.optString("id")
            if (id.isEmpty()) continue

            val tipoApp = item.optString("tipoApp", "YAPE")
            if (tipoApp !in enabled) {
                ackIds.add(id)
                continue
            }

            val payment = YapePaymentParser.parse(item)
            if (payment == null) {
                Log.d(TAG, "Ignorada (sin monto): '${item.optString("text")}'")
                ackIds.add(id)
                continue
            }

            when (val code = post(baseUrl, token, payment)) {
                in 200..299 -> {
                    Log.d(
                        TAG,
                        "Registrado: ${payment.nombrePagador} S/ ${payment.monto} " +
                            "(op ${payment.codigoOperacion})"
                    )
                    ackIds.add(id)
                }
                HttpURLConnection.HTTP_UNAUTHORIZED -> {
                    Log.w(TAG, "401: credenciales vencidas, se limpia el token espejado")
                    unauthorized = true
                }
                in 500..599, HTTP_NO_RESPONSE, HttpURLConnection.HTTP_CLIENT_TIMEOUT, 429 -> {
                    Log.w(TAG, "Error temporal ($code), se reintentará")
                    needsRetry = true
                }
                else -> {
                    Log.w(TAG, "Error permanente ($code), queda en cola para la app")
                }
            }
            if (unauthorized) break
        }

        if (ackIds.isNotEmpty()) {
            YapeNotificationListenerService.ackItems(applicationContext, ackIds)
        }
        if (unauthorized) {
            prefs.edit().remove(TOKEN_KEY).apply()
            return@withContext Result.success()
        }
        if (needsRetry) Result.retry() else Result.success()
    }

    private fun post(
        baseUrl: String,
        token: String,
        payment: YapePaymentParser.Payment
    ): Int {
        val body = JSONObject().apply {
            put("nombrePagador", payment.nombrePagador)
            put("monto", payment.monto)
            put("codigoOperacion", payment.codigoOperacion)
            put("tipoApp", payment.tipoApp)
        }.toString()

        var connection: HttpURLConnection? = null
        return try {
            val url = URL("${baseUrl.trimEnd('/')}/pagos-yape")
            connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = TIMEOUT_MS
                readTimeout = TIMEOUT_MS
                doOutput = true
                setRequestProperty("Authorization", "Bearer $token")
                setRequestProperty("PlatformRequest", "mobile")
                setRequestProperty("Content-Type", "application/json; charset=utf-8")
                setRequestProperty("Accept", "application/json")
            }
            connection.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }
            val code = connection.responseCode
            runCatching {
                (if (code in 200..299) connection.inputStream else connection.errorStream)
                    ?.use { it.readBytes() }
            }
            code
        } catch (e: IOException) {
            Log.w(TAG, "Fallo de red enviando el pago: ${e.message}")
            HTTP_NO_RESPONSE
        } catch (e: Exception) {
            Log.w(TAG, "Fallo inesperado enviando el pago: ${e.message}")
            HTTP_NO_RESPONSE
        } finally {
            connection?.disconnect()
        }
    }
}

private const val HTTP_NO_RESPONSE = -1
