package pe.teki.app

import org.json.JSONObject

object YapePaymentParser {

    data class Payment(
        val nombrePagador: String,
        val monto: Double,
        val codigoOperacion: String,
        val tipoApp: String
    )

    private val MONTO_REGEX = Regex("""S/\.?\s*([\d.,]+)""")
    private val TRAILING_SEPARATORS_REGEX = Regex("[.,]+$")
    private val CODIGO_REGEX = Regex(
        """(?:operaci[oó]n|seguridad)\D*(\d+)""",
        RegexOption.IGNORE_CASE
    )

    private val NOMBRE_REGEX = mapOf(
        "YAPE" to Regex(
            """^(.*?)\s+te\s+(?:envió|envio|pagó|pago)(?:\s|${'$'})""",
            RegexOption.IGNORE_CASE
        ),
        "INTERBANK" to Regex(
            """^(.*?)\s+te\s+ha\s+plineado\b""",
            RegexOption.IGNORE_CASE
        ),
        "BBVA" to Regex(
            """^(.*?)\s+te\s+pline[oó](?:\s|${'$'})""",
            RegexOption.IGNORE_CASE
        )
    )

    fun parse(item: JSONObject): Payment? = parse(
        title = item.optString("title"),
        text = item.optString("text"),
        bigText = item.optString("bigText"),
        tipoApp = item.optString("tipoApp", "YAPE")
    )

    fun parse(title: String, text: String, bigText: String, tipoApp: String): Payment? {
        val tipo = tipoApp.ifEmpty { "YAPE" }.uppercase()
        val source = listOf(text, bigText, title)
            .filter { it.isNotEmpty() }
            .joinToString(" ")

        val montoRaw = MONTO_REGEX.find(source)?.groupValues?.get(1) ?: return null
        val monto = normalizeMonto(montoRaw)
        if (monto == null || monto <= 0) return null

        var nombre = NOMBRE_REGEX[tipo]
            ?.find(source.trim())
            ?.groupValues
            ?.get(1)
            ?.trim()
            ?: ""
        if (nombre.isEmpty() &&
            title.isNotEmpty() &&
            !title.lowercase().contains("yape")
        ) {
            nombre = title.trim()
        }

        var codigo = "-"
        if (tipo == "YAPE") {
            codigo = CODIGO_REGEX.find(source)?.groupValues?.get(1)?.trim() ?: ""
        }

        return Payment(
            nombrePagador = nombre,
            monto = monto,
            codigoOperacion = codigo,
            tipoApp = tipo
        )
    }

    private fun normalizeMonto(raw: String): Double? {
        var value = raw.replace(TRAILING_SEPARATORS_REGEX, "")
        if (value.contains(',') && value.contains('.')) {
            value = value.replace(",", "")
        } else if (value.contains(',')) {
            value = value.replace(',', '.')
        }
        return value.toDoubleOrNull()
    }
}
