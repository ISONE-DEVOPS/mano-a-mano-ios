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
      body: CustomScrollView(
        slivers: [
          // AppBar personalizada com gradiente
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Ranking Shell ao KM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.emoji_events,
                    size: 60,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
          ),

          // Conteúdo do ranking
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('ranking')
                      .orderBy('pontuacao', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 400,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Carregando ranking...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SizedBox(
                    height: 400,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.leaderboard_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum ranking disponível',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'As equipas aparecerão aqui quando iniciarem a competição',
                            style: TextStyle(color: Colors.grey.shade500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final rankings = snapshot.data!.docs;

                return Column(
                  children: [
                    // Header com estatísticas
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade50, Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            'Equipas',
                            '${rankings.length}',
                            Icons.groups,
                            Colors.blue,
                          ),
                          _buildStatCard(
                            'Em Competição',
                            '${rankings.where((doc) => (doc.data() as Map)['checkpointCount'] > 0).length}',
                            Icons.flag,
                            Colors.green,
                          ),
                          _buildStatCard(
                            'Finalizadas',
                            '${rankings.where((doc) => (doc.data() as Map)['checkpointCount'] >= 8).length}',
                            Icons.check_circle,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),

                    // Lista do ranking
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: rankings.length,
                      itemBuilder: (context, index) {
                        final data =
                            rankings[index].data() as Map<String, dynamic>;
                        final equipaId = data['equipaId'];

                        if (equipaId == null || equipaId.toString().isEmpty) {
                          return _buildErrorCard();
                        }

                        return FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('equipas')
                                  .doc(equipaId)
                                  .get(),
                          builder: (context, equipaSnapshot) {
                            final equipaNome =
                                equipaSnapshot.data?.get('nome') ??
                                'Equipa ${index + 1}';

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
                                  for (var doc
                                      in pontuacaoSnapshot.data!.docs) {
                                    final dados =
                                        doc.data() as Map<String, dynamic>;
                                    if (dados['respostaCorreta'] == true) {
                                      pontosPerguntas += 10;
                                    }
                                  }
                                }

                                return _buildRankingCard(
                                  index: index,
                                  equipaNome: equipaNome,
                                  pontuacao: data['pontuacao'] ?? 0,
                                  checkpointCount: data['checkpointCount'] ?? 0,
                                  pontosPerguntas: pontosPerguntas,
                                  tempoTotal: data['tempoTotal'] ?? 0,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildRankingCard({
    required int index,
    required String equipaNome,
    required int pontuacao,
    required int checkpointCount,
    required int pontosPerguntas,
    required int tempoTotal,
  }) {
    // Cores para top 3
    Color getRankColor(int position) {
      switch (position) {
        case 0:
          return Colors.amber; // Ouro
        case 1:
          return Colors.grey; // Prata
        case 2:
          return Colors.brown; // Bronze
        default:
          return AppColors.primary;
      }
    }

    bool isTopThree = index < 3;
    Color rankColor = getRankColor(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            isTopThree
                ? Border.all(color: rankColor.withAlpha(77), width: 2)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Posição
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isTopThree ? rankColor : AppColors.primary,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isTopThree
                            ? rankColor.withAlpha(77)
                            : AppColors.primary.withAlpha(77)),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child:
                    isTopThree && index < 3
                        ? Icon(
                          index == 0
                              ? Icons.emoji_events
                              : index == 1
                              ? Icons.military_tech
                              : Icons.workspace_premium,
                          color: Colors.white,
                          size: 24,
                        )
                        : Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
              ),
            ),

            const SizedBox(width: 16),

            // Informações da equipa
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipaNome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.flag_outlined,
                        '$checkpointCount/8',
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.quiz_outlined,
                        '$pontosPerguntas pts',
                        Colors.green,
                      ),
                    ],
                  ),
                  if (tempoTotal > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(tempoTotal / 60).toStringAsFixed(0)} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Pontuação total
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '$pontuacao',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'pontos',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400),
          const SizedBox(width: 12),
          const Text(
            'Equipa com dados inválidos',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
