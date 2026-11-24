import 'dart:async';

import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/repositories/customer_repository_impl.dart';
import 'package:teki_app/src/utils/constants.dart';

/// Busca un cliente registrado para filtrar los préstamos.
class CustomerFilterSheet extends StatefulWidget {
  const CustomerFilterSheet({super.key});

  static Future<Customer?> show(BuildContext context) {
    return showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CustomerFilterSheet(),
    );
  }

  @override
  State<CustomerFilterSheet> createState() => _CustomerFilterSheetState();
}

class _CustomerFilterSheetState extends State<CustomerFilterSheet> {
  final _repository = CustomersRepositoryImpl();
  Timer? _debounce;
  List<Customer> _results = const [];
  bool _loading = false;
  int _version = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = const []);
      return;
    }
    final version = ++_version;
    setState(() => _loading = true);
    try {
      final customers = await _repository.searchCustomers(query.trim());
      if (!mounted || version != _version) return;
      setState(
        () => _results = customers.where((c) => c.porDefecto != true).toList(),
      );
    } catch (_) {
      if (mounted && version == _version) setState(() => _results = const []);
    } finally {
      if (mounted && version == _version) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  autofocus: true,
                  onChanged: _onChanged,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Nombre o documento del cliente',
                  ),
                ),
              ),
              if (_loading)
                const LinearProgressIndicator(color: ColorSchema.primaryColor),
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final c = _results[i];
                    return ListTile(
                      title: Text(c.razonSocial ?? '-'),
                      subtitle: Text(c.numeroDocumento ?? ''),
                      onTap: () => Navigator.of(context).pop(c),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
