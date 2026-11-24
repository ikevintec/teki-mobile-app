import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/seller.dart';
import 'package:teki_app/src/data/repositories/seller_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/seller_repository.dart';
import 'package:teki_app/src/utils/notifications.dart';

final sellersProvider =
    StateNotifierProvider<SellersNotifier, List<Seller>>((ref) {
  final repo = SellerRepositoryImpl();
  return SellersNotifier(repository: repo);
});

class SellersNotifier extends StateNotifier<List<Seller>> {
  final SellerRepository repository;
  bool _loaded = false;

  SellersNotifier({required this.repository}) : super([]);

  /// Carga los vendedores una sola vez; llamadas posteriores no vuelven a pegarle al backend.
  Future<void> loadOnce() async {
    if (_loaded) return;
    _loaded = true;
    try {
      state = await repository.getAllSellers();
    } catch (e) {
      _loaded = false;
      errorNotification('Error al obtener vendedores: $e');
    }
  }
}
