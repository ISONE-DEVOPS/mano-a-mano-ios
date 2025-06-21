import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TshirtReportView extends StatefulWidget {
  const TshirtReportView({super.key});

  @override
  State<TshirtReportView> createState() => _TshirtReportViewState();
}

class _TshirtReportViewState extends State<TshirtReportView> {
  String grupoSelecionado = 'Todos';
  final List<String> grupos = ['Todos', 'A', 'B'];

  Future<Map<String, Map<String, int>>> _fetchData() async {
    final equipesSnapshot =
        await FirebaseFirestore.instance.collection('equipas').get();
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    // Map<equipaId, Map<tamanho, count>>
    final Map<String, Map<String, int>> report = {};
    final Map<String, String> teamNames = {};

    for (final team in equipesSnapshot.docs) {
      final grupo = team['grupo'] ?? 'Todos';
      if (grupoSelecionado == 'Todos' || grupoSelecionado == grupo) {
        final teamName = team['nome'] ?? 'Sem nome';
        report[team.id] = {};
        teamNames[team.id] = teamName;
      }
    }

    for (final user in usersSnapshot.docs) {
      final data = user.data();
      final teamId = data['equipaId'];
      final tamanho = data['tshirt'] ?? 'desconhecido';

      if (report.containsKey(teamId)) {
        // teamName já está armazenado em teamNames para uso posterior
        report[teamId]![tamanho] = (report[teamId]![tamanho] ?? 0) + 1;
      }
    }

    // Convert report keys from teamId to teamName for display
    final Map<String, Map<String, int>> namedReport = {};
    report.forEach((teamId, sizes) {
      final teamName = teamNames[teamId] ?? 'Sem nome';
      namedReport[teamName] = sizes;
    });

    return namedReport;
  }

  Future<void> _exportToCsv(Map<String, Map<String, int>> data) async {
    final buffer = StringBuffer();
    buffer.writeln('Equipa,Tamanho,Quantidade');

    for (final team in data.entries) {
      for (final size in team.value.entries) {
        buffer.writeln('${team.key},${size.key},${size.value}');
      }
    }

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/tshirt_report.csv';
    final file = File(path);
    await file.writeAsString(buffer.toString());

    await SharePlus.instance.share(
      ShareParams(
        text:
            'Relatório de Tamanhos por Equipa\n\nArquivo disponível em: $path',
        subject: 'Relatório de Tamanhos por Equipa',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tamanhos por Equipa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              final snapshot = await _fetchData();
              await _exportToCsv(snapshot);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: grupoSelecionado,
              onChanged: (value) {
                setState(() {
                  grupoSelecionado = value!;
                });
              },
              items:
                  grupos
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<Map<String, Map<String, int>>>(
                future: _fetchData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Nenhum dado encontrado'));
                  }

                  final data = snapshot.data!;
                  return ListView(
                    children:
                        data.entries.map((entry) {
                          final teamName = entry.key;
                          final sizes = entry.value;

                          return Card(
                            child: ExpansionTile(
                              title: Text(teamName),
                              children:
                                  sizes.entries.map((s) {
                                    return ListTile(
                                      title: Text('Tamanho ${s.key}'),
                                      trailing: Text('${s.value}'),
                                    );
                                  }).toList(),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
