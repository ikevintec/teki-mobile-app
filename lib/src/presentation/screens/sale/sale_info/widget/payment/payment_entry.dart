import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/payment_method.dart';

// ─── Entrada de pago individual ──────────────────────────────────────────────

class PaymentEntry {
  final PaymentMethod method;
  final TextEditingController amountController;
  final TextEditingController operationController;

  PaymentEntry({required this.method, required double initialAmount})
      : amountController =
            TextEditingController(text: initialAmount.toStringAsFixed(2)),
        operationController = TextEditingController();

  PaymentEntry.fromExisting({
    required this.method,
    required String amount,
    required String operation,
  })  : amountController = TextEditingController(text: amount),
        operationController = TextEditingController(text: operation);

  void dispose() {
    amountController.dispose();
    operationController.dispose();
  }
}
