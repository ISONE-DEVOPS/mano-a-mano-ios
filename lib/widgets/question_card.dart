

import 'package:flutter/material.dart';

/// Widget reutilizável que exibe uma pergunta com opção de resposta.
/// Pode ser usado em checkpoints ou jogos do evento Shell ao KM.
class QuestionCard extends StatelessWidget {
  final String question;
  final int questionNumber;
  final ValueChanged<String> onAnswer;

  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pergunta $questionNumber',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(question),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Sua resposta',
                border: OutlineInputBorder(),
              ),
              onSubmitted: onAnswer,
            ),
          ],
        ),
      ),
    );
  }
}