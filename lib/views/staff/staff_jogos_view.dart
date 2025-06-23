import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/widgets/shared/staff_nav_bottom.dart';

class StaffJogosView extends StatefulWidget {
  const StaffJogosView({super.key});

  @override
  State<StaffJogosView> createState() => _StaffJogosViewState();
}

class _StaffJogosViewState extends State<StaffJogosView> {
  List<Map<String, dynamic>> _checkpoints = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCheckpoints();
  }

  Future<void> _fetchCheckpoints() async {
    final checkpointSnap =
        await FirebaseFirestore.instance
            .collection('editions')
            .doc('shell_2025')
            .collection('events')
            .doc('shell_km_02')
            .collection('checkpoints')
            .get();

    List<Map<String, dynamic>> result = [];

    for (var doc in checkpointSnap.docs) {
      final data = doc.data();
      final nome = data['nome']?.toString() ?? '';

      List<Map<String, dynamic>> jogos = [];

      // Adiciona jogo único (jogoRef)
      if (data['jogoRef'] != null && data['jogoRef'] is DocumentReference) {
        final ref = data['jogoRef'] as DocumentReference;
        final jogoDoc = await ref.get();
        if (jogoDoc.exists) {
          final rawData = jogoDoc.data();
          if (rawData == null) continue;
          final jogoData = rawData as Map<String, dynamic>;
          jogos.add({
            'nome': jogoData['nome'] ?? 'Sem nome',
            'tipo': jogoData['tipo'] ?? 'N/D',
          });
        }
      }

      // Adiciona múltiplos jogos (jogosRefs)
      if (data['jogosRefs'] != null && data['jogosRefs'] is List) {
        for (var ref in data['jogosRefs']) {
          if (ref is DocumentReference) {
            final jogoDoc = await ref.get();
            if (jogoDoc.exists) {
              final rawData = jogoDoc.data();
              if (rawData == null) continue;
              final jogoData = rawData as Map<String, dynamic>;
              jogos.add({
                'nome': jogoData['nome'] ?? 'Sem nome',
                'tipo': jogoData['tipo'] ?? 'N/D',
              });
            }
          }
        }
      }

      result.add({'nome': nome, 'jogos': jogos});
    }

    setState(() {
      _checkpoints = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jogos por Checkpoint'),
        backgroundColor: Colors.black,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _checkpoints.length,
                itemBuilder: (context, index) {
                  final checkpoint = _checkpoints[index];
                  final jogos =
                      (checkpoint['jogos'] ?? []) as List<Map<String, dynamic>>;
                  return ExpansionTile(
                    title: Text(checkpoint['nome'] ?? 'Sem nome'),
                    trailing: Icon(
                      jogos.length > 1
                          ? Icons.stacked_line_chart
                          : Icons.videogame_asset,
                    ),
                    children:
                        jogos
                            .map(
                              (jogo) => ListTile(
                                title: Text(jogo['nome']),
                                subtitle: Text('Tipo: ${jogo['tipo']}'),
                                leading: const Icon(Icons.sports_esports),
                              ),
                            )
                            .toList(),
                  );
                },
              ),
      bottomNavigationBar: const StaffNavBottom(),
    );
  }
}
