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
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
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
                future:
                    FirebaseFirestore.instance
                        .collection('equipas')
                        .doc(equipaId)
                        .get(),
                builder: (context, equipaSnapshot) {
                  final equipaNome =
                      equipaSnapshot.data?.get('nome') ?? 'Equipa';

                  return FutureBuilder<QuerySnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('equipas')
                            .doc(equipaId)
                            .collection('pontuacoes')
                            .get(),
                    builder: (context, pontuacaoSnapshot) {
                      int pontosPerguntas = 0;
                      if (pontuacaoSnapshot.hasData) {
                        for (var doc in pontuacaoSnapshot.data!.docs) {
                          final dados = doc.data() as Map<String, dynamic>;
                          if (dados['respostaCorreta'] == true) {
                            pontosPerguntas +=
                                10; // pontuação padrão por pergunta
                          }
                        }
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.secondaryDark,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        title: Text(
                          equipaNome,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Checkpoints: ${data['checkpointCount'] ?? 0} | Pontos de Pergunta: $pontosPerguntas',
                          style: TextStyle(color: Colors.black),
                        ),
                        trailing: Text(
                          '${data['pontuacao'] ?? 0} pts',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
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
