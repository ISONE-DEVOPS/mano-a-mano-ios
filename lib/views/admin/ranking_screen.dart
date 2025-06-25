// ================================
// RANKING SCREEN - CABEÇALHO OTIMIZADO
// ================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/services/ranking_service.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  bool _isRecalculating = false;
  DateTime? _lastUpdate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.leaderboard, size: 24),
            SizedBox(width: 12),
            Text(
              'Ranking Geral',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showRankingManagement(context),
            icon: const Icon(Icons.settings, size: 20),
            tooltip: 'Gestão do Ranking',
          ),
          IconButton(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Atualizar',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Header compacto otimizado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.red.shade600, Colors.red.shade500],
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'SHELL AO KM 2025',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Classificação geral por pontuação',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                _buildCompactRankingStats(),
              ],
            ),
          ),

          // Status do último recálculo
          if (_lastUpdate != null) _buildLastUpdateInfo(),

          // Lista do ranking
          Expanded(child: _buildRankingList()),
        ],
      ),
    );
  }

  Widget _buildCompactRankingStats() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('ranking')
              .orderBy('pontuacao', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 40,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final totalEquipas = snapshot.data!.docs.length;
        final pontucaoMais =
            totalEquipas > 0
                ? (snapshot.data!.docs.first.data()
                        as Map<String, dynamic>)['pontuacao'] ??
                    0
                : 0;
        final equipasComPontos =
            snapshot.data!.docs
                .where(
                  (doc) =>
                      ((doc.data() as Map<String, dynamic>)['pontuacao'] ?? 0) >
                      0,
                )
                .length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCompactStatItem('Total', '$totalEquipas', Icons.groups),
            _buildCompactStatItem(
              'Com Pontos',
              '$equipasComPontos',
              Icons.star,
            ),
            _buildCompactStatItem(
              'Melhor',
              '$pontucaoMais pts',
              Icons.emoji_events,
            ),
            _buildCompactStatItem('Status', 'Ativo', Icons.play_circle),
          ],
        );
      },
    );
  }

  Widget _buildCompactStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdateInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 8),
          Text(
            'Última atualização: ${_formatDateTime(_lastUpdate!)}',
            style: TextStyle(color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('ranking')
              .orderBy('pontuacao', descending: true)
              .snapshots(),
      builder: (context, rankingSnapshot) {
        if (!rankingSnapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.red),
                SizedBox(height: 16),
                Text('Carregando ranking...'),
              ],
            ),
          );
        }

        final rankingDocs = rankingSnapshot.data!.docs;

        if (rankingDocs.isEmpty) {
          return _buildEmptyRanking();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header da tabela
                _buildRankingHeader(),

                // Lista de equipas
                ...rankingDocs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final doc = entry.value;
                  final data = doc.data() as Map<String, dynamic>;

                  return _buildRankingRow(data, index + 1);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyRanking() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.leaderboard, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Nenhum ranking disponível',
              style: TextStyle(
                fontSize: 22,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'As pontuações aparecerão aqui após o início do rally',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.red.shade500],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'Posição',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Equipa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              'Pontuação',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'Checkpoints',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              'Grupo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingRow(Map<String, dynamic> data, int position) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('equipas')
              .doc(data['equipaId'])
              .get(),
      builder: (context, equipaSnapshot) {
        final equipaData =
            equipaSnapshot.hasData
                ? (equipaSnapshot.data?.data() as Map<String, dynamic>?)
                : null;

        final equipaNome = equipaData?['nome'] ?? 'Equipa $position';
        final grupo = equipaData?['grupo'] ?? 'A';

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: position % 2 == 0 ? Colors.white : Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
                width: position == 1 ? 0 : 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Posição com medalha
              SizedBox(
                width: 80,
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getPositionColor(position),
                            _getPositionColor(position).withAlpha(204),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: _getPositionColor(position).withAlpha(102),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$position',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (position <= 3)
                      Icon(
                        Icons.emoji_events,
                        color: _getPositionColor(position),
                        size: 20,
                      ),
                  ],
                ),
              ),

              // Nome da equipa
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipaNome,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                        decoration:
                            position <= 3 ? TextDecoration.underline : null,
                        decorationColor: _getPositionColor(position),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${data['equipaId']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Pontuação
              SizedBox(
                width: 140,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade50, Colors.green.shade100],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Text(
                    '${data['pontuacao'] ?? 0} pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Checkpoints
              SizedBox(
                width: 120,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    '${data['checkpointCount'] ?? 0}/8',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Grupo
              SizedBox(
                width: 100,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        grupo == 'A'
                            ? Colors.blue.shade100
                            : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          grupo == 'A'
                              ? Colors.blue.shade300
                              : Colors.green.shade300,
                    ),
                  ),
                  child: Text(
                    grupo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          grupo == 'A'
                              ? Colors.blue.shade800
                              : Colors.green.shade800,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber.shade600; // Ouro
      case 2:
        return Colors.grey.shade500; // Prata
      case 3:
        return Colors.brown.shade500; // Bronze
      case 4:
      case 5:
        return Colors.green.shade600; // Top 5
      case 6:
      case 7:
      case 8:
      case 9:
      case 10:
        return Colors.blue.shade600; // Top 10
      default:
        return Colors.red.shade600; // Restantes
    }
  }

  void _showRankingManagement(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.settings, color: Colors.red.shade600),
                const SizedBox(width: 12),
                const Text('Gestão do Ranking'),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gerir o sistema de ranking do rally',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  if (_lastUpdate != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Última atualização: ${_formatDateTime(_lastUpdate!)}',
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  const Text(
                    'Informações do Sistema:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Atualização automática quando participante responde',
                  ),
                  const Text('• Recálculo manual quando necessário'),
                  const Text('• Ordenação por pontuação e checkpoints'),
                  const Text('• Sincronização em tempo real'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
              ElevatedButton.icon(
                onPressed: _isRecalculating ? null : _recalculateRanking,
                icon:
                    _isRecalculating
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.refresh),
                label: Text(
                  _isRecalculating ? 'Recalculando...' : 'Recalcular Tudo',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _recalculateRanking() async {
    setState(() => _isRecalculating = true);

    try {
      await RankingService.recalculateCompleteRanking();

      setState(() {
        _lastUpdate = DateTime.now();
        _isRecalculating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ranking recalculado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isRecalculating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao recalcular: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} às ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
