import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_coupon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_card.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_customer.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_points_movement.dart';
import 'package:teki_app/src/providers/loyalty/loyalty_provider.dart';
import 'package:teki_app/src/providers/loyalty/loyalty_customers_provider.dart';
import 'package:teki_app/src/presentation/screens/loyalty/widgets/loyalty_shell.dart';
import 'package:teki_app/src/presentation/screens/loyalty/widgets/loyalty_paged_list.dart';

class LoyaltyCustomersScreen extends ConsumerWidget {
  final int companyId;
  final LoyaltyCard card;
  const LoyaltyCustomersScreen({
    super.key,
    required this.companyId,
    required this.card,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(loyaltyCustomersScopeProvider);
    final allowed = scope != null && scope.companyId == companyId;
    final key = (companyId: companyId, cardId: card.id);
    if (!allowed) {
      return const LoyaltyScaffold(
        title: 'Clientes de la tarjeta',
        unavailableText:
            'Requiere fidelización habilitada y permisos para consultar tarjetas y clientes en la empresa actual.',
        allowed: false,
        child: SizedBox.shrink(),
      );
    }
    final state = ref.watch(loyaltyCustomersProvider(key));
    final notifier = ref.read(loyaltyCustomersProvider(key).notifier);
    return LoyaltyScaffold(
      title: 'Clientes de la tarjeta',
      unavailableText:
          'Requiere fidelización habilitada y permisos para consultar tarjetas y clientes en la empresa actual.',
      allowed: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.loaded
                      ? '${state.total} ${state.total == 1 ? 'cliente' : 'clientes'}${state.filter.trim().isEmpty
                            ? ''
                            : state.total == 1
                            ? ' encontrado'
                            : ' encontrados'}'
                      : state.loading
                      ? 'Consultando clientes…'
                      : 'Consulta los clientes inscritos',
                ),
                const SizedBox(height: 16),
                TextField(
                  key: ObjectKey(notifier),
                  decoration: const InputDecoration(
                    labelText: 'Buscar cliente',
                    hintText: 'Nombre, documento o teléfono',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  autocorrect: false,
                  textInputAction: TextInputAction.search,
                  onChanged: notifier.search,
                  onSubmitted: (_) => notifier.load(),
                ),
              ],
            ),
          ),
          Expanded(
            child: LoyaltyPagedList<LoyaltyCustomer>(
              state: state,
              onRefresh: notifier.load,
              onLoadMore: notifier.loadMore,
              emptyText: state.filter.trim().isEmpty
                  ? 'Todavía no hay clientes inscritos en esta tarjeta.'
                  : 'No se encontraron clientes para esta búsqueda.',
              itemBuilder: (customer) => Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    customer.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (customer.discreetDocument != null)
                          Text('Documento: ${customer.discreetDocument}'),
                        Text(
                          [
                            if (card.permitirSellos)
                              '${_number(customer.stamps)} sellos',
                            if (card.permitirPuntos)
                              '${_number(customer.availablePoints)} puntos disponibles',
                          ].join(' · '),
                        ),
                        if (!customer.active)
                          const Text('Inscripción inactiva'),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LoyaltyCustomerScreen(
                        customerKey: (
                          companyId: companyId,
                          cardId: card.id,
                          enrollmentId: customer.id,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum LoyaltyCustomerView { balance, points, coupons }

class LoyaltyCustomerScreen extends ConsumerWidget {
  final LoyaltyCustomerKey customerKey;
  final LoyaltyCustomerView view;
  const LoyaltyCustomerScreen({
    super.key,
    required this.customerKey,
    this.view = LoyaltyCustomerView.balance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(loyaltyCustomersScopeProvider);
    final allowed =
        scope != null &&
        scope.companyId == customerKey.companyId &&
        (view != LoyaltyCustomerView.coupons ||
            canViewLoyaltyCoupons(ref.watch(sesionProvider)));
    final title = switch (view) {
      LoyaltyCustomerView.balance => 'Saldo del cliente',
      LoyaltyCustomerView.points => 'Movimientos de puntos',
      LoyaltyCustomerView.coupons => 'Cupones emitidos',
    };
    return LoyaltyScaffold(
      title: title,
      allowed: allowed,
      unavailableText:
          'Requiere fidelización habilitada y los permisos de consulta correspondientes en la empresa actual.',
      child: allowed ? _content(context, ref) : const SizedBox.shrink(),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref) {
    final cardKey = (
      companyId: customerKey.companyId,
      cardId: customerKey.cardId,
    );
    final cardState = ref.watch(loyaltyCardProvider(cardKey));
    final customerState = ref.watch(loyaltyCustomerProvider(customerKey));
    return cardState.when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => LoyaltyMessage(
        icon: Icons.cloud_off_outlined,
        text: loyaltyErrorText(e),
        retry: () => ref.invalidate(loyaltyCardProvider(cardKey)),
      ),
      data: (card) => card == null
          ? const SizedBox.shrink()
          : customerState.when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => LoyaltyMessage(
                icon: Icons.cloud_off_outlined,
                text: loyaltyErrorText(e),
                retry: () =>
                    ref.invalidate(loyaltyCustomerProvider(customerKey)),
              ),
              data: (result) => result == null
                  ? const SizedBox.shrink()
                  : _body(
                      context,
                      ref,
                      card,
                      result.customer,
                      result.consultedAt,
                    ),
            ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    LoyaltyCard card,
    LoyaltyCustomer customer,
    DateTime consultedAt,
  ) {
    Future<void> refresh() async {
      ref.invalidate(
        loyaltyCardProvider((
          companyId: customerKey.companyId,
          cardId: customerKey.cardId,
        )),
      );
      ref.invalidate(loyaltyCustomerProvider(customerKey));
      if (view == LoyaltyCustomerView.points) {
        ref.invalidate(loyaltyMovementsProvider(customerKey));
      }
      if (view == LoyaltyCustomerView.coupons) {
        ref.invalidate(loyaltyCouponsProvider(customerKey));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      customer.cardName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (!customer.active)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Inscripción inactiva'),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: switch (view) {
            LoyaltyCustomerView.balance => _balance(
              context,
              ref,
              card,
              customer,
              consultedAt,
              refresh,
            ),
            LoyaltyCustomerView.points => _movements(ref, card, refresh),
            LoyaltyCustomerView.coupons => _coupons(ref, refresh),
          },
        ),
      ],
    );
  }

  Widget _balance(
    BuildContext context,
    WidgetRef ref,
    LoyaltyCard card,
    LoyaltyCustomer customer,
    DateTime consultedAt,
    Future<void> Function() refresh,
  ) => RefreshIndicator(
    onRefresh: refresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        if (customer.document?.isNotEmpty == true)
          Text('Documento: ${customer.document}'),
        if (customer.phone?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Teléfono: ${customer.phone}'),
          ),
        if (card.permitirSellos)
          _Stamps(customer: customer, goal: card.sellosParaPremio),
        if (card.permitirPuntos) ...[
          _Balance(
            label: 'Puntos disponibles',
            value: _number(customer.availablePoints),
          ),
          _Balance(
            label: 'Puntos acumulados históricos',
            value: _number(customer.historicalPoints),
            large: false,
          ),
        ],
        if (card.permitirMembresia && customer.membership?.isNotEmpty == true)
          _Balance(
            label: 'Membresía',
            value: customer.membership!,
            large: false,
          ),
        if (customer.visits != null)
          _Balance(
            label: 'Visitas registradas',
            value: '${customer.visits}',
            large: false,
          ),
        if (customer.registeredAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              'Inscrito el ${DateFormat('dd/MM/yyyy').format(customer.registeredAt!)}',
            ),
          ),
        const SizedBox(height: 20),
        Text('Consultado a las ${DateFormat('HH:mm:ss').format(consultedAt)}'),
        const SizedBox(height: 20),
        if (card.permitirPuntos)
          OutlinedButton.icon(
            icon: const Icon(Icons.history),
            label: const Text('Ver movimientos de puntos'),
            onPressed: () => _open(context, LoyaltyCustomerView.points),
          ),
        if (canViewLoyaltyCoupons(ref.watch(sesionProvider)))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.card_giftcard),
              label: const Text('Ver cupones emitidos'),
              onPressed: () => _open(context, LoyaltyCustomerView.coupons),
            ),
          ),
        if (card.permitirSellos)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'El historial de sellos no está disponible en esta vista.',
            ),
          ),
      ],
    ),
  );

  void _open(BuildContext context, LoyaltyCustomerView view) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              LoyaltyCustomerScreen(customerKey: customerKey, view: view),
        ),
      );

  Widget _coupons(WidgetRef ref, Future<void> Function() refresh) {
    final state = ref.watch(loyaltyCouponsProvider(customerKey));
    final notifier = ref.read(loyaltyCouponsProvider(customerKey).notifier);
    return LoyaltyPagedList<LoyaltyCoupon>(
      state: state,
      onRefresh: refresh,
      onLoadMore: notifier.loadMore,
      emptyText: 'No hay cupones emitidos para esta inscripción.',
      header: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estado registrado de los cupones de esta inscripción. El saldo de sellos no confirma su disponibilidad.',
              ),
              if (state.loaded)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '${state.total} ${state.total == 1 ? 'cupón emitido' : 'cupones emitidos'}',
                  ),
                ),
            ],
          ),
        ),
      ],
      itemBuilder: (coupon) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              coupon.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Estado registrado: ${coupon.statusLabel}'),
            if (coupon.code != null) Text('Código: ${coupon.code}'),
            if (coupon.issuedAt != null)
              Text(
                'Emitido: ${DateFormat('dd/MM/yyyy').format(coupon.issuedAt!)}',
              ),
            if (coupon.expiresAt != null)
              Text(
                'Vencimiento: ${DateFormat('dd/MM/yyyy').format(coupon.expiresAt!)}',
              ),
            if (coupon.usedAt != null)
              Text('Usado: ${DateFormat('dd/MM/yyyy').format(coupon.usedAt!)}'),
            if (coupon.status == 'PENDIENTE' &&
                coupon.expiresAt != null &&
                coupon.expiresAt!.isBefore(DateTime.now()))
              const Text('Su fecha de vencimiento ya pasó.'),
            const SizedBox(height: 12),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }

  Widget _movements(
    WidgetRef ref,
    LoyaltyCard card,
    Future<void> Function() refresh,
  ) {
    if (!card.permitirPuntos) {
      return const LoyaltyMessage(
        icon: Icons.info_outline,
        text:
            'Esta tarjeta no tiene puntos habilitados. El historial de sellos no está disponible.',
      );
    }
    final state = ref.watch(loyaltyMovementsProvider(customerKey));
    final notifier = ref.read(loyaltyMovementsProvider(customerKey).notifier);
    return LoyaltyPagedList<LoyaltyPointsMovement>(
      state: state,
      onRefresh: refresh,
      onLoadMore: notifier.loadMore,
      emptyText:
          'No hay movimientos de puntos registrados para esta inscripción.',
      header: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Solo movimientos de puntos. No incluye el historial completo de sellos ni todos los canjes.',
              ),
              if (state.loaded)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '${state.total} ${state.total == 1 ? 'movimiento' : 'movimientos'}',
                  ),
                ),
            ],
          ),
        ),
      ],
      itemBuilder: (movement) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    movement.typeLabel,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    '${movement.points != null && movement.points! > 0 ? '+' : ''}${_number(movement.points)} puntos',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (movement.processLabel != null) Text(movement.processLabel!),
            if (movement.description?.isNotEmpty == true)
              Text(movement.description!),
            if (movement.date != null)
              Text(DateFormat('dd/MM/yyyy HH:mm').format(movement.date!)),
            if (movement.ticketId != null)
              Text('Referencia de venta: ${movement.ticketId}'),
            const SizedBox(height: 12),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }
}

class _Balance extends StatelessWidget {
  final String label;
  final String value;
  final bool large;
  const _Balance({required this.label, required this.value, this.large = true});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: large ? 32 : 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _Stamps extends StatelessWidget {
  final LoyaltyCustomer customer;
  final int? goal;
  const _Stamps({required this.customer, required this.goal});
  @override
  Widget build(BuildContext context) {
    final stamps = customer.stamps;
    final valid = goal != null && goal! > 0 && stamps != null && stamps >= 0;
    final cycle = valid ? stamps % goal! : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Balance(
          label: 'Sellos acumulados (histórico)',
          value: _number(stamps),
        ),
        if (valid) ...[
          const SizedBox(height: 16),
          Text('Avance del ciclo: $cycle de $goal sellos'),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: cycle / goal!,
            minHeight: 8,
            semanticsLabel: 'Avance del ciclo de sellos',
          ),
          const SizedBox(height: 8),
          const Text('El avance del ciclo no confirma premios disponibles.'),
        ],
      ],
    );
  }
}

String _number(int? value) => value?.toString() ?? 'No disponible';
