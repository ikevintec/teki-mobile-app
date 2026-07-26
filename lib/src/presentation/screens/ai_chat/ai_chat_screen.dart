import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart' hide Trans;
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/response/ai_chat_models.dart';
import 'package:teki_app/src/presentation/screens/ai_chat/widgets/ai_orb_button.dart';
import 'package:teki_app/src/providers/ai_chat/ai_chat_provider.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/routes/app_routes.dart';

/// Pantalla del asistente Teki AI — espejo del panel app-ai-chat de la web
/// (estilo Apple Intelligence: marco de gradiente giratorio, shimmer,
/// respuestas con KPIs/tabla/gráfico/acciones/sugerencias).
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen>
    with TickerProviderStateMixin {
  late final AnimationController _frameSpin;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  static const _suggestions = [
    '¿Cuánto vendí este mes?',
    '¿Cuánto me deben mis clientes?',
    'Resumen de caja de la semana',
    '¿Qué categorías vendo más?',
  ];

  bool get _puedeUsarIa {
    final sesion = ref.read(sesionProvider);
    return sesion.hasPermission('PERMITIR_CONSULTAS_IA') ||
        sesion.hasPermission('SUPER_USUARIO');
  }

  @override
  void initState() {
    super.initState();
    _frameSpin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    if (_puedeUsarIa) {
      Future.microtask(() => ref.read(aiChatProvider.notifier).abrir());
    }
  }

  @override
  void dispose() {
    _frameSpin.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _send([String? explicit]) {
    final text = (explicit ?? _inputController.text).trim();
    if (text.isEmpty) return;
    if (explicit == null) _inputController.clear();
    ref.read(aiChatProvider.notifier).send(text);
  }

  /// Traducción de rutas web del asistente a rutas del móvil; null = sin
  /// equivalente (el botón de acción no se muestra).
  String? _rutaMovil(String rutaWeb) {
    if (rutaWeb.startsWith('/ventas')) return AppRoutes.comprobantesVer;
    if (rutaWeb.startsWith('/cuentas-por-cobrar')) {
      return AppRoutes.accountsReceivable;
    }
    if (rutaWeb.startsWith('/cuentas-por-pagar')) {
      return AppRoutes.accountsPayable;
    }
    if (rutaWeb.startsWith('/productos')) return AppRoutes.products;
    if (rutaWeb.startsWith('/inventario')) return AppRoutes.inventory;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatProvider);
    final companyName =
        ref.watch(sesionProvider).company?.nombreComercial ?? 'Teki';
    ref.listen(aiChatProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F8),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _frameSpin,
          builder: (context, child) => Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: GradientBoxBorder(
                angle: _frameSpin.value * 2 * math.pi,
                width: state.thinking ? 2.6 : 1.4,
                opacity: state.thinking ? 1 : 0.55,
              ),
            ),
            child: child,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Tintes del marco traslucidos dentro del panel, girando con
                // él (paridad web: el glow cónico se ve a través del glass).
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _frameSpin,
                    builder: (context, _) => DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: SweepGradient(
                          colors: const [...kAiColors, Color(0xFF0A84FF)],
                          transform: GradientRotation(
                              _frameSpin.value * 2 * math.pi),
                        ),
                      ),
                    ),
                  ),
                ),
                // Velo glass que suaviza los tintes a pastel.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.90),
                          Colors.white.withValues(alpha: 0.86),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    _buildHeader(companyName),
                    Expanded(
                      child: _puedeUsarIa
                          ? _buildMessages(state)
                          : _buildBloqueado(),
                    ),
                    _buildInputBar(state),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String companyName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [kAiColors0, kAiColors1]),
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$companyName AI',
                    style: GoogleFonts.roboto(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                Text('Tu asistente del negocio',
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (_puedeUsarIa) ...[
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 20),
              color: Colors.grey.shade700,
              tooltip: 'Nueva conversación',
              onPressed: () =>
                  ref.read(aiChatProvider.notifier).nuevaConversacion(),
            ),
            IconButton(
              icon: const Icon(Icons.history_rounded, size: 20),
              color: Colors.grey.shade700,
              tooltip: 'Historial',
              onPressed: _showHistorial,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            color: Colors.grey.shade700,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showHistorial() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final st = ref.read(aiChatProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text('Conversaciones',
                  style: GoogleFonts.roboto(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              if (st.conversaciones.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Aún no tienes conversaciones guardadas.',
                      style: GoogleFonts.roboto(
                          fontSize: 13, color: Colors.grey.shade600)),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final cv in st.conversaciones)
                        ListTile(
                          dense: true,
                          leading: Icon(Icons.chat_bubble_outline_rounded,
                              size: 18,
                              color: cv.id == st.conversationId
                                  ? kAiColors0
                                  : Colors.grey.shade500),
                          title: Text(
                            cv.title ?? 'Conversación',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 13.5,
                              fontWeight: cv.id == st.conversationId
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            ref
                                .read(aiChatProvider.notifier)
                                .abrirConversacion(cv.id);
                          },
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBloqueado() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  kAiColors0.withValues(alpha: 0.15),
                  kAiColors1.withValues(alpha: 0.15),
                ]),
              ),
              child: Icon(Icons.lock_outline_rounded,
                  size: 28, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            Text('Inteligencia artificial no disponible',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'No cuentas con el permiso para usar la inteligencia artificial. Solicítaselo a un administrador de tu empresa.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                  fontSize: 13, color: Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(AiChatState state) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      children: [
        if (state.messages.isEmpty && !state.thinking) _buildWelcome(),
        for (int i = 0; i < state.messages.length; i++)
          _buildMessage(i, state.messages[i]),
        if (state.thinking)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: _ShimmerText(state.toolStatus ?? 'Pensando…'),
          ),
      ],
    );
  }

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const AiOrbButton(onTap: _noop, size: 62),
          const SizedBox(height: 14),
          Text('Hola 👋',
              style: GoogleFonts.roboto(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Pregúntame por tus ventas, cobros o caja,\nen lenguaje natural.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                  fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final s in _suggestions) _chip(s, () => _send(s)),
            ],
          ),
        ],
      ),
    );
  }

  static void _noop() {}

  Widget _chip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            kAiColors0.withValues(alpha: 0.1),
            kAiColors1.withValues(alpha: 0.1),
          ]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kAiColors0.withValues(alpha: 0.25)),
        ),
        child: Text(label,
            style: GoogleFonts.roboto(
                fontSize: 12.5,
                color: const Color(0xFF34406B),
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildMessage(int index, AiChatMessage m) {
    if (m.role == 'user') {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            gradient:
                const LinearGradient(colors: [kAiColors0, Color(0xFF6A5CFF)]),
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomRight: const Radius.circular(4),
            ),
          ),
          child: Text(m.content,
              style: GoogleFonts.roboto(fontSize: 13.5, color: Colors.white)),
        ),
      );
    }

    final r = m.payload;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: const BoxConstraints(maxWidth: 330),
        decoration: BoxDecoration(
          color: m.error
              ? const Color(0xFFFDECEC)
              : Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
          border: Border.all(
              color:
                  m.error ? const Color(0xFFF5B5B5) : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MarkdownLigero(m.content,
                color: m.error ? const Color(0xFFB4232A) : Colors.black87),
            if (r != null) ...[
              if (r.kpis.isNotEmpty) _buildKpis(r.kpis),
              if (r.grafico != null) _buildGrafico(r.grafico!),
              if (r.tabla != null) _buildTabla(r.tabla!),
              if (r.acciones.isNotEmpty) _buildAcciones(r.acciones),
              if (r.sugerencias.isNotEmpty) _buildSugerencias(r.sugerencias),
            ],
            if (m.messageId != null && !m.error) _buildFeedback(index, m),
          ],
        ),
      ),
    );
  }

  Widget _buildKpis(List<RespuestaKpi> kpis) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final k in kpis)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  kAiColors0.withValues(alpha: 0.08),
                  kAiColors1.withValues(alpha: 0.08),
                ]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(k.etiqueta,
                      style: GoogleFonts.roboto(
                          fontSize: 10.5, color: Colors.grey.shade600)),
                  Text(k.valor,
                      style: GoogleFonts.roboto(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                  if (k.delta != null)
                    Text(k.delta!,
                        style: GoogleFonts.roboto(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: k.deltaNegativo
                              ? const Color(0xFFC62828)
                              : const Color(0xFF2E7D32),
                        )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrafico(RespuestaGrafico g) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (g.titulo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(g.titulo!,
                  style: GoogleFonts.roboto(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          SizedBox(height: 180, child: _AiChart(grafico: g)),
        ],
      ),
    );
  }

  Widget _buildTabla(RespuestaTabla t) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (t.titulo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(t.titulo!,
                  style: GoogleFonts.roboto(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 32,
              dataRowMinHeight: 30,
              dataRowMaxHeight: 36,
              horizontalMargin: 8,
              columnSpacing: 18,
              headingTextStyle: GoogleFonts.roboto(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700),
              dataTextStyle:
                  GoogleFonts.roboto(fontSize: 12, color: Colors.black87),
              columns: [
                for (final c in t.columnas) DataColumn(label: Text(c)),
              ],
              rows: [
                for (final fila in t.filas)
                  DataRow(cells: [for (final c in fila) DataCell(Text(c))]),
              ],
            ),
          ),
          if ((t.totalFilas ?? 0) > t.filas.length)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Mostrando ${t.filas.length} de ${t.totalFilas}',
                  style: GoogleFonts.roboto(
                      fontSize: 10.5, color: Colors.grey.shade500)),
            ),
        ],
      ),
    );
  }

  Widget _buildAcciones(List<RespuestaAccion> acciones) {
    final visibles = acciones
        .map((a) => (a, _rutaMovil(a.ruta)))
        .where((par) => par.$2 != null)
        .toList();
    if (visibles.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (a, ruta) in visibles)
            GestureDetector(
              onTap: () => Get.toNamed(ruta!),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [kAiColors0, Color(0xFF6A5CFF)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(a.label,
                        style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 13, color: Colors.white),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSugerencias(List<String> sugerencias) {
    final thinking = ref.read(aiChatProvider).thinking;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in sugerencias)
            _chip(s, thinking ? _noop : () => _send(s)),
        ],
      ),
    );
  }

  Widget _buildFeedback(int index, AiChatMessage m) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final rating in [1, -1])
            GestureDetector(
              onTap: m.feedback != null
                  ? null
                  : () =>
                      ref.read(aiChatProvider.notifier).darFeedback(index, rating),
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  rating == 1
                      ? Icons.thumb_up_alt_outlined
                      : Icons.thumb_down_alt_outlined,
                  size: 15,
                  color: m.feedback == rating
                      ? kAiColors0
                      : Colors.grey.shade400,
                ),
              ),
            ),
          if (m.feedback != null)
            Text('¡Gracias!',
                style: GoogleFonts.roboto(
                    fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildInputBar(AiChatState state) {
    final habilitado = _puedeUsarIa && !state.thinking;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.7))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: habilitado,
              maxLength: 2000,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: GoogleFonts.roboto(fontSize: 13.5),
              decoration: InputDecoration(
                counterText: '',
                hintText: _puedeUsarIa
                    ? 'Pregunta lo que quieras…'
                    : 'Sin permiso para usar la IA',
                hintStyle: GoogleFonts.roboto(
                    fontSize: 13, color: Colors.grey.shade400),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF4F4FA),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: habilitado ? _send : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: habilitado
                    ? const LinearGradient(
                        colors: [kAiColors0, Color(0xFF6A5CFF)])
                    : LinearGradient(colors: [
                        Colors.grey.shade300,
                        Colors.grey.shade300,
                      ]),
              ),
              child: const Icon(Icons.arrow_upward_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

const kAiColors0 = Color(0xFF0A84FF);
const kAiColors1 = Color(0xFFBF5AF2);

/// Borde de gradiente cónico giratorio (el marco luminoso del panel web).
class GradientBoxBorder extends BoxBorder {
  final double angle;
  final double width;
  final double opacity;

  const GradientBoxBorder({
    required this.angle,
    required this.width,
    required this.opacity,
  });

  @override
  BorderSide get top => BorderSide.none;

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  bool get isUniform => true;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = SweepGradient(
        colors: [
          for (final c in kAiColors) c.withValues(alpha: opacity),
          kAiColors.first.withValues(alpha: opacity),
        ],
        transform: GradientRotation(angle),
      ).createShader(rect);
    final rrect = (borderRadius ?? BorderRadius.circular(22))
        .toRRect(rect)
        .deflate(width / 2);
    canvas.drawRRect(rrect, paint);
  }

  @override
  ShapeBorder scale(double t) => this;
}

