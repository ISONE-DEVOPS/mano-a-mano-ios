import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Popup simples para exibir a próxima pista (concha) do Rally Paper.
/// Utilizado para mostrar de forma clara e visualmente apelativa o próximo destino.
class HintPopup extends StatelessWidget {
  final String clueText;

  const HintPopup({super.key, required this.clueText});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: const Text('🏁 Próxima Concha', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
      content: Text(
        clueText,
        style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }
}
