// ================================
// DASHBOARD ADMIN VIEW - UI MELHORADO PARA MAIOR VISIBILIDADE
// ================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/services/ranking_service.dart';
//import 'package:mano_mano_dashboard/widgets/shared/admin_page_wrapper.dart';
import 'qualification_grid_screen.dart';
import 'ranking_screen.dart';

class DashboardAdminView extends StatefulWidget {
  const DashboardAdminView({super.key});

  @override
  State<DashboardAdminView> createState() => _DashboardAdminViewState();
}

class _DashboardAdminViewState extends State<DashboardAdminView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildEnhancedHeader(context),
          Expanded(child: _buildImprovedMainDashboard(context)),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFDC2626), // Shell Red Primary
            const Color(0xFFEF4444), // Shell Red Light
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withAlpha(64),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            // Linha principal do header - mais compacta
            Row(
              children: [
                // Logo/Ícone compacto
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withAlpha(77),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.local_gas_station_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 16),

                // Título compacto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SHELL AO KM 2025',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Dashboard Administrativo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withAlpha(20),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Informações do usuário
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withAlpha(77),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white.withAlpha(77),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'linda@pagali.cv',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Botões de ação principais compactos
                Row(
                  children: [
                    _buildCompactActionButton(
                      context,
                      'Grelha',
                      Icons.grid_view_rounded,
                      const Color(0xFF2563EB),
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
                      Icons.leaderboard_rounded,
                      const Color(0xFF059669),
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

            const SizedBox(height: 16),

            // Estatísticas em tempo real mais compactas
            _buildCompactStatsRow(),
          ],
        ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(80, 32),
        ),
      ),
    );
  }

  Widget _buildImprovedMainDashboard(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção principal mais visível
          _buildSectionHeader(
            'Visão Geral do Rally',
            'Monitoramento completo do evento em tempo real',
            Icons.dashboard_rounded,
            const Color(0xFFDC2626),
          ),

          const SizedBox(height: 24),

          // Cards de resumo com melhor hierarquia visual
          _buildEnhancedSummaryCards(),

          const SizedBox(height: 32),

          // Seção de gestão com layout melhorado
          _buildImprovedQuickManagement(context),

          const SizedBox(height: 32),

          // Layout side-by-side para melhor aproveitamento do espaço
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informações dos percursos
              Expanded(flex: 3, child: _buildEnhancedRouteInformation()),

              const SizedBox(width: 24),

              // Atividade recente mais compacta
              Expanded(flex: 2, child: _buildCompactRecentActivity()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [color.withAlpha(13), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(5), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(77),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildHighVisibilityCard(
            'Rally Ativo',
            'Shell ao KM 2025',
            'Rally Paper • 2ª Edição',
            Icons.event_available_rounded,
            const Color(0xFF2563EB),
            Colors.blue.shade50,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildHighVisibilityCard(
            'Status Sistema',
            'Operacional',
            'Todos os serviços ativos',
            Icons.check_circle_rounded,
            const Color(0xFF059669),
            Colors.green.shade50,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildHighVisibilityCard(
            'Data do Evento',
            '28 Jun 2025',
            'Sábado • 14h30 Kebra Canela',
            Icons.calendar_today_rounded,
            const Color(0xFFEA580C),
            Colors.orange.shade50,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildHighVisibilityCard(
            'Checkpoints',
            '8 Postos Shell',
            'Percursos A e B configurados',
            Icons.location_on_rounded,
            const Color(0xFFDC2626),
            Colors.red.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildHighVisibilityCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    Color backgroundColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(51), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone com background colorido
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(77)),
            ),
            child: Icon(icon, color: color, size: 32),
          ),

          const SizedBox(height: 20),

          // Valor principal em destaque
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),

          const SizedBox(height: 8),

          // Título
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 4),

          // Subtítulo
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovedQuickManagement(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da seção
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withAlpha(77),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.tune_rounded,
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
                      'Gestão Rápida',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Acesso direto às principais funcionalidades',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Grid de ações melhorado
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildEnhancedActionCard(
                'Grelha Qualificação',
                'Visualizar posições organizadas por grupos A e B',
                Icons.grid_view_rounded,
                const Color(0xFF2563EB),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QualificationGridScreen(),
                  ),
                ),
              ),
              _buildEnhancedActionCard(
                'Ranking Completo',
                'Classificação geral e pontuações detalhadas',
                Icons.leaderboard_rounded,
                const Color(0xFF059669),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RankingScreen(),
                  ),
                ),
              ),
              _buildEnhancedActionCard(
                'Recalcular Ranking',
                'Atualizar pontuações e corrigir inconsistências',
                Icons.refresh_rounded,
                const Color(0xFFEA580C),
                () => _showRankingManagement(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActionCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(26),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withAlpha(13), color.withAlpha(5)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(77), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícone
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),

                const SizedBox(height: 16),

                // Título
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),

                const SizedBox(height: 8),

                // Descrição
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // Indicador de ação
                Row(
                  children: [
                    Text(
                      'Abrir',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedRouteInformation() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withAlpha(77),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.route_rounded,
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
                      'Percursos do Rally',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Rotas sincronizadas com dados reais',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildRouteCardsFromFirestore(),
        ],
      ),
    );
  }

  Widget _buildRouteCardsFromFirestore() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('editions')
          .doc('shell_2025')
          .collection('events')
          .doc('shell_km_02')
          .collection('checkpoints')
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final grupoA = <MapEntry<int, String>>[];
        final grupoB = <MapEntry<int, String>>[];

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final descricao = data['descricao']?.toString() ?? doc.id;
          final percurso = data['percurso']?.toString().toUpperCase();
          if (percurso == 'A' || percurso == 'AMBOS') {
            final ordemA = data['ordemA'];
            if (ordemA is int) grupoA.add(MapEntry(ordemA, descricao));
          }
          if (percurso == 'B' || percurso == 'AMBOS') {
            final ordemB = data['ordemB'];
            if (ordemB is int) grupoB.add(MapEntry(ordemB, descricao));
          }
        }

        grupoA.sort((a, b) => a.key.compareTo(b.key));
        grupoB.sort((a, b) => a.key.compareTo(b.key));

        return Column(
          children: [
            if (grupoA.isNotEmpty)
              _buildDetailedRouteCard(
                'GRUPO A',
                'Ordem oficial dos checkpoints',
                grupoA.map((e) => e.value).toList(),
                const Color(0xFF2563EB),
                Icons.north_rounded,
              ),
            const SizedBox(height: 16),
            if (grupoB.isNotEmpty)
              _buildDetailedRouteCard(
                'GRUPO B',
                'Ordem oficial dos checkpoints',
                grupoB.map((e) => e.value).toList(),
                const Color(0xFF059669),
                Icons.south_rounded,
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailedRouteCard(
    String title,
    String description,
    List<String> checkpoints,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withAlpha(13), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(77), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do percurso
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Lista de checkpoints
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                checkpoints.asMap().entries.map((entry) {
                  final index = entry.key;
                  final checkpoint = entry.value;
                  final isStart = index == 0;
                  final isEnd = index == checkpoints.length - 1;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isStart || isEnd
                              ? color.withAlpha(38)
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isStart || isEnd
                                ? color.withAlpha(128)
                                : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                isStart || isEnd ? color : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          checkpoint,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                isStart || isEnd ? color : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0891B2).withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Atividade Recente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Lista de atividades
          Column(
            children: [
              _buildCompactActivityItem(
                'Sistema atualizado',
                'Base de dados sincronizada',
                '2 min',
                Icons.sync_rounded,
                const Color(0xFF7C3AED),
              ),
              _buildCompactActivityItem(
                'Nova equipa',
                'Equipa Flamingos registada',
                '5 min',
                Icons.add_circle_rounded,
                const Color(0xFF059669),
              ),
              _buildCompactActivityItem(
                'Checkpoint configurado',
                'Posto Tira-Chapéu ativo',
                '8 min',
                Icons.edit_rounded,
                const Color(0xFF2563EB),
              ),
              _buildCompactActivityItem(
                'Novo participante',
                'João Silva - Águias do Norte',
                '12 min',
                Icons.person_add_rounded,
                const Color(0xFFEA580C),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActivityItem(
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(10),
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
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatsRow() {
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
                      children: [
                        Expanded(
                          child: _buildCompactStatCard(
                            Icons.groups_rounded,
                            'Equipas',
                            totalEquipas,
                            'registadas',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactStatCard(
                            Icons.local_gas_station_rounded,
                            'Checkpoints',
                            totalCheckpoints,
                            'configurados',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactStatCard(
                            Icons.person_rounded,
                            'Participantes',
                            totalParticipantes,
                            'inscritos',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildCompactStatCard(
                            Icons.directions_car_rounded,
                            'Veículos',
                            totalVeiculos,
                            'registados',
                          ),
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

  Widget _buildCompactStatCard(
    IconData icon,
    String label,
    int count,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(77), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withAlpha(204),
              fontWeight: FontWeight.w500,
            ),
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
// RANKING MANAGEMENT DIALOG - MELHORADO
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header melhorado
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.leaderboard_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestão do Ranking',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Recalcular pontuações do sistema',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Conteúdo
            if (_lastUpdate != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Última atualização: ${_formatDateTime(_lastUpdate!)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Informações do sistema
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_rounded,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Informações do Sistema',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Atualização automática quando participante responde',
                  ),
                  const Text('• Recálculo manual quando necessário'),
                  const Text(
                    '• Ordenação por pontuação e checkpoints visitados',
                  ),
                  const Text('• Sincronização em tempo real'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Fechar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isRecalculating ? null : _recalculateRanking,
                    icon:
                        _isRecalculating
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.refresh_rounded),
                    label: Text(
                      _isRecalculating ? 'Recalculando...' : 'Recalcular Agora',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Ranking recalculado com sucesso!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isRecalculating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erro ao recalcular: $e',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} às ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
