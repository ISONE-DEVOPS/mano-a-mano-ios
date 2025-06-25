import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/services/ranking_service.dart';
import 'qualification_grid_view.dart'; // Importe o arquivo da grelha de qualificação

class DashboardAdminView extends StatefulWidget {
  const DashboardAdminView({super.key});

  @override
  State<DashboardAdminView> createState() => _DashboardAdminViewState();
}

class _DashboardAdminViewState extends State<DashboardAdminView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header com estatísticas
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.red.shade700, Colors.red.shade500],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withAlpha(77),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Título principal
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(51),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.dashboard,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SHELL AO KM 2025',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Dashboard Administrativo',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(51),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '28 Jun 2025',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Estatísticas
                _buildStatsHeader(),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.red,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.red,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.dashboard, size: 24), text: 'Dashboard'),
                Tab(
                  icon: Icon(Icons.grid_view, size: 24),
                  text: 'Grelha de Qualificação',
                ),
                Tab(icon: Icon(Icons.leaderboard, size: 24), text: 'Ranking'),
              ],
            ),
          ),

          // Conteúdo das tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                const QualificationGridView(),
                _buildRankingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('equipas').snapshots(),
      builder: (context, equipasSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('editions')
                  .doc('shell_2025')
                  .collection('events')
                  .doc('shell_km_02')
                  .collection('checkpoints')
                  .snapshots(),
          builder: (context, checkpointsSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, usersSnapshot) {
                if (!equipasSnapshot.hasData ||
                    !checkpointsSnapshot.hasData ||
                    !usersSnapshot.hasData) {
                  return const CircularProgressIndicator(color: Colors.white);
                }

                final equipasDocs = equipasSnapshot.data!.docs;
                final usersDocs = usersSnapshot.data!.docs;

                final Map<String, Map<String, dynamic>> usersMap = {
                  for (var u in usersDocs)
                    u.id: u.data() as Map<String, dynamic>,
                };

                final filteredEquipas =
                    equipasDocs.where((doc) {
                      final membros = (doc['membros'] ?? []) as List<dynamic>;
                      return !membros.any(
                        (uid) => usersMap[uid]?['tipo'] == 'admin',
                      );
                    }).toList();

                final totalEquipas = filteredEquipas.length;
                final totalCheckpoints =
                    checkpointsSnapshot.data?.docs.length ?? 0;
                final totalParticipantes = usersSnapshot.data?.docs.length ?? 0;

                return FutureBuilder<QuerySnapshot>(
                  future:
                      FirebaseFirestore.instance.collection('veiculos').get(),
                  builder: (context, veiculosSnapshot) {
                    if (!veiculosSnapshot.hasData) {
                      return const CircularProgressIndicator(
                        color: Colors.white,
                      );
                    }

                    final totalVeiculos = veiculosSnapshot.data!.docs.length;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatIndicator(
                          Icons.groups,
                          'Total de Equipas',
                          totalEquipas,
                        ),
                        _buildStatIndicator(
                          Icons.local_gas_station,
                          'Checkpoints',
                          totalCheckpoints,
                        ),
                        _buildStatIndicator(
                          Icons.person,
                          'Participantes',
                          totalParticipantes,
                        ),
                        _buildStatIndicator(
                          Icons.directions_car,
                          'Veículos',
                          totalVeiculos,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção de status do evento
          Row(
            children: [
              Icon(Icons.dashboard, size: 28, color: Colors.red.shade600),
              const SizedBox(width: 12),
              const Text(
                'Visão Geral do Rally',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Cards de resumo
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Evento Ativo',
                  'Shell ao KM 2025',
                  Icons.event,
                  Colors.blue.shade600,
                  'Rally Paper em preparação',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Status',
                  'Em Preparação',
                  Icons.settings,
                  Colors.orange.shade600,
                  'Configurações em andamento',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Data do Evento',
                  '28 Jun 2025',
                  Icons.calendar_today,
                  Colors.green.shade600,
                  'Sábado - 14h30',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Local de Partida',
                  'Kebra Canela',
                  Icons.location_on,
                  Colors.red.shade600,
                  'Ponto de encontro',
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Seção de estatísticas detalhadas
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          size: 24,
                          color: Colors.red.shade600,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Estatísticas Detalhadas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildDetailedStatsCard(),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications,
                          size: 24,
                          color: Colors.red.shade600,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Atividade Recente',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildActivityCard(),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Informações do percurso
          Row(
            children: [
              Icon(Icons.route, size: 24, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text(
                'Informações dos Percursos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildRouteCard(
                  'GRUPO A - PERCURSO NORTE',
                  'Kebra Canela → Cidadela → São Filipe → Fazenda → Tira-Chapéu → Aeroporto → Várzea → Chã de Areia',
                  Colors.blue.shade600,
                  Icons.north,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRouteCard(
                  'GRUPO B - PERCURSO SUL',
                  'Kebra Canela → Chã de Areia → Várzea → Aeroporto → Tira-Chapéu → Fazenda → São Filipe → Cidadela',
                  Colors.green.shade600,
                  Icons.south,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard, size: 28, color: Colors.red.shade600),
              const SizedBox(width: 12),
              const Text(
                'Ranking Geral',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {}); // Atualizar dados
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('ranking')
                    .orderBy('pontuacao', descending: true)
                    .snapshots(),
            builder: (context, rankingSnapshot) {
              if (!rankingSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final rankingDocs = rankingSnapshot.data!.docs;

              if (rankingDocs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.leaderboard, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum ranking disponível',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'As pontuações aparecerão aqui após o início do rally',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header do ranking
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade600, Colors.red.shade400],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              'Pos.',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Equipa',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Text(
                              'Pontuação',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Checkpoints',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              'Grupo',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lista de equipas no ranking
                    ...rankingDocs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final doc = entry.value;
                      final data = doc.data() as Map<String, dynamic>;

                      return FutureBuilder<DocumentSnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('equipas')
                                .doc(data['equipaId'])
                                .get(),
                        builder: (context, equipaSnapshot) {
                          final equipaData =
                              equipaSnapshot.hasData
                                  ? (equipaSnapshot.data?.data()
                                      as Map<String, dynamic>?)
                                  : null;

                          final equipaNome =
                              equipaData?['nome'] ?? 'Equipa ${index + 1}';
                          final grupo = equipaData?['grupo'] ?? 'A';

                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color:
                                  index % 2 == 0
                                      ? Colors.white
                                      : Colors.grey.shade50,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 60,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _getPositionColor(index + 1),
                                          _getPositionColor(
                                            index + 1,
                                          ).withAlpha(204),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getPositionColor(
                                            index + 1,
                                          ).withAlpha(77),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    equipaNome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      '${data['pontuacao'] ?? 0} pts',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    '${data['checkpointCount'] ?? 0}',
                                    style: const TextStyle(fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          grupo == 'A'
                                              ? Colors.blue.shade100
                                              : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      grupo,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            grupo == 'A'
                                                ? Colors.blue.shade700
                                                : Colors.green.shade700,
                                        fontSize: 12,
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
                    }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow(
            'Postos Shell na Praia',
            '8',
            Icons.local_gas_station,
            Colors.red.shade600,
          ),
          const Divider(),
          _buildStatRow(
            'Checkpoints Configurados',
            '8',
            Icons.check_circle,
            Colors.green.shade600,
          ),
          const Divider(),
          _buildStatRow(
            'Tempo Médio por Posto',
            '15 min',
            Icons.timer,
            Colors.orange.shade600,
          ),
          const Divider(),
          _buildStatRow(
            'Distância Total',
            '~45 km',
            Icons.straighten,
            Colors.blue.shade600,
          ),
          const Divider(),
          _buildStatRow(
            'Duração Estimada',
            '3-4 horas',
            Icons.schedule,
            Colors.purple.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActivityItem(
            'Nova equipa registada',
            'Equipa Flamingos registou-se',
            '14:30',
            Icons.add_circle,
            Colors.green,
          ),
          const Divider(),
          _buildActivityItem(
            'Checkpoint atualizado',
            'Posto de Tira-Chapéu configurado',
            '13:45',
            Icons.edit,
            Colors.blue,
          ),
          const Divider(),
          _buildActivityItem(
            'Novo participante',
            'João Silva juntou-se às Águias',
            '12:20',
            Icons.person_add,
            Colors.orange,
          ),
          const Divider(),
          _buildActivityItem(
            'Sistema atualizado',
            'Base de dados sincronizada',
            '11:15',
            Icons.sync,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(
    String title,
    String description,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withAlpha(25), Colors.white],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatIndicator(IconData icon, String label, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(77)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber.shade600; // Ouro
      case 2:
        return Colors.grey.shade400; // Prata
      case 3:
        return Colors.brown.shade400; // Bronze
      default:
        return Colors.blue.shade600; // Outras posições
    }
  }
}

// ===================================
// WIDGET PARA O DASHBOARD ADMIN
// ===================================

class RankingManagementWidget extends StatefulWidget {
  const RankingManagementWidget({super.key});

  @override
  State<RankingManagementWidget> createState() =>
      _RankingManagementWidgetState();
}

class _RankingManagementWidgetState extends State<RankingManagementWidget> {
  bool _isRecalculating = false;
  DateTime? _lastUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard, color: Colors.red.shade600, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Gestão do Ranking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Botões de ação
          Row(
            children: [
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

              const SizedBox(width: 12),

              OutlinedButton.icon(
                onPressed: () => _showRankingInfo(context),
                icon: const Icon(Icons.info),
                label: const Text('Info'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status
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
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
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

  void _showRankingInfo(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ℹ️ Informações do Ranking'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🔄 **Atualização Automática:**'),
                Text('• Sempre que participante responde pergunta'),
                Text('• Sempre que staff pontua jogo'),
                Text('• Sempre que checkpoint é completado'),
                SizedBox(height: 12),
                Text('🔧 **Atualização Manual:**'),
                Text('• Use o botão "Recalcular Tudo"'),
                Text('• Recomendado se houver inconsistências'),
                Text('• Pode ser usado a qualquer momento'),
                SizedBox(height: 12),
                Text('📊 **Critérios de Ordenação:**'),
                Text('1. Maior pontuação total'),
                Text('2. Maior número de checkpoints'),
                Text('3. Menor tempo total (se implementado)'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} às ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
