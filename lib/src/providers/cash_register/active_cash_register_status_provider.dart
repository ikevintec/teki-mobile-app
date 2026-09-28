import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/response/cash_register_active_status.dart';
import 'package:teki_app/src/data/repositories/cash_register_repository_impl.dart';
import 'package:teki_app/src/providers/config/config.dart';

final activeCashRegisterStatusProvider =
    FutureProvider.autoDispose<CashRegisterActiveStatus>((ref) async {
      final session = ref.watch(sesionProvider);
      final idPuntoVenta = session.office?.id;
      final idEstacionVenta = session.saleStation?.id;
      if (idPuntoVenta == null || idEstacionVenta == null) {
        return const CashRegisterActiveStatus(
          cajaActiva: false,
          fechaPasada: false,
        );
      }
      return CashRegisterRepositoryImpl().getActiveStatus(
        idPuntoVenta: idPuntoVenta,
        idEstacionVenta: idEstacionVenta,
      );
    });
