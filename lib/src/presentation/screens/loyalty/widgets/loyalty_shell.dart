import 'package:flutter/material.dart';
import 'package:teki_app/src/utils/constants.dart';

class LoyaltyScaffold extends StatelessWidget {
  final String title;
  final bool allowed;
  final Widget child;
  final String? unavailableText;
  const LoyaltyScaffold({
    super.key,
    this.unavailableText,
    required this.title,
    required this.allowed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: ColorSchema.primaryColor,
        onPrimary: Colors.white,
      ),
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        backgroundColor: ColorSchema.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: allowed
            ? child
            : LoyaltyMessage(
                icon: Icons.lock_outline,
                text:
                    unavailableText ??
                    'Tarjetas de fidelización no disponibles para esta sesión. '
                        'Requiere fidelización habilitada y permiso de consulta en la empresa actual.',
              ),
      ),
    ),
  );
}

class LoyaltyMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? retry;
  const LoyaltyMessage({
    super.key,
    required this.icon,
    required this.text,
    this.retry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: const Color(0xFF535965)),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          if (retry != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: OutlinedButton(
                onPressed: retry,
                child: const Text('Reintentar'),
              ),
            ),
        ],
      ),
    ),
  );
}

String loyaltyErrorText(Object error) =>
    error.toString().replaceFirst('Exception: ', '');
