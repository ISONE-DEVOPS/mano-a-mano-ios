import 'package:flutter/material.dart';

/// Popup simples para exibir a próxima pista (concha) do Rally Paper.
/// Utilizado para mostrar de forma clara e visualmente apelativa o próximo destino.
class HintPopup extends StatelessWidget {
  final String clueText;

  const HintPopup({super.key, required this.clueText});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.yellow[100],
      title: const Text('🏁 Próxima Concha', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text(
        clueText,
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
