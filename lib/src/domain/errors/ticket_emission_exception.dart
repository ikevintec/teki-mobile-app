/// El servidor pudo registrar la venta aunque no recibimos una respuesta válida.
class TicketEmissionException implements Exception {
  final String message;
  const TicketEmissionException(this.message);
  @override
  String toString() => message;
}
