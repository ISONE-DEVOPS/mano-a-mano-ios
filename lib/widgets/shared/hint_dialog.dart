import 'package:flutter/material.dart';

/// Widget reutilizável que exibe uma pista em forma de diálogo.
/// Pode ser usado em qualquer parte da aplicação onde uma pista/concha precise ser mostrada.
class HintDialog extends StatelessWidget {
  final String hintText;

  const HintDialog({super.key, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('📍 Sua Concha'),
      content: Text(
        hintText,
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}