/// Texto con barrido de brillo (el .ai-shimmer del web: "Pensando…").
class _ShimmerText extends StatefulWidget {
  final String text;

  const _ShimmerText(this.text);

  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat();
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sweep,
      builder: (context, _) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: const [Color(0xFF8E8E93), kAiColors0, kAiColors1, Color(0xFF8E8E93)],
          stops: const [0.2, 0.45, 0.55, 0.8],
          transform: _SlideGradient(_sweep.value),
        ).createShader(bounds),
        child: Text(
          widget.text,
          style: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double t;

  const _SlideGradient(this.t);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues((t * 2 - 1) * bounds.width * 2, 0, 0);
}

/// Markdown mínimo del asistente: **negritas**, "- listas" y saltos de línea.
class _MarkdownLigero extends StatelessWidget {
  final String text;
  final Color color;

  const _MarkdownLigero(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (line.startsWith('- ')) {
        spans.add(const TextSpan(text: '•  '));
        line = line.substring(2);
      }
      // Negritas **texto**
      final regex = RegExp(r'\*\*(.+?)\*\*');
      int last = 0;
      for (final m in regex.allMatches(line)) {
        if (m.start > last) {
          spans.add(TextSpan(text: line.substring(last, m.start)));
        }
        spans.add(TextSpan(
            text: m.group(1),
            style: const TextStyle(fontWeight: FontWeight.w700)));
        last = m.end;
      }
      if (last < line.length) {
        spans.add(TextSpan(text: line.substring(last)));
      }
      if (i < lines.length - 1) spans.add(const TextSpan(text: '\n'));
    }
    return RichText(
      text: TextSpan(
        style: GoogleFonts.roboto(fontSize: 13.5, color: color, height: 1.45),
        children: spans,
      ),
    );
  }
}

