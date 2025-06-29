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

    final result = await Future.wait(
      checkpointSnap.docs.map((doc) async {
        final data = doc.data();
        final nome = data['nome']?.toString() ?? '';
        final List<Map<String, dynamic>> jogos = [];

        final List<Future<Map<String, dynamic>?>> jogoFetches = [];

        if (data['jogoRef'] != null && data['jogoRef'] is DocumentReference) {
          jogoFetches.add(
            (data['jogoRef'] as DocumentReference).get().then((doc) {
              if (!doc.exists) return null;
              final d = doc.data() as Map<String, dynamic>?;
              return d == null
                  ? null
                  : {
                    'nome': d['nome'] ?? 'Sem nome',
                    'tipo': d['tipo'] ?? 'N/D',
                    'pontos': d['pontos'] ?? 0,
                  };
            }),
          );
        }

        if (data['jogosRefs'] != null && data['jogosRefs'] is List) {
          for (var ref in data['jogosRefs']) {
            if (ref is DocumentReference) {
              jogoFetches.add(
                ref.get().then((doc) {
                  if (!doc.exists) return null;
                  final d = doc.data() as Map<String, dynamic>?;
                  return d == null
                      ? null
                      : {
                        'nome': d['nome'] ?? 'Sem nome',
                        'tipo': d['tipo'] ?? 'N/D',
                        'pontos': d['pontos'] ?? 0,
                      };
                }),
              );
            }
          }
        }

        final jogoResults = await Future.wait(jogoFetches);
        jogos.addAll(jogoResults.whereType<Map<String, dynamic>>());

        return {'nome': nome, 'jogos': jogos};
      }).toList(),
    );

    setState(() {
      _checkpoints = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Jogos por Checkpoint',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFFDD1D21),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sports_esports, color: Colors.white),
            onPressed:
                () =>
                    Navigator.of(context).pushReplacementNamed('/staff/jogos'),
            tooltip: 'Voltar aos Jogos',
          ),
          const SizedBox(width: 8),
        ],
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
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Tipo: ${jogo['tipo']}'),
                                    if (jogo.containsKey('pontos'))
                                      Text('Pontos: ${jogo['pontos']}'),
                                  ],
                                ),
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
