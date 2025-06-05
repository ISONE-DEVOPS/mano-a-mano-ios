import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';

class DashboardAdminView extends StatelessWidget {
  const DashboardAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard(
                  Icons.groups,
                  'Equipas',
                  FirebaseFirestore.instance.collection('equipas'),
                ),
                _buildStatCard(
                  Icons.local_gas_station,
                  'Checkpoints',
                  FirebaseFirestore.instance.collection('checkpoints'),
                ),
                _buildStatCard(
                  Icons.emoji_events,
                  'Pontuações',
                  FirebaseFirestore.instance.collection('ranking'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              '🏆 Top 3 Equipas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('ranking')
                      .orderBy('pontuacao', descending: true)
                      .limit(3)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;
                return Row(
                  children:
                      docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Expanded(
                          child: Card(
                            color: AppColors.secondary,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    data['nome'] ?? 'Equipa',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${data['pontuacao']} pts',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              '📊 Ranking Geral',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('ranking')
                      .orderBy('pontuacao', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;
                return DataTable(
                  dataRowColor: WidgetStateProperty.all(Colors.black12),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Equipa',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Pontuação',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Checkpoints',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                  rows:
                      docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                data['nome'] ?? '',
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${data['pontuacao']}',
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${data['checkpointCount']}',
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              '📝 Equipas Inscritas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('equipas').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;
                return FutureBuilder<List<DataRow>>(
                  future: _buildEquipasRows(docs),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    return DataTable(
                      dataRowColor: WidgetStateProperty.all(Colors.black12),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Nome da Equipa',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Condutor',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Marca do Carro',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                      rows: snapshot.data!,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, CollectionReference ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref.snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Expanded(
          child: Card(
            elevation: 2,
            color: Colors.red,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(icon, size: 32, color: Colors.blue),
                  const SizedBox(height: 8),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<List<DataRow>> _buildEquipasRows(
  List<QueryDocumentSnapshot> docs,
) async {
  List<DataRow> rows = [];

  for (final doc in docs) {
    final data = doc.data() as Map<String, dynamic>;
    final nome = data['nome'] ?? '';
    final veiculoId = data['veiculoId'];

    String marca = '';
    String condutor = '';

    if (veiculoId != null) {
      final veiculoDoc =
          await FirebaseFirestore.instance
              .collection('veiculos')
              .doc(veiculoId)
              .get();
      final veiculoData = veiculoDoc.data();
      marca = veiculoData?['marca'] ?? '';
      final condutorId = veiculoData?['condutorId'];
      if (condutorId != null) {
        final condutorDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(condutorId)
                .get();
        final condutorData = condutorDoc.data();
        condutor = condutorData?['nome'] ?? '';
      }
    }

    rows.add(
      DataRow(
        cells: [
          DataCell(Text(nome, style: const TextStyle(color: Colors.black))),
          DataCell(Text(condutor, style: const TextStyle(color: Colors.black))),
          DataCell(Text(marca, style: const TextStyle(color: Colors.black))),
        ],
      ),
    );
  }

  return rows;
}
