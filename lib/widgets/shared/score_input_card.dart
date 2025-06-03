

import 'package:flutter/material.dart';

/// Widget reutilizável para inserir a pontuação de uma equipa.
/// Usado por administradores ou avaliadores durante os checkpoints ou atividades finais.
class ScoreInputCard extends StatelessWidget {
  final String title;
  final int initialScore;
  final ValueChanged<int> onScoreChanged;

  const ScoreInputCard({
    super.key,
    required this.title,
    required this.initialScore,
    required this.onScoreChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: initialScore.toString());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pontuação',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final intScore = int.tryParse(value) ?? 0;
                onScoreChanged(intScore);
              },
            ),
          ],
        ),
      ),
    );
  }
}