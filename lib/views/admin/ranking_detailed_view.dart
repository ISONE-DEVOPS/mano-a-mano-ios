import 'package:mano_mano_dashboard/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

/// Tela que apresenta o ranking detalhado dos participantes.
/// Mostra nome da equipa, pontuação e número de checkpoints concluídos.
class RankingDetailedView extends StatelessWidget {
  const RankingDetailedView({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ranking')
            .orderBy('pontuacao', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum dado disponível'));
          }

          final rankings = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rankings.length,
            separatorBuilder: (context, _) => const Divider(),
            itemBuilder: (context, index) {
              final data = rankings[index].data() as Map<String, dynamic>;
              final equipaId = data['equipaId'];
              if (equipaId == null || equipaId.toString().isEmpty) {
                return const ListTile(
                  title: Text('Equipa inválida'),
                  subtitle: Text('ID não definido'),
                );
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('equipas').doc(equipaId).get(),
                builder: (context, equipaSnapshot) {
                  final equipaNome = equipaSnapshot.data?.get('nome') ?? 'Equipa';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.secondaryDark,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    title: Text(
                      equipaNome,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Checkpoints: ${data['checkpointCount'] ?? 0}',
                      style: TextStyle(
                        color: AppColors.textSecondary.withAlpha(179),
                      ),
                    ),
                    trailing: Text(
                      '${data['pontuacao'] ?? 0} pts',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}