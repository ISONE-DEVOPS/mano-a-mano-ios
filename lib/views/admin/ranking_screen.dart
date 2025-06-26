// ================================
// RANKING SCREEN - PÓDIUM + REAL-TIME
// ================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/services/ranking_service.dart';
import 'package:mano_mano_dashboard/widgets/shared/admin_page_wrapper.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  bool _isRecalculating = false;
  DateTime? _lastUpdate;
  late Stream<QuerySnapshot> _rankingStream;

  List<QueryDocumentSnapshot> _equipas = [];
  List<QueryDocumentSnapshot> _veiculos = [];
  bool _dadosCarregados = false;

  @override
  void initState() {
    super.initState();
    // Stream em tempo real
    _rankingStream =
        FirebaseFirestore.instance
            .collection('ranking')
            .orderBy('pontuacao', descending: true)
            .orderBy('tempoTotal')
            .orderBy('pontuacaoDesempate', descending: true)
            .snapshots();

    FirebaseFirestore.instance.collection('equipas').get().then((snapshot) {
      setState(() {
        _equipas = snapshot.docs;
      });
    });

    FirebaseFirestore.instance.collection('veiculos').get().then((snapshot) {
      setState(() {
        _veiculos = snapshot.docs;
        _dadosCarregados = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageWrapper(
      title: 'Ranking Shell ao KM',
      actions: [
        IconButton(
          onPressed: () => _showRankingManagement(context),
          icon: const Icon(Icons.settings),
          tooltip: 'Gestão do Ranking',
        ),
      ],
      child: StreamBuilder<QuerySnapshot>(
        stream: _rankingStream,
        builder: (context, snapshot) {
          debugPrint(
            '🔍 snapshot connection: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, error: ${snapshot.error}',
          );
          if (!snapshot.hasData) {
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

          final rankingDocs = snapshot.data!.docs;

          if (rankingDocs.isEmpty) {
            return _buildEmptyRanking();
          }

          final top3 = rankingDocs.take(3).toList();
          final remaining = rankingDocs.skip(3).toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeaderStats(rankingDocs),
                _buildPodium(top3),
                if (remaining.isNotEmpty) _buildRemainingTeams(remaining),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderStats(List<QueryDocumentSnapshot> docs) {
    final totalEquipas = docs.length;
    final pontucaoMais =
        totalEquipas > 0
            ? (docs.first.data() as Map<String, dynamic>)['pontuacao'] ?? 0
            : 0;
    final equipasComPontos =
        docs
            .where(
              (doc) =>
                  ((doc.data() as Map<String, dynamic>)['pontuacao'] ?? 0) > 0,
            )
            .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Classificação Geral - Atualização em Tempo Real',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          if (_lastUpdate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Última atualização: ${_formatDateTime(_lastUpdate!)}',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard('Total Equipas', '$totalEquipas', Icons.groups),
                SizedBox(width: 12),
                _buildStatCard('Com Pontos', '$equipasComPontos', Icons.star),
                SizedBox(width: 12),
                _buildStatCard(
                  'Melhor Score',
                  '$pontucaoMais pts',
                  Icons.emoji_events,
                ),
                SizedBox(width: 12),
                _buildStatCard('Status', 'AO VIVO', Icons.live_tv),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<QueryDocumentSnapshot> top3) {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Título do pódium
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.yellow.shade600, Colors.yellow.shade500],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Text(
                  'PÓDIUM - TOP 3',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // Pódium visual
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Layout do pódium (2º, 1º, 3º)
                if (top3.isNotEmpty) _buildPodiumLayout(top3),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumLayout(List<QueryDocumentSnapshot> top3) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2º Lugar
          if (top3.length > 1)
            _buildPodiumStep(top3[1], 2, 120, Colors.grey.shade500),

          // 1º Lugar (mais alto)
          if (top3.isNotEmpty)
            _buildPodiumStep(top3[0], 1, 160, Colors.yellow.shade600),

          // 3º Lugar
          if (top3.length > 2)
            _buildPodiumStep(top3[2], 3, 100, Colors.brown.shade500),
        ],
      ),
    );
  }

  Widget _buildPodiumStep(
    QueryDocumentSnapshot doc,
    int position,
    double height,
    Color color,
  ) {
    final data = doc.data() as Map<String, dynamic>;

    // Adiciona a linha para pegar o tempo total
    final tempoTotal = data['tempoTotal'] ?? 0;

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

        final equipaNome =
            data['nome'] ?? equipaData?['nome'] ?? 'Equipa $position';
        final grupo = data['grupo'] ?? equipaData?['grupo'] ?? 'A';
        final distico = data['distico'] ?? equipaData?['distico'];
        final matricula = data['matricula'] ?? equipaData?['matricula'];

        return Column(
          children: [
            // Medalha e info da equipa
            Container(
              width: 120,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withAlpha(51),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color, width: 2),
              ),
              child: Column(
                children: [
                  // Medalha
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withAlpha(204)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(102),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$position°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Nome da equipa
                  Text(
                    equipaNome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Dístico e matrícula (abaixo do nome)
                  if (distico != null || matricula != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        [
                          if (distico != null) 'Dístico $distico',
                          if (matricula != null) matricula,
                        ].join(' · '),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Pontuação
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      '${data['pontuacao'] ?? 0} pts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  // Desempate
                  if ((data['pontuacaoDesempate'] ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        'Desempate: ${data['pontuacaoDesempate']} pts',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),

                  // Adiciona o bloco do tempo total
                  const SizedBox(height: 8),

                  // Tempo Total
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(tempoTotal / 60).toStringAsFixed(1)} min',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Grupo
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          grupo == 'A'
                              ? Colors.blue.shade100
                              : Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Grupo $grupo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            grupo == 'A'
                                ? Colors.blue.shade800
                                : Colors.purple.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Base do pódium
            Container(
              width: 120,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withAlpha(153), color],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(102),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: position == 1 ? 40 : 30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$position° LUGAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: position == 1 ? 16 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRemainingTeams(List<QueryDocumentSnapshot> remaining) {
    if (!_dadosCarregados) {
      return const Center(child: CircularProgressIndicator());
    }

    final equipasMap = {
      for (var doc in _equipas) doc.id: doc.data() as Map<String, dynamic>,
    };

    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRemainingTeamsHeader(),
          ...remaining.asMap().entries.map((entry) {
            final index = entry.key;
            final doc = entry.value;
            final position = index + 4;
            final data = doc.data() as Map<String, dynamic>;
            final equipaId = data['equipaId'];
            final equipaData = equipasMap[equipaId] ?? {};

            final membros = equipaData['membros'] ?? [];
            final condutorId =
                (membros is List && membros.isNotEmpty) ? membros[0] : null;

            final veiculosFiltrados =
                _veiculos.where((doc) {
                  final vdata = doc.data() as Map<String, dynamic>;
                  return vdata['ownerId'] == condutorId ||
                      vdata['condutorId'] == condutorId;
                }).toList();

            final veiculo =
                veiculosFiltrados.isNotEmpty ? veiculosFiltrados.first : null;
            final veiculoData =
                veiculo != null ? veiculo.data() as Map<String, dynamic> : {};

            return _buildTeamRowCard(
              position: position,
              equipaNome:
                  data['nome'] ?? equipaData['nome'] ?? 'Equipa $position',
              grupo: data['grupo'] ?? equipaData['grupo'] ?? 'A',
              pontuacao: data['pontuacao'] ?? 0,
              tempoTotal: data['tempoTotal'] ?? 0,
              checkpointCount: data['checkpointCount'] ?? 0,
              distico:
                  data['distico'] ??
                  equipaData['distico'] ??
                  veiculoData['distico']?.toString(),
              matricula:
                  data['matricula'] ??
                  equipaData['matricula'] ??
                  veiculoData['matricula']?.toString(),
              pontuacaoDesempate: data['pontuacaoDesempate'] ?? 0,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRemainingTeamsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.list, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Text(
            'CLASSIFICAÇÃO COMPLETA',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Spacer(),
          Text(
            'Posição | Equipa | Pontos | Checkpoints',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRowCard({
    required int position,
    required String equipaNome,
    required String grupo,
    required int pontuacao,
    required int tempoTotal,
    required int checkpointCount,
    required int pontuacaoDesempate,
    String? distico,
    String? matricula,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: position % 2 == 0 ? Colors.grey.shade50 : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Posição
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getPositionColor(position),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                '$position',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Nome da equipa
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipaNome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Grupo $grupo',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                // Dístico e matrícula em linha, se existirem
                if ((distico != null && distico.isNotEmpty) ||
                    (matricula != null && matricula.isNotEmpty))
                  Text(
                    [
                      if (distico != null && distico.isNotEmpty)
                        'Dístico $distico',
                      if (matricula != null && matricula.isNotEmpty) matricula,
                    ].join(' · '),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                if (pontuacaoDesempate > 0)
                  Text(
                    'Desempate: $pontuacaoDesempate pts',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
              ],
            ),
          ),

          // Pontuação
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Text(
              '$pontuacao pts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Checkpoints
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$checkpointCount/8',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Tempo Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${(tempoTotal / 60).toStringAsFixed(1)} min',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
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
              'Rally ainda não iniciado',
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'As pontuações aparecerão aqui quando as equipas começarem a participar',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getPositionColor(int position) {
    if (position <= 5) return Colors.green.shade600;
    if (position <= 10) return Colors.blue.shade600;
    return Colors.orange.shade600;
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
                    'Sistema de ranking em tempo real',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.live_tv, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Status: ATIVO',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Atualização automática quando participante pontua',
                        ),
                        Text('• Pódium destacado para top 3'),
                        Text('• Sincronização em tempo real via Firestore'),
                        Text('• Ordenação por pontuação total'),
                      ],
                    ),
                  ),
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
                  _isRecalculating ? 'Recalculando...' : 'Recalcular Ranking',
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
