import 'package:mano_mano_dashboard/theme/app_colors.dart';


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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Ranking Detalhado',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rankings.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final item = rankings[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.secondaryDark,
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.black),
              ),
            ),
            title: Text(
              item['team'] as String,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Checkpoints: ${item['checkpoints']}',
              style: TextStyle(
                color: AppColors.textSecondary.withAlpha(179),
              ),
            ),
            trailing: Text(
              '${item['score']} pts',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}