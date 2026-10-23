import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/container_loan.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/presentation/screens/container_loans/widgets/container_loan_history_sheet.dart';
import 'package:teki_app/src/presentation/screens/container_loans/widgets/container_opening_sheet.dart';
import 'package:teki_app/src/presentation/screens/container_loans/widgets/container_return_sheet.dart';
import 'package:teki_app/src/presentation/screens/container_loans/widgets/customer_filter_sheet.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/container_loans/container_loans_provider.dart';
import 'package:teki_app/src/providers/container_loans/container_loans_state.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';

/// Envases en préstamo: saldos por cliente, devoluciones e historial.
/// Con [customer] se abre filtrado por ese cliente (desde la venta).
class ContainerLoansMainScreen extends ConsumerStatefulWidget {
  final Customer? customer;

  const ContainerLoansMainScreen({super.key, this.customer});

  /// Requisitos de empresa y permiso de lectura del módulo.
  static bool isAvailable(SesionState sesion) =>
      sesion.config?.permitirRetornoEnvase == true &&
      sesion.config?.inventario == true &&
      (sesion.hasPermission('INVENTARIO_VER') ||
          sesion.hasPermission('SUPER_USUARIO'));

  @override
  ConsumerState<ContainerLoansMainScreen> createState() =>
      _ContainerLoansMainScreenState();
}

class _ContainerLoansMainScreenState
    extends ConsumerState<ContainerLoansMainScreen> {
  final ScrollController _scrollController = ScrollController();
  // Valida el flag de envases con la configuración vigente del servidor, no
  // solo con la guardada en el teléfono.
  bool _checkingConfig = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(containerLoansProvider.notifier).loadNextPage();
      }
    });
    Future.microtask(() async {
      await ref.read(authStateProvider.notifier).refreshConfigCompany();
      if (!mounted) return;
      setState(() => _checkingConfig = false);
      if (!ContainerLoansMainScreen.isAvailable(ref.read(sesionProvider))) {
        return;
      }
      ref.read(containerLoansProvider.notifier).load(customer: widget.customer);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _canReturn {
    final sesion = ref.read(sesionProvider);
    return sesion.hasPermission('INVENTARIO_AJUSTAR') ||
        sesion.hasPermission('SUPER_USUARIO');
  }

  Future<void> _pickCustomer() async {
    final selected = await CustomerFilterSheet.show(context);
    if (selected != null) {
      ref.read(containerLoansProvider.notifier).load(customer: selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(sesionProvider);
    // Mantiene vivo el proveedor autoDispose mientras se valida la configuración.
    // La consulta inicial puede terminar antes del siguiente build.
    final loans = ref.watch(containerLoansProvider);
    const title = 'Envases pendientes';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CustomAppBar(navigateName: title),
      ),
      body: _checkingConfig
          ? const Center(
              child: CircularProgressIndicator(
                color: ColorSchema.primaryColor,
                strokeWidth: 2,
              ),
            )
          : !ContainerLoansMainScreen.isAvailable(sesion)
          ? _message(
              Icons.lock_outline,
              'Módulo no disponible',
              'Requiere retorno de envases e inventario habilitados en la '
                  'empresa y permiso para ver inventario.',
            )
          : Column(
              children: [
                _buildFilters(loans, sesion),
                Expanded(
                  child: RefreshIndicator(
                    color: ColorSchema.primaryColor,
                    onRefresh: () =>
                        ref.read(containerLoansProvider.notifier).load(),
                    child: _buildBody(loans),
                  ),
                ),
              ],
            ),
      floatingActionButton:
          !_checkingConfig &&
              ContainerLoansMainScreen.isAvailable(sesion) &&
              _canReturn
          ? FloatingActionButton.extended(
              onPressed: loans.isSaving
                  ? null
                  : () => ContainerOpeningSheet.show(
                      context,
                      customer: ref.read(containerLoansProvider).customer,
                    ),
              backgroundColor: ColorSchema.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Registrar pendientes',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  Future<void> _cancelOpening(ContainerLoan loan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Anular registro de envases'),
        content: Text(
          loan.stockAlreadyDeducted == true
              ? 'Se eliminará este saldo pendiente. El inventario no cambiará.'
              : 'Se eliminará este saldo pendiente y se repondrán los vacíos '
                    'descontados al registrarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Anular registro'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(containerLoansProvider.notifier).cancelOpening(loan);
      successNotification('Registro anulado. Se conserva su historial.');
    } catch (error) {
      errorNotification(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget _buildFilters(ContainerLoansState state, SesionState sesion) {
    final notifier = ref.read(containerLoansProvider.notifier);
    final offices = sesion.offices ?? const [];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Controla lo que cada cliente tiene por devolver.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.person_search_outlined),
            title: Text(state.customer?.razonSocial ?? 'Todos los clientes'),
            trailing: state.customer == null
                ? const Icon(Icons.chevron_right)
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => notifier.load(customer: null),
                  ),
            onTap: _pickCustomer,
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    isExpanded: true,
                    value: state.officeId,
                    hint: const Text('Todas las sedes'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todas las sedes'),
                      ),
                      for (final office in offices)
                        DropdownMenuItem<int?>(
                          value: office.id,
                          child: Text(
                            office.nombre ?? '-',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (id) => notifier.load(officeId: id),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Solo pendientes', style: TextStyle(fontSize: 13)),
              Switch(
                value: state.pending,
                activeThumbColor: ColorSchema.primaryColor,
                onChanged: (value) => notifier.load(pending: value),
              ),
            ],
          ),
          for (final total in state.totals)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${formatDouble(total.quantity)} '
                '${total.quantity == 1 ? 'envase pendiente' : 'envases pendientes'}'
                '\nValor de referencia: '
                '${formatExchange(moneda: total.currency ?? 'PEN')}'
                '${total.value.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ContainerLoansState state) {
    if (state.isLoading && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 150),
          Center(
            child: CircularProgressIndicator(
              color: ColorSchema.primaryColor,
              strokeWidth: 2,
            ),
          ),
        ],
      );
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return _message(
        Icons.cloud_off_rounded,
        'No se pudieron cargar',
        state.errorMessage!,
        onRetry: () => ref.read(containerLoansProvider.notifier).load(),
      );
    }
    if (state.items.isEmpty) {
      return _message(
        Icons.recycling,
        state.pending ? 'Sin envases pendientes' : 'Sin registros de envases',
        'Los envases prestados en ventas aparecerán aquí. Si tus clientes '
        'ya tienen envases, usa «Registrar pendientes».',
      );
    }
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      itemCount: state.items.length + (state.last ? 0 : 1),
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: CircularProgressIndicator(
                color: ColorSchema.primaryColor,
                strokeWidth: 2,
              ),
            ),
          );
        }
        return _LoanCard(
          loan: state.items[index],
          canReturn: _canReturn,
          saving: state.isSaving,
          onReturn: () =>
              ContainerReturnSheet.show(context, state.items[index]),
          onHistory: () =>
              ContainerLoanHistorySheet.show(context, state.items[index]),
          onCancelOpening: () => _cancelOpening(state.items[index]),
        );
      },
    );
  }

  Widget _message(
    IconData icon,
    String title,
    String detail, {
    VoidCallback? onRetry,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      children: [
        const SizedBox(height: 110),
        Icon(
          icon,
          size: 56,
          color: ColorSchema.primaryColor.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        if (onRetry != null)
          Center(
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ),
      ],
    );
  }
}

