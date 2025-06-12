import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';

class ParticipantesView extends StatelessWidget {
  const ParticipantesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text(
          'Participantes',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Exportar CSV',
            onPressed: () async {
              final snapshot =
                  await FirebaseFirestore.instance.collection('users').get();
              final buffer = StringBuffer();
              buffer.writeln(
                'Nome,Email,Telefone,Emergência,T-Shirt,EquipaID,EventoNome',
              );

              for (var doc in snapshot.docs) {
                final d = doc.data();
                buffer.writeln(
                  [
                        d['nome'] ?? '',
                        d['email'] ?? '',
                        d['telefone'] ?? '',
                        d['emergencia'] ?? '',
                        d['tshirt'] ?? '',
                        d['equipaId'] ?? '',
                        d['eventoNome'] ?? '',
                      ]
                      .map((v) => '"${v.toString().replaceAll('"', '""')}"')
                      .join(','),
                );
              }

              // Salvar local ou compartilhar via plataforma
              if (!context.mounted) return;
              await showDialog(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: const Text('CSV Gerado'),
                      content: SingleChildScrollView(
                        child: Text(buffer.toString()),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fechar'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: false)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum participante encontrado.',
                style: TextStyle(color: Colors.black),
              ),
            );
          }

          final users = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              columns: const [
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
                    'Email',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Telefone',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Emergência',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'T-Shirt',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Equipa',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Evento',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Ações',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              rows:
                  users.map((doc) {
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
                            data['email'] ?? '',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        DataCell(
                          Text(
                            data['telefone'] ?? '',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        DataCell(
                          Text(
                            data['emergencia'] ?? '',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        DataCell(
                          Text(
                            data['tshirt'] ?? '',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        DataCell(
                          (data['equipaId'] == null ||
                                  data['equipaId'].toString().isEmpty)
                              ? const Text(
                                'N/A',
                                style: TextStyle(color: Colors.black),
                              )
                              : FutureBuilder<DocumentSnapshot>(
                                future:
                                    (data['equipaId'] == null ||
                                            data['equipaId'].toString().isEmpty)
                                        ? null
                                        : FirebaseFirestore.instance
                                            .collection('equipas')
                                            .doc(data['equipaId'])
                                            .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.none) {
                                    return const Text(
                                      'Equipa não definida',
                                      style: TextStyle(color: Colors.black),
                                    );
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Text(
                                      '...',
                                      style: TextStyle(color: Colors.black),
                                    );
                                  }
                                  if (!snapshot.hasData ||
                                      !snapshot.data!.exists) {
                                    return const Text(
                                      'N/A',
                                      style: TextStyle(color: Colors.black),
                                    );
                                  }
                                  final nomeEquipa =
                                      snapshot.data!.get('nome') ?? '';
                                  return Text(
                                    nomeEquipa,
                                    style: const TextStyle(color: Colors.black),
                                  );
                                },
                              ),
                        ),
                        DataCell(
                          Text(
                            data['eventoNome'] ?? '',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.group, color: Colors.blueGrey),
                                onPressed: () async {
                                  final veiculoId = data['veiculoId'];
                                  if (veiculoId == null ||
                                      veiculoId.toString().trim().isEmpty) {
                                    if (!context.mounted) return;
                                    showDialog(
                                      context: context,
                                      builder:
                                          (_) => const AlertDialog(
                                            title: Text('Acompanhantes'),
                                            content: Text(
                                              'ID do veículo não definido.',
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                    );
                                    return;
                                  }
                                  final veiculoDoc =
                                      await FirebaseFirestore.instance
                                          .collection('veiculos')
                                          .doc(veiculoId)
                                          .get();
                                  final veiculo = veiculoDoc.data();
                                  final acompanhantes =
                                      veiculo?['passageiros'] ?? [];
                                  if (!context.mounted) return;
                                  showDialog(
                                    context: context,
                                    builder: (_) {
                                      return AlertDialog(
                                        title: const Text(
                                          'Acompanhantes',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        content:
                                            acompanhantes.isEmpty
                                                ? const Text(
                                                  'Nenhum acompanhante encontrado.',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                )
                                                : Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children:
                                                      (acompanhantes as List).map((
                                                        p,
                                                      ) {
                                                        return ListTile(
                                                          title: Text(
                                                            'Nome: ${p['nome'] ?? ''}',
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .black,
                                                                ),
                                                          ),
                                                          subtitle: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'Telefone: ${p['telefone'] ?? ''}',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .black,
                                                                ),
                                                              ),
                                                              Text(
                                                                'T-Shirt: ${p['tshirt'] ?? ''}',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .black,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }).toList(),
                                                ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text(
                                              'Fechar',
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.directions_car,
                                  color: Colors.green,
                                ),
                                onPressed: () async {
                                  final veiculoId = data['veiculoId'];
                                  if (veiculoId == null) return;

                                  final veiculoDoc =
                                      await FirebaseFirestore.instance
                                          .collection('veiculos')
                                          .doc(veiculoId)
                                          .get();
                                  final veiculo = veiculoDoc.data();

                                  if (!context.mounted) return;
                                  showDialog(
                                    context: context,
                                    builder: (ctx) {
                                      return AlertDialog(
                                        title: const Text(
                                          'Veículo',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        content:
                                            veiculo == null
                                                ? const Text(
                                                  'Veículo não encontrado.',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                )
                                                : Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Marca: ${veiculo['marca'] ?? ''}',
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Modelo: ${veiculo['modelo'] ?? ''}',
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Matrícula: ${veiculo['matricula'] ?? ''}',
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    // Text(
                                                    //   'Condutor: $nomeCondutor',
                                                    //   style: const TextStyle(
                                                    //     color: Colors.black,
                                                    //   ),
                                                    // ),
                                                    const SizedBox(height: 10),
                                                    TextField(
                                                      controller:
                                                          TextEditingController(
                                                            text:
                                                                veiculo['registro'] ??
                                                                '',
                                                          ),
                                                      decoration: const InputDecoration(
                                                        labelText: 'Distíco',
                                                        labelStyle: TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                        enabledBorder:
                                                            UnderlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                    color:
                                                                        Colors
                                                                            .black,
                                                                  ),
                                                            ),
                                                      ),
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                      ),
                                                      onSubmitted: (
                                                        value,
                                                      ) async {
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                              'veiculos',
                                                            )
                                                            .doc(veiculoId)
                                                            .update({
                                                              'registro': value,
                                                            });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text(
                                              'Fechar',
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              // lógica de edição do veículo (se necessário)
                                            },
                                            child: const Text(
                                              'Editar',
                                              style: TextStyle(
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.info_outline,
                                  color: Colors.deepPurple,
                                ),
                                tooltip: 'Ver detalhes',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (_) => AlertDialog(
                                          title: const Text(
                                            'Detalhes do Participante',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Nome: ${data['nome'] ?? ''}',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Text(
                                                  'Email: ${data['email'] ?? ''}',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Text(
                                                  'Telefone: ${data['telefone'] ?? ''}',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Text(
                                                  'Emergência: ${data['emergencia'] ?? ''}',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Text(
                                                  'T-Shirt: ${data['tshirt'] ?? ''}',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Text(
                                                  'Equipa: ${data['equipaId'] ?? 'N/A'}',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Text(
                                                  'Evento: ${data['eventoNome'] ?? ''}',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  '--- Equipa ---',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                FutureBuilder<DocumentSnapshot>(
                                                  future:
                                                      (data['equipaId'] ==
                                                                  null ||
                                                              data['equipaId']
                                                                  .toString()
                                                                  .isEmpty)
                                                          ? null
                                                          : FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'equipas',
                                                              )
                                                              .doc(
                                                                data['equipaId'],
                                                              )
                                                              .get(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState.none) {
                                                      return const Text(
                                                        'Equipa não definida',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                      );
                                                    }
                                                    if (!snapshot.hasData ||
                                                        !snapshot
                                                            .data!
                                                            .exists) {
                                                      return const Text(
                                                        'Equipa não encontrada',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                      );
                                                    }
                                                    final equipa =
                                                        snapshot.data!.data()
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >;
                                                    return Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Nome da Equipa: ${equipa['nome'] ?? ''}',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Hino: ${equipa['hino'] ?? ''}',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Pontuação Total: ${equipa['pontuacaoTotal'] ?? 0}',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  '--- Veículo ---',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                FutureBuilder<DocumentSnapshot>(
                                                  future:
                                                      (data['veiculoId'] ==
                                                                  null ||
                                                              data['veiculoId']
                                                                  .toString()
                                                                  .isEmpty)
                                                          ? null
                                                          : FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'veiculos',
                                                              )
                                                              .doc(
                                                                data['veiculoId'],
                                                              )
                                                              .get(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState.none) {
                                                      return const Text(
                                                        'Veículo não definido',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                      );
                                                    }
                                                    if (!snapshot.hasData ||
                                                        !snapshot
                                                            .data!
                                                            .exists) {
                                                      return const Text(
                                                        'Veículo não encontrado',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                      );
                                                    }
                                                    final v =
                                                        snapshot.data!.data()
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >;
                                                    return Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Marca: ${v['marca'] ?? ''}',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Modelo: ${v['modelo'] ?? ''}',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Matrícula: ${v['matricula'] ?? ''}',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  '--- Acompanhantes ---',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                FutureBuilder<DocumentSnapshot>(
                                                  future:
                                                      (data['veiculoId'] ==
                                                                  null ||
                                                              data['veiculoId']
                                                                  .toString()
                                                                  .isEmpty)
                                                          ? null
                                                          : FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'veiculos',
                                                              )
                                                              .doc(
                                                                data['veiculoId'],
                                                              )
                                                              .get(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState.none) {
                                                      return const Text(
                                                        'Veículo não definido',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                      );
                                                    }
                                                    if (!snapshot.hasData ||
                                                        !snapshot
                                                            .data!
                                                            .exists) {
                                                      return const Text(
                                                        'Sem acompanhantes',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                      );
                                                    }
                                                    final passageiros =
                                                        (snapshot.data!.get(
                                                                  'passageiros',
                                                                ) ??
                                                                [])
                                                            as List;
                                                    if (passageiros.isEmpty) {
                                                      return const Text(
                                                        'Sem acompanhantes',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                      );
                                                    }
                                                    return Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children:
                                                          passageiros.map<
                                                            Widget
                                                          >((p) {
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 4,
                                                                  ),
                                                              child: Text(
                                                                '• ${p['nome']} - ${p['telefone']} - T-Shirt: ${p['tshirt']}',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .black,
                                                                ),
                                                              ),
                                                            );
                                                          }).toList(),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              child: const Text(
                                                'Fechar',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          );
        },
      ),
    );
  }
}