/// Gráfico del asistente con fl_chart (bar/line/pie, paleta del web).
class _AiChart extends StatelessWidget {
  final RespuestaGrafico grafico;

  const _AiChart({required this.grafico});

  static const _colors = [
    Color(0xFF0A84FF),
    Color(0xFFBF5AF2),
    Color(0xFFFF375F),
    Color(0xFFFF9F0A),
    Color(0xFF64D2FF),
    Color(0xFF30D158),
  ];

  @override
  Widget build(BuildContext context) {
    switch (grafico.tipo) {
      case 'pie':
        return _pie();
      case 'line':
        return _line();
      default:
        return _bar();
    }
  }

  Widget _etiqueta(double value, TitleMeta meta) {
    final i = value.toInt();
    if (i < 0 || i >= grafico.etiquetas.length) return const SizedBox.shrink();
    var label = grafico.etiquetas[i];
    if (label.length > 7) label = '${label.substring(0, 6)}…';
    return SideTitleWidget(
      meta: meta,
      child: Text(label, style: const TextStyle(fontSize: 9)),
    );
  }

  Widget _bar() {
    final serie = grafico.series.isNotEmpty
        ? grafico.series.first
        : const SerieGrafico(nombre: '', datos: []);
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true, reservedSize: 38,
                  getTitlesWidget: _leftTitle)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true, getTitlesWidget: _etiqueta, reservedSize: 24),
          ),
        ),
        barGroups: [
          for (int i = 0; i < serie.datos.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: serie.datos[i],
                color: _colors[0],
                width: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
        ],
      ),
    );
  }

  static Widget _leftTitle(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      child: Text(
        value >= 1000 ? '${(value / 1000).toStringAsFixed(0)}k' : '${value.toInt()}',
        style: const TextStyle(fontSize: 9),
      ),
    );
  }

  Widget _line() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true, reservedSize: 38,
                  getTitlesWidget: _leftTitle)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true, getTitlesWidget: _etiqueta, reservedSize: 24),
          ),
        ),
        lineBarsData: [
          for (int s = 0; s < grafico.series.length; s++)
            LineChartBarData(
              spots: [
                for (int i = 0; i < grafico.series[s].datos.length; i++)
                  FlSpot(i.toDouble(), grafico.series[s].datos[i]),
              ],
              color: _colors[s % _colors.length],
              barWidth: 2,
              isCurved: true,
              curveSmoothness: 0.35,
              dotData: const FlDotData(show: false),
            ),
        ],
      ),
    );
  }

  Widget _pie() {
    final serie = grafico.series.isNotEmpty
        ? grafico.series.first
        : const SerieGrafico(nombre: '', datos: []);
    final total = serie.datos.fold<double>(0, (a, b) => a + b);
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 26,
              sections: [
                for (int i = 0; i < serie.datos.length; i++)
                  PieChartSectionData(
                    value: serie.datos[i],
                    color: _colors[i % _colors.length],
                    radius: 52,
                    title: total > 0
                        ? '${(serie.datos[i] / total * 100).round()}%'
                        : '',
                    titleStyle: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0;
                i < grafico.etiquetas.length && i < serie.datos.length;
                i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: _colors[i % _colors.length],
                            shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 90),
                      child: Text(grafico.etiquetas[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9.5)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
