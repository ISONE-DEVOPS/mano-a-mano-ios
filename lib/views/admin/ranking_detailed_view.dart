

import 'package:flutter/material.dart';

/// Tela que apresenta o ranking detalhado dos participantes.
/// Mostra nome da equipa, pontuação e número de checkpoints concluídos.
class RankingDetailedView extends StatelessWidget {
  const RankingDetailedView({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemplo estático - futuramente conectar com dados do backend
    final rankings = [
      {'team': 'Os Velozes', 'score': 85, 'checkpoints': 7},
      {'team': 'As Conchas', 'score': 75, 'checkpoints': 7},
      {'team': 'Rally Power', 'score': 68, 'checkpoints': 6},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Ranking Detalhado')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rankings.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final item = rankings[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(item['team'] as String),
            subtitle: Text('Checkpoints: ${item['checkpoints']}'),
            trailing: Text('${item['score']} pts',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }
}