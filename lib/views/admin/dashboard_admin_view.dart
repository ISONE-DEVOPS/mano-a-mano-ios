// ================================
// DASHBOARD ADMIN VIEW - COMPLETO ATUALIZADO
// ================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/services/ranking_service.dart';
import 'qualification_grid_screen.dart'; // Nova tela dedicada
import 'ranking_screen.dart'; // Nova tela dedicada

class DashboardAdminView extends StatefulWidget {
  const DashboardAdminView({super.key});

  @override
  State<DashboardAdminView> createState() => _DashboardAdminViewState();
}

class _DashboardAdminViewState extends State<DashboardAdminView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Header otimizado
          _buildHeader(context),

          // Dashboard principal
          Expanded(child: _buildMainDashboard(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red.shade800, Colors.red.shade600],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withAlpha(77),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        children: [
          // Título principal mais compacto
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.dashboard,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SHELL AO KM 2025',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'Dashboard Administrativo',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Botões de navegação rápida mais compactos
              Row(
                children: [
                  _buildCompactActionButton(
                    context,
                    'Grelha',
                    Icons.grid_view,
                    Colors.blue.shade600,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QualificationGridScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildCompactActionButton(
                    context,
                    'Ranking',
                    Icons.leaderboard,
                    Colors.green.shade600,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RankingScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Estatísticas mais compactas
          _buildCompactStatsHeader(),
        ],
      ),
    );
  }

  Widget _buildCompactActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 4,
        shadowColor: color.withAlpha(102),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(80, 32),
      ),
    );
  }

  Widget _buildMainDashboard(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção principal
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.dashboard,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Visão Geral do Rally',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Cards de resumo melhorados
          _buildSummaryCards(),

          const SizedBox(height: 40),

          // Seção de gestão rápida
          _buildQuickManagementSection(context),

          const SizedBox(height: 40),

          // Informações dos percursos
          _buildRouteInformation(),

          const SizedBox(height: 40),

          // Atividade recente
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildImprovedSummaryCard(
            'Evento Ativo',
            'Shell ao KM 2025',
            Icons.event_available,
            Colors.blue.shade600,
            'Rally Paper em preparação',
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildImprovedSummaryCard(
            'Status do Sistema',
            'Operacional',
            Icons.check_circle,
            Colors.green.shade600,
            'Todos os sistemas funcionando',
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildImprovedSummaryCard(
            'Data do Evento',
            '28 Jun 2025',
            Icons.calendar_today,
            Colors.orange.shade600,
            'Sábado às 14h30',
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildImprovedSummaryCard(
            'Local de Partida',
            'Kebra Canela',
            Icons.location_on,
            Colors.red.shade600,
            'Ponto de encontro confirmado',
          ),
        ),
      ],
    );
  }

  Widget _buildImprovedSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickManagementSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Gestão Rápida',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildManagementCard(
                  'Ver Grelha de Qualificação',
                  'Visualizar posições das equipas organizadas por grupos',
                  Icons.grid_view,
                  Colors.blue.shade600,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QualificationGridScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildManagementCard(
                  'Ver Ranking Completo',
                  'Acompanhar classificação geral e pontuações',
                  Icons.leaderboard,
                  Colors.green.shade600,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RankingScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildManagementCard(
                  'Gestão do Ranking',
                  'Recalcular pontuações e verificar inconsistências',
                  Icons.refresh,
                  Colors.orange.shade600,
                  () => _showRankingManagement(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Abrir',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16, color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInformation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.route, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Text(
                'Informações dos Percursos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

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
              const SizedBox(width: 20),
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
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Atividade Recente',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Column(
            children: [
              _buildActivityItem(
                'Nova equipa registada',
                'Equipa Flamingos registou-se no sistema',
                '14:30',
                Icons.add_circle,
                Colors.green.shade600,
              ),
              const SizedBox(height: 16),
              _buildActivityItem(
                'Checkpoint atualizado',
                'Posto de Tira-Chapéu foi configurado com sucesso',
                '13:45',
                Icons.edit,
                Colors.blue.shade600,
              ),
              const SizedBox(height: 16),
              _buildActivityItem(
                'Novo participante',
                'João Silva juntou-se às Águias do Norte',
                '12:20',
                Icons.person_add,
                Colors.orange.shade600,
              ),
              const SizedBox(height: 16),
              _buildActivityItem(
                'Sistema atualizado',
                'Base de dados sincronizada automaticamente',
                '11:15',
                Icons.sync,
                Colors.purple.shade600,
              ),
            ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatsHeader() {
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

                    final totalVeiculos = veiculosSnapshot.data!.docs.length;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCompactStatIndicator(
                          Icons.groups,
                          'Equipas',
                          totalEquipas,
                        ),
                        _buildCompactStatIndicator(
                          Icons.local_gas_station,
                          'Checkpoints',
                          totalCheckpoints,
                        ),
                        _buildCompactStatIndicator(
                          Icons.person,
                          'Participantes',
                          totalParticipantes,
                        ),
                        _buildCompactStatIndicator(
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

  Widget _buildCompactStatIndicator(IconData icon, String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(77)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showRankingManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const RankingManagementDialog(),
    );
  }
}

// ================================
// RANKING MANAGEMENT DIALOG
// ================================

class RankingManagementDialog extends StatefulWidget {
  const RankingManagementDialog({super.key});

  @override
  State<RankingManagementDialog> createState() =>
      _RankingManagementDialogState();
}

class _RankingManagementDialogState extends State<RankingManagementDialog> {
  bool _isRecalculating = false;
  DateTime? _lastUpdate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.leaderboard, color: Colors.red.shade600),
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
            const Text('• Atualização automática quando participante responde'),
            const Text('• Recálculo manual quando necessário'),
            const Text('• Ordenação por pontuação e checkpoints'),
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
          label: Text(_isRecalculating ? 'Recalculando...' : 'Recalcular'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
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
