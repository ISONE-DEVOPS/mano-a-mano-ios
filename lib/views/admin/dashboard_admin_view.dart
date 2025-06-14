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
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('equipas').snapshots(),
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
                          FirebaseFirestore.instance
                              .collection('users')
                              .where('tipo', isEqualTo: 'user')
                              .snapshots(),
                      builder: (context, usersSnapshot) {
                        final totalEquipas =
                            equipasSnapshot.data?.docs.length ?? 0;
                        final totalCheckpoints =
                            checkpointsSnapshot.data?.docs.length ?? 0;
                        final totalParticipantes =
                            usersSnapshot.data?.docs.length ?? 0;
                        return Card(
                          elevation: 2,
                          color: Colors.red,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatIndicator(
                                  Icons.groups,
                                  'Total de Equipas',
                                  totalEquipas,
                                ),
                                _buildStatIndicator(
                                  Icons.local_gas_station,
                                  'Total de Checkpoints',
                                  totalCheckpoints,
                                ),
                                _buildStatIndicator(
                                  Icons.person,
                                  'Total de Participantes',
                                  totalParticipantes,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
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
              builder: (context, rankingSnapshot) {
                if (!rankingSnapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final rankingDocs = rankingSnapshot.data!.docs;
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: Future.wait(
                    rankingDocs.map((doc) async {
                      final data = doc.data() as Map<String, dynamic>;
                      final equipaId = data['equipaId'];
                      String nomeEquipa = 'Equipa';
                      if (equipaId != null) {
                        final equipaDoc =
                            await FirebaseFirestore.instance
                                .collection('equipas')
                                .doc(equipaId)
                                .get();
                        nomeEquipa = equipaDoc.data()?['nome'] ?? 'Equipa';
                      }
                      return {
                        'nome': nomeEquipa,
                        'pontuacao': data['pontuacao'] ?? 0,
                      };
                    }),
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final topEquipas = snapshot.data!;
                    return Row(
                      children:
                          topEquipas.map((data) {
                            return Expanded(
                              child: Card(
                                color: AppColors.secondary,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Text(
                                        data['nome'],
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
              builder: (context, rankingSnapshot) {
                if (!rankingSnapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final rankingDocs = rankingSnapshot.data!.docs;
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: Future.wait(
                    rankingDocs.map((doc) async {
                      final data = doc.data() as Map<String, dynamic>;
                      final equipaId = data['equipaId'];
                      String nomeEquipa = '';
                      int checkpointCount = data['checkpointCount'] ?? 0;
                      int pontuacao = data['pontuacao'] ?? 0;
                      if (equipaId != null) {
                        final equipaDoc =
                            await FirebaseFirestore.instance
                                .collection('equipas')
                                .doc(equipaId)
                                .get();
                        nomeEquipa = equipaDoc.data()?['nome'] ?? '';
                      }
                      return {
                        'nome': nomeEquipa,
                        'pontuacao': pontuacao,
                        'checkpointCount': checkpointCount,
                      };
                    }),
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final rankingData = snapshot.data!;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
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
                            rankingData.map((data) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      data['nome'],
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${data['pontuacao']}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${data['checkpointCount']}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    );
                  },
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
                final equipasDocs = snapshot.data!.docs;
                final dataSource = EquipasDataSource(equipasDocs);
                return PaginatedDataTable(
                  header: const Text(
                    'Equipas Inscritas',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Nome da Equipa',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Condutor',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Modelo do Carro',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Matrícula',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  columnSpacing: 12,
                  actions: [
                    TextButton(
                      onPressed: () {
                        if (dataSource.previousPage != null) {
                          dataSource.previousPage!();
                        }
                      },
                      child: const Text(
                        'Anterior',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (dataSource.nextPage != null) {
                          dataSource.nextPage!();
                        }
                      },
                      child: const Text(
                        'Próximo',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  source: dataSource,
                  rowsPerPage: 5,
                  showCheckboxColumn: false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatIndicator(IconData icon, String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
    );
  }
}

class EquipasDataSource extends DataTableSource {
  final List<QueryDocumentSnapshot> equipasDocs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  EquipasDataSource(this.equipasDocs);

  // Dummy nextPage/previousPage for compatibility with actions buttons.
  // Implement proper logic if needed.
  VoidCallback? nextPage;
  VoidCallback? previousPage;

  final Map<String, String> _condutorCache = {};
  final Map<String, String> _modeloCache = {};

  @override
  DataRow? getRow(int index) {
    if (index >= equipasDocs.length) return null;
    final doc = equipasDocs[index];
    final data = doc.data() as Map<String, dynamic>;
    final nome = data['nome'] ?? '';
    final veiculoId = data['veiculoId'];

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(nome, style: const TextStyle(color: Colors.black))),
        DataCell(
          FutureBuilder<String>(
            future: _getCondutorNome(veiculoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text(
                  'Carregando...',
                  style: TextStyle(color: Colors.black),
                );
              }
              return Text(
                snapshot.data ?? '',
                style: const TextStyle(color: Colors.black),
              );
            },
          ),
        ),
        DataCell(
          FutureBuilder<String>(
            future: _getModeloCarro(veiculoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text(
                  'Carregando...',
                  style: TextStyle(color: Colors.black),
                );
              }
              return Text(
                snapshot.data ?? '',
                style: const TextStyle(color: Colors.black),
              );
            },
          ),
        ),
        DataCell(
          FutureBuilder<String>(
            future: _getMatricula(veiculoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text(
                  'Carregando...',
                  style: TextStyle(color: Colors.black),
                );
              }
              return Text(
                snapshot.data ?? '',
                style: const TextStyle(color: Colors.black),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<String> _getCondutorNome(String? veiculoId) async {
    if (veiculoId == null) return '';
    if (_condutorCache.containsKey(veiculoId)) {
      return _condutorCache[veiculoId]!;
    }

    final veiculoDoc =
        await _firestore.collection('veiculos').doc(veiculoId).get();
    final veiculoData = veiculoDoc.data();
    if (veiculoData == null) {
      _condutorCache[veiculoId] = '';
      return '';
    }
    final condutorId = veiculoData['condutorId'];
    if (condutorId == null) {
      _condutorCache[veiculoId] = '';
      return '';
    }
    final condutorDoc =
        await _firestore.collection('users').doc(condutorId).get();
    final condutorData = condutorDoc.data();
    final nome = condutorData?['nome'] ?? '';
    _condutorCache[veiculoId] = nome;
    return nome;
  }

  Future<String> _getModeloCarro(String? veiculoId) async {
    if (veiculoId == null) return '';
    if (_modeloCache.containsKey(veiculoId)) return _modeloCache[veiculoId]!;

    final veiculoDoc =
        await _firestore.collection('veiculos').doc(veiculoId).get();
    final veiculoData = veiculoDoc.data();
    final modelo = veiculoData?['modelo'] ?? '';
    _modeloCache[veiculoId] = modelo;
    return modelo;
  }

  Future<String> _getMatricula(String? veiculoId) async {
    if (veiculoId == null) return '';
    final veiculoDoc =
        await _firestore.collection('veiculos').doc(veiculoId).get();
    final veiculoData = veiculoDoc.data();
    return veiculoData?['matricula'] ?? '';
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => equipasDocs.length;

  @override
  int get selectedRowCount => 0;
}
