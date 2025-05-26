import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mano_mano_dashboard/theme/app_backend_theme.dart';

class DashboardAdminView extends StatefulWidget {
  const DashboardAdminView({super.key});

  @override
  State<DashboardAdminView> createState() => _DashboardAdminViewState();
}

class _DashboardAdminViewState extends State<DashboardAdminView> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Theme(
      data: AppBackendTheme.dark,
      child: Scaffold(
        appBar: AppBar(toolbarHeight: 0, backgroundColor: Colors.black),
        backgroundColor: const Color(0xFF0E0E2C),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/Logo_Shell_KM.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(height: 24);
                      }
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      final nome = data?['nome'] ?? 'Administrador';
                      return Text(
                        'Olá, $nome 👋',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: screenWidth < 400 ? 16 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aqui está um resumo da atividade recente.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: screenWidth < 400 ? 12 : 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ranking dos Carros',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: screenWidth < 400 ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: _opacity,
                    child: Center(
                      child: SizedBox(
                        height: 300,
                        width: screenWidth < 600 ? screenWidth - 32 : 600,
                        child: _buildBarChart(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('cars')
              .orderBy('pontuacao_total', descending: true)
              .limit(3)
              .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final bars =
            docs.mapIndexed((i, doc) {
              final pontos = (doc['pontuacao_total'] ?? 0) as int;
              final isFirst = i == 0;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: pontos.toDouble(),
                    width: isFirst ? 26 : 20,
                    color: isFirst ? Colors.greenAccent : Colors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
                showingTooltipIndicators: [0],
              );
            }).toList();

        final labels =
            docs
                .map(
                  (doc) => (doc['matricula'] ?? '---').toString().toUpperCase(),
                )
                .toList();

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceEvenly,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.blueGrey.shade700,
                tooltipMargin: 12,
                direction: TooltipDirection.top,
                getTooltipItem: (group, _, __, ___) {
                  final doc = docs[group.x.toInt()];
                  final matricula = doc['matricula'] ?? '---';
                  final pontos = doc['pontuacao_total'] ?? 0;
                  final equipa = doc['nome_equipa'] ?? doc['modelo'] ?? '';
                  return BarTooltipItem(
                    '$matricula\n$equipa\n$pontos pontos',
                    const TextStyle(color: Colors.white),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      labels[index],
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: bars,
            gridData: FlGridData(show: false),
          ),
        );
      },
    );
  }
}
