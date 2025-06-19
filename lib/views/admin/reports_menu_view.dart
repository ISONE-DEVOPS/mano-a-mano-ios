import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReportsMenuView extends StatelessWidget {
  const ReportsMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      {"title": "Relatório Geral do Evento", "route": "/report-geral"},
      {"title": "Relatório de Checkpoints", "route": "/report-checkpoints"},
      {"title": "Relatório de Participação", "route": "/report-participacao"},
      {"title": "Relatório de Pontuação", "route": "/report-pontuacao"},
      {
        "title": "Relatório de Avaliação Pós-Evento",
        "route": "/report-avaliacao",
      },
      {
        "title": "Relatório de Team Building Final",
        "route": "/report-team-building",
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Menu de Relatórios")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final report = reports[index];
          return ElevatedButton.icon(
            icon: const Icon(Icons.insert_drive_file_outlined),
            label: Text(report["title"]!),
            onPressed: () => Get.toNamed(report["route"]!),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              textStyle: const TextStyle(fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}
