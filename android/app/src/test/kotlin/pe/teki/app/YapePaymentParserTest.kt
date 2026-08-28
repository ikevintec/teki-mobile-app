package pe.teki.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

/** Espejo de test/services/yape_notification_parser_test.dart (ver README.md). */
class YapePaymentParserTest {

    private fun parse(
        text: String,
        title: String = "Yape!",
        tipoApp: String = "YAPE"
    ) = YapePaymentParser.parse(
        title = title,
        text = text,
        bigText = "",
        tipoApp = tipoApp
    )

    @Test
    fun `parsea el formato real de Yape con codigo de seguridad`() {
        val data = parse("Luis Alb* te envió un pago por S/ 1. El cod. de seguridad es: 984")

        assertNotNull(data)
        assertEquals("Luis Alb*", data!!.nombrePagador)
        assertEquals(1.0, data.monto, 0.0)
        assertEquals("984", data.codigoOperacion)
    }

    @Test
    fun `parsea montos con decimales y miles`() {
        assertEquals(25.50, parse("Ana te envió un pago por S/ 25,50")!!.monto, 0.0)
        assertEquals(1234.50, parse("Ana te envió un pago por S/ 1,234.50")!!.monto, 0.0)
    }

    @Test
    fun `devuelve null si no hay monto`() {
        assertNull(parse("Bienvenido a Yape"))
    }

    @Test
    fun `parsea una notificacion Plin de Interbank`() {
        val data = parse(
            "Luis Alberto Albarran Jara te ha plineado S/ 1.00",
            tipoApp = "INTERBANK"
        )

        assertEquals("Luis Alberto Albarran Jara", data?.nombrePagador)
        assertEquals(1.0, data!!.monto, 0.0)
        assertEquals("-", data.codigoOperacion)
        assertEquals("INTERBANK", data.tipoApp)
    }

    @Test
    fun `parsea una notificacion Plin de BBVA`() {
        val data = parse("LUIS ALBERTO ALBARRAN te plineó S/1 .", tipoApp = "BBVA")

        assertEquals("LUIS ALBERTO ALBARRAN", data?.nombrePagador)
        assertEquals(1.0, data!!.monto, 0.0)
        assertEquals("-", data.codigoOperacion)
        assertEquals("BBVA", data.tipoApp)
    }

    @Test
    fun `usa el title como nombre cuando el patron no coincide`() {
        val data = parse("Recibiste S/ 10.50", title = "Maria Perez")

        assertEquals("Maria Perez", data?.nombrePagador)
        assertEquals(10.50, data!!.monto, 0.0)
    }
}
