import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetail.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetailGroupOption.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetailPreparationOption.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/orderRestaurant.dart';
import 'package:teki_app/src/providers/restaurant/restaurant_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/notifications.dart';

/// Screen shown exclusively from a [dish_desk_ready] push notification.
/// Displays the specific ready item and a single "Servir" button.
/// After serving, pops back to the mesas screen already in the stack.
class DishDeskReadyScreen extends ConsumerStatefulWidget {
  final int commandId;
  final int itemId;

  const DishDeskReadyScreen({
    super.key,
    required this.commandId,
    required this.itemId,
  });

  /// Indica si esta pantalla está actualmente en la pila de navegación.
  /// Usado por [NotificationService] para hacer pop antes de apilar una nueva.
  static bool isVisible = false;

  @override
  ConsumerState<DishDeskReadyScreen> createState() => _DishDeskReadyScreenState();
}

class _DishDeskReadyScreenState extends ConsumerState<DishDeskReadyScreen> {
  bool _isServing = false;

  @override
  void initState() {
    super.initState();
    DishDeskReadyScreen.isVisible = true;
  }

  @override
  void dispose() {
    DishDeskReadyScreen.isVisible = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restaurantProvider);

    CommandDetail? item;
    Command? command;
    OrderRestaurant? order;

    outer:
    for (final o in state.orders) {
      for (final cmd in o.comandas ?? []) {
        if (cmd.id == widget.commandId) {
          command = cmd;
          order = o;
          for (final it in cmd.items ?? []) {
            if (it.id == widget.itemId) {
              item = it;
              break outer;
            }
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: ColorSchema.primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Plato listo para servir',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      body: state.isLoading && item == null
          ? const Center(
              child: CircularProgressIndicator(color: ColorSchema.primaryColor),
            )
          : item == null
              ? _ItemNotFound(onBack: () => Get.back())
              : _ItemReadyBody(
                  item: item,
                  command: command,
                  order: order,
                  isServing: _isServing,
                  onServir: _servir,
                ),
    );
  }

  Future<void> _servir() async {
    if (_isServing) return;
    setState(() => _isServing = true);
    try {
      await ref.read(restaurantProvider.notifier).updateCommandItemStatus(
            widget.commandId,
            widget.itemId,
            'DESPACHADO',
          );
      successNotification('Plato servido correctamente');
      Get.back();
    } catch (e) {
      errorNotification('Error al servir el plato');
      setState(() => _isServing = false);
    }
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _ItemReadyBody extends StatelessWidget {
  final CommandDetail item;
  final Command? command;
  final OrderRestaurant? order;
  final bool isServing;
  final VoidCallback onServir;

  const _ItemReadyBody({
    required this.item,
    required this.command,
    required this.order,
    required this.isServing,
    required this.onServir,
  });

  @override
  Widget build(BuildContext context) {
    final grupoOpciones =
        (item.grupoProductoOpciones ?? []).where((o) => o.eliminado != true).toList();
    final preparaciones =
        (item.preparacionProductoOpciones ?? []).where((o) => o.eliminado != true).toList();
    final total = (item.precioVenta ?? 0) * (item.cantidad ?? 1);
    final mesaNumero = order?.mesa?.numero?.toString() ?? order?.mesa?.id?.toString();
    final clienteNombre = order?.cliente?.razonSocial;
    final imagenUrl = item.producto?.imagenUrl;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Ready banner ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF9A825), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9A825),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.room_service_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plato listo en cocina',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF7B5800),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Confirma el servicio para marcarlo como despachado',
                              style: TextStyle(fontSize: 12, color: Color(0xFF9B6F00)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Mesa / Cliente info ───────────────────────────────────
                if (mesaNumero != null || clienteNombre != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        if (mesaNumero != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E5F5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCE93D8)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.table_restaurant_rounded,
                                    size: 16, color: Color(0xFF7B1FA2)),
                                const SizedBox(width: 6),
                                Text(
                                  'Mesa $mesaNumero',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF7B1FA2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (clienteNombre != null)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF90CAF9)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_rounded,
                                      size: 16, color: Color(0xFF1565C0)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      clienteNombre,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1565C0),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // ── Item card ─────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header comanda
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(14),
                            topRight: Radius.circular(14),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.restaurant_menu_rounded,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              command?.numeroComanda != null
                                  ? 'Comanda #${command!.numeroComanda}'
                                  : 'Detalle del plato',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Item details
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name + quantity (con thumbnail a la izquierda)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Thumbnail
                                if (imagenUrl != null && imagenUrl.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: Image.network(
                                          imagenUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (_, child, progress) =>
                                              progress == null
                                                  ? child
                                                  : Container(
                                                      color: const Color(0xFFF5F5F5),
                                                      child: const Center(
                                                        child: SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 1.5,
                                                            color: ColorSchema.primaryColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                          errorBuilder: (_, _, _) => Container(
                                            color: const Color(0xFFF5F5F5),
                                            child: Icon(Icons.broken_image_rounded,
                                                size: 24,
                                                color: Colors.grey.shade400),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9A825)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${(item.cantidad ?? 1).toInt()}x',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFF9A825),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.producto?.nombre ?? '-',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Price
                            Row(
                              children: [
                                const Icon(Icons.attach_money_rounded,
                                    size: 16, color: Colors.grey),
                                Text(
                                  'S/. ${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),

                            // Nota
                            if (item.nota != null && item.nota!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.notes_rounded,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.nota!,
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Group options
                            if (grupoOpciones.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const _SectionLabel(label: 'OPCIONES'),
                              const SizedBox(height: 6),
                              ...grupoOpciones.map((o) => _GroupOptionRow(option: o)),
                            ],

                            // Preparations
                            if (preparaciones.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const _SectionLabel(label: 'PREPARACIONES'),
                              const SizedBox(height: 6),
                              ..._buildPreparaciones(preparaciones),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Servir button ─────────────────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isServing ? null : onServir,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFF1565C0).withValues(alpha: 0.7),
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: isServing ? 0 : 3,
                  shadowColor: const Color(0xFF1565C0).withValues(alpha: 0.4),
                ),
                child: isServing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Sirviendo...',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Servir plato',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPreparaciones(List<CommandDetailPreparationOption> preps) {
    final Map<String, List<CommandDetailPreparationOption>> grouped = {};
    for (final p in preps) {
      final key = p.nombrePreparacion ?? 'Preparación';
      grouped.putIfAbsent(key, () => []).add(p);
    }
    return grouped.entries
        .map((e) => _PreparationGroup(nombre: e.key, opciones: e.value))
        .toList();
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── Group option row ─────────────────────────────────────────────────────────

class _GroupOptionRow extends StatelessWidget {
  final CommandDetailGroupOption option;
  const _GroupOptionRow({required this.option});

  @override
  Widget build(BuildContext context) {
    final name = option.nombreOpcion ?? option.nombreGrupo ?? '-';
    final qty = (option.cantidad ?? 1).toInt();
    final price = (option.precio ?? 0) * (option.cantidad ?? 1);

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_right_rounded,
              size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${qty}x $name',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          if (price > 0)
            Text(
              'S/. ${price.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }
}

// ─── Preparation group ────────────────────────────────────────────────────────

class _PreparationGroup extends StatelessWidget {
  final String nombre;
  final List<CommandDetailPreparationOption> opciones;

  const _PreparationGroup({required this.nombre, required this.opciones});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tune_rounded, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                children: [
                  TextSpan(
                    text: '$nombre: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: opciones.map((o) => o.nombreOpcion ?? '-').join(', '),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Item not found ───────────────────────────────────────────────────────────

class _ItemNotFound extends StatelessWidget {
  final VoidCallback onBack;
  const _ItemNotFound({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No se encontró el plato',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Es posible que ya haya sido servido',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorSchema.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ir a Mesas'),
          ),
        ],
      ),
    );
  }
}
