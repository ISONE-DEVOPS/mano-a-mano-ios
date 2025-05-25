import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardAdminView extends StatelessWidget {
  const DashboardAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Painel Administrativo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0E0E2C),
      ),
      backgroundColor: const Color(0xFF0E0E2C),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // rolagem suave
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 32.0,
            ), // margem inferior extra
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${FirebaseAuth.instance.currentUser?.displayName ?? 'Administrador'} 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aqui está um resumo da atividade recente.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 600;
                    final cardWidth =
                        isSmallScreen ? constraints.maxWidth : 180.0;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _StatCard(
                          label: 'Total Utilizadores Ativos',
                          valueFuture: FirebaseFirestore.instance
                              .collection('users')
                              .where('ativo', isEqualTo: true)
                              .get()
                              .then((snap) => snap.size.toString()),
                          width: cardWidth,
                        ),
                        _StatCard(
                          label: 'Total Utilizadores',
                          valueFuture: FirebaseFirestore.instance
                              .collection('users')
                              .get()
                              .then((snap) => snap.size.toString()),
                          width: cardWidth,
                        ),
                        _StatCard(
                          label: 'Eventos Ativos',
                          valueFuture: FirebaseFirestore.instance
                              .collection('eventos')
                              .where('ativo', isEqualTo: true)
                              .get()
                              .then((snap) => snap.size.toString()),
                          width: cardWidth,
                        ),
                        _StatCard(
                          label: 'Fotos na Galeria',
                          valueFuture: FirebaseFirestore.instance
                              .collection('galeria')
                              .where('visivel', isEqualTo: true)
                              .get()
                              .then((snap) => snap.size.toString()),
                          width: cardWidth,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Utilizadores Ativos por Mês',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FutureBuilder<List<BarChartGroupData>>(
                  future: _buildMonthlyUserData(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.data!.isEmpty) {
                      return const SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            'Nenhum utilizador ativo nos últimos 6 meses.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          backgroundColor: Colors.transparent,
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const months = [
                                    'Jan',
                                    'Feb',
                                    'Mar',
                                    'Apr',
                                    'May',
                                    'Jun',
                                    'Jul',
                                    'Aug',
                                    'Sep',
                                    'Oct',
                                    'Nov',
                                    'Dec',
                                  ];
                                  return Text(
                                    months[value.toInt()],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                                interval: 1,
                              ),
                            ),
                          ),
                          gridData: FlGridData(show: false),
                          barGroups: snapshot.data!,
                        ),
                      ),
                    );
                  },
                ),
                GridView.count(
                  crossAxisCount:
                      MediaQuery.of(context).size.width < 600 ? 1 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    _DashboardCard(
                      title: 'Utilizadores',
                      icon: Icons.people,
                      onTap: () => Navigator.pushNamed(context, '/users'),
                    ),
                    _DashboardCard(
                      title: 'Eventos',
                      icon: Icons.event,
                      onTap: () => Navigator.pushNamed(context, '/events'),
                    ),
                    _DashboardCard(
                      title: 'Galeria',
                      icon: Icons.image,
                      onTap: () => Navigator.pushNamed(context, '/gallery'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<List<BarChartGroupData>> _buildMonthlyUserData() async {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 5);
    final snap =
        await FirebaseFirestore.instance
            .collection('users')
            .where('ativo', isEqualTo: true)
            .where('created_at', isGreaterThanOrEqualTo: sixMonthsAgo)
            .get();

    final Map<int, int> monthCount = {};
    for (int i = 0; i < 6; i++) {
      final month = DateTime(now.year, now.month - i).month;
      monthCount[month] = 0;
    }

    for (var doc in snap.docs) {
      if (!doc.data().containsKey('created_at') || doc['created_at'] == null) {
        continue;
      }
      final createdAt = (doc['created_at'] as Timestamp).toDate();
      final m = createdAt.month;
      if (monthCount.containsKey(m)) {
        monthCount[m] = monthCount[m]! + 1;
      }
    }

    final List<BarChartGroupData> groups = [];
    final orderedMonths = monthCount.keys.toList()..sort();
    for (var i = 0; i < orderedMonths.length; i++) {
      final month = orderedMonths[i];
      final count = monthCount[month]!;
      groups.add(
        BarChartGroupData(
          x: month,
          barRods: [
            BarChartRodData(toY: count.toDouble(), color: Colors.amber),
          ],
        ),
      );
    }
    final hasData = groups.any((g) => g.barRods.any((r) => r.toY > 0));
    if (!hasData) return [];
    return groups;
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final void Function()? onTap;

  const _DashboardCard({required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white10,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.amber),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final Future<String> valueFuture;
  final double width;

  const _StatCard({
    required this.label,
    required this.valueFuture,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: FutureBuilder<String>(
          future: valueFuture,
          builder: (context, snapshot) {
            final value = snapshot.data ?? '...';
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(color: Colors.white)),
              ],
            );
          },
        ),
      ),
    );
  }
}
