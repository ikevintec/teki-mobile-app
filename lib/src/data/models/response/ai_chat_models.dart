/// Modelos del asistente Teki AI — espejo de las interfaces del servicio
/// ai-chat.service de la web (misma respuesta estructurada del teki-ai).
class RespuestaKpi {
  final String etiqueta;
  final String valor;
  final String? delta;

  const RespuestaKpi({required this.etiqueta, required this.valor, this.delta});

  factory RespuestaKpi.fromJson(Map<String, dynamic> json) => RespuestaKpi(
        etiqueta: json['etiqueta'] ?? '',
        valor: json['valor']?.toString() ?? '',
        delta: json['delta']?.toString(),
      );

  bool get deltaNegativo => (delta ?? '').trim().startsWith('-');
}

class RespuestaTabla {
  final String? titulo;
  final List<String> columnas;
  final List<List<String>> filas;
  final int? totalFilas;

  const RespuestaTabla({
    this.titulo,
    required this.columnas,
    required this.filas,
    this.totalFilas,
  });

  factory RespuestaTabla.fromJson(Map<String, dynamic> json) => RespuestaTabla(
        titulo: json['titulo'],
        columnas:
            (json['columnas'] as List? ?? []).map((e) => '$e').toList(),
        filas: (json['filas'] as List? ?? [])
            .map((f) => (f as List).map((c) => '${c ?? ''}').toList())
            .toList(),
        totalFilas: (json['totalFilas'] as num?)?.toInt(),
      );
}

class SerieGrafico {
  final String nombre;
  final List<double> datos;

  const SerieGrafico({required this.nombre, required this.datos});

  factory SerieGrafico.fromJson(Map<String, dynamic> json) => SerieGrafico(
        nombre: json['nombre'] ?? '',
        datos: (json['datos'] as List? ?? [])
            .map((e) => ((e ?? 0) as num).toDouble())
            .toList(),
      );
}

class RespuestaGrafico {
  final String tipo; // bar | line | pie
  final String? titulo;
  final List<String> etiquetas;
  final List<SerieGrafico> series;

  const RespuestaGrafico({
    required this.tipo,
    this.titulo,
    required this.etiquetas,
    required this.series,
  });

  factory RespuestaGrafico.fromJson(Map<String, dynamic> json) =>
      RespuestaGrafico(
        tipo: json['tipo'] ?? 'bar',
        titulo: json['titulo'],
        etiquetas:
            (json['etiquetas'] as List? ?? []).map((e) => '$e').toList(),
        series: (json['series'] as List? ?? [])
            .map((e) => SerieGrafico.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class RespuestaAccion {
  final String label;
  final String ruta;

  const RespuestaAccion({required this.label, required this.ruta});

  factory RespuestaAccion.fromJson(Map<String, dynamic> json) =>
      RespuestaAccion(label: json['label'] ?? '', ruta: json['ruta'] ?? '');
}

class RespuestaIa {
  final String texto;
  final List<RespuestaKpi> kpis;
  final RespuestaTabla? tabla;
  final RespuestaGrafico? grafico;
  final List<RespuestaAccion> acciones;
  final List<String> sugerencias;

  const RespuestaIa({
    required this.texto,
    this.kpis = const [],
    this.tabla,
    this.grafico,
    this.acciones = const [],
    this.sugerencias = const [],
  });

  factory RespuestaIa.fromJson(Map<String, dynamic> json) => RespuestaIa(
        texto: json['texto'] ?? '',
        kpis: (json['kpis'] as List? ?? [])
            .map((e) => RespuestaKpi.fromJson(e as Map<String, dynamic>))
            .toList(),
        tabla: json['tabla'] == null
            ? null
            : RespuestaTabla.fromJson(json['tabla'] as Map<String, dynamic>),
        grafico: json['grafico'] == null
            ? null
            : RespuestaGrafico.fromJson(
                json['grafico'] as Map<String, dynamic>),
        acciones: (json['acciones'] as List? ?? [])
            .map((e) => RespuestaAccion.fromJson(e as Map<String, dynamic>))
            .toList(),
        sugerencias:
            (json['sugerencias'] as List? ?? []).map((e) => '$e').toList(),
      );
}

class ConversacionIa {
  final int id;
  final String? title;

  const ConversacionIa({required this.id, this.title});

  factory ConversacionIa.fromJson(Map<String, dynamic> json) =>
      ConversacionIa(id: (json['id'] as num).toInt(), title: json['title']);
}

class MensajeGuardadoIa {
  final int id;
  final String role;
  final dynamic content;

  const MensajeGuardadoIa({
    required this.id,
    required this.role,
    required this.content,
  });

  factory MensajeGuardadoIa.fromJson(Map<String, dynamic> json) =>
      MensajeGuardadoIa(
        id: (json['id'] as num).toInt(),
        role: json['role'] ?? 'assistant',
        content: json['content'],
      );
}

/// Evento del stream SSE del teki-ai (mismos tipos que consume la web).
class AiChatEvent {
  final String type; // tool | respuesta | text | error | meta | saved
  final String? name;
  final RespuestaIa? respuesta;
  final String? content;
  final String? message;
  final int? conversationId;
  final int? messageId;

  const AiChatEvent._({
    required this.type,
    this.name,
    this.respuesta,
    this.content,
    this.message,
    this.conversationId,
    this.messageId,
  });

  static AiChatEvent? fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'tool':
        return AiChatEvent._(type: 'tool', name: json['name'] ?? '');
      case 'respuesta':
        return AiChatEvent._(
          type: 'respuesta',
          respuesta:
              RespuestaIa.fromJson(json['data'] as Map<String, dynamic>? ?? {}),
        );
      case 'text':
        return AiChatEvent._(type: 'text', content: json['content'] ?? '');
      case 'error':
        return AiChatEvent._(type: 'error', message: json['message'] ?? '');
      case 'meta':
        return AiChatEvent._(
          type: 'meta',
          conversationId: (json['conversationId'] as num?)?.toInt(),
        );
      case 'saved':
        return AiChatEvent._(
          type: 'saved',
          messageId: (json['messageId'] as num?)?.toInt(),
        );
      default:
        return null;
    }
  }
}
