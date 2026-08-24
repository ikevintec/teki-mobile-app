import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/yape/pago_yape.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/providers/yape/pago_yape_provider.dart';
import 'package:teki_app/src/utils/constants.dart';

class PagoYapeScreen extends ConsumerStatefulWidget {
  const PagoYapeScreen({super.key});

  @override
  ConsumerState<PagoYapeScreen> createState() => _PagoYapeScreenState();
}

class _PagoYapeScreenState extends ConsumerState<PagoYapeScreen> {
  final ScrollController _scrollController = ScrollController();
  static final NumberFormat _amountFormat = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/ ',
    decimalDigits: 2,
  );
  static final DateFormat _dateFormat = DateFormat(
    'dd/MM/yyyy · hh:mm a',
    'es_PE',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pagoYapeListProvider.notifier).loadFirstPage();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      ref.read(pagoYapeListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pagoYapeListProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: 'Yapes'),
      ),
      body: Column(
        children: [
          _summary(state.totalElements),
          Expanded(child: _content(state)),
        ],
      ),
    );
  }

  Widget _summary(int total) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Text(
        '$total ${total == 1 ? 'Yape registrado' : 'Yapes registrados'}',
        style: GoogleFonts.roboto(
          color: Colors.grey.shade700,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _content(PagoYapeListState state) {
    if (state.loading && state.pagos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.pagos.isEmpty) {
      return _errorState(state.errorMessage!);
    }
    if (state.pagos.isEmpty) return _emptyState();

    final showFooter = state.loading || state.errorMessage != null;
    return RefreshIndicator(
      onRefresh: () => ref.read(pagoYapeListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: state.pagos.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.pagos.length) {
            if (state.errorMessage != null) {
              return _retryFooter(state.errorMessage!);
            }
            return const Padding(
              padding: EdgeInsets.all(18),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _paymentCard(state.pagos[index]);
        },
      ),
    );
  }

  Widget _paymentCard(PagoYape payment) {
    final statusColor = payment.validado
        ? const Color(0xFF26864A)
        : const Color(0xFF9A6700);
    final statusBackground = payment.validado
        ? const Color(0xFFE7F6EC)
        : const Color(0xFFFFF4CE);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ColorSchema.primaryColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: ColorSchema.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        payment.nombrePagador.isEmpty
                            ? 'Sin nombre'
                            : payment.nombrePagador,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _amountFormat.format(payment.monto),
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ColorSchema.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  payment.fechaRegistro == null
                      ? 'Fecha no disponible'
                      : _dateFormat.format(payment.fechaRegistro!),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Operación: ${payment.codigoOperacion.isEmpty ? '-' : payment.codigoOperacion}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        payment.validado ? 'Validado' : 'Pendiente',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return RefreshIndicator(
      onRefresh: () => ref.read(pagoYapeListProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 130),
          Icon(Icons.payments_outlined, size: 58, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Todavía no hay Yapes registrados',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: Text(
              'Desliza hacia abajo para actualizar',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 52,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(pagoYapeListProvider.notifier).loadFirstPage(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _retryFooter(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.red.shade700),
          ),
          TextButton(
            onPressed: () => ref.read(pagoYapeListProvider.notifier).loadMore(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