class _LoanCard extends StatelessWidget {
  final ContainerLoan loan;
  final bool canReturn;
  final bool saving;
  final VoidCallback onReturn;
  final VoidCallback onHistory;
  final VoidCallback onCancelOpening;

  const _LoanCard({
    required this.loan,
    required this.canReturn,
    required this.saving,
    required this.onReturn,
    required this.onHistory,
    required this.onCancelOpening,
  });

  @override
  Widget build(BuildContext context) {
    final date = loan.loanedOn ?? loan.createdOn;
    final moneda = formatExchange(moneda: loan.currency ?? 'PEN');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loan.customer ?? '-',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(loan.container ?? '-', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            loan.cancelled
                ? 'Registro anulado'
                : '${formatDouble(loan.pendingQuantity)} por devolver',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: loan.cancelled ? Colors.grey : ColorSchema.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${formatDouble(loan.quantity)} ${loan.quantity == 1 ? 'entregado' : 'entregados'} · ${formatDouble(loan.returnedQuantity)} ${loan.returnedQuantity == 1 ? 'devuelto' : 'devueltos'}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            [
              loan.office,
              loan.openingBalance ? 'Registro de pendientes' : loan.ticket,
              if (date != null) DateFormat('dd/MM/yyyy').format(date),
            ].whereType<String>().join(' · '),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'Valor de referencia: $moneda${loan.pendingValue.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (canReturn && loan.pendingQuantity > 0)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorSchema.primaryColor,
                    minimumSize: const Size(44, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: saving ? null : onReturn,
                  icon: const Icon(Icons.keyboard_return, size: 18),
                  label: const Text('Recibir envases'),
                ),
              TextButton(onPressed: onHistory, child: const Text('Historial')),
              if (canReturn &&
                  loan.openingBalance &&
                  !loan.cancelled &&
                  loan.returnedQuantity == 0)
                TextButton(
                  onPressed: saving ? null : onCancelOpening,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Anular registro'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
