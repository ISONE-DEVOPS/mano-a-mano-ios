import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;

class ParticipantesView extends StatelessWidget {
  const ParticipantesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      // AppBar removido conforme solicitado
      // floatingActionButton removido; botão de adicionar participante movido para dentro do corpo
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - kToolbarHeight,
            ),
            child: FutureBuilder<QuerySnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('createdAt', descending: false)
                      .get(),
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

                // Corrigido para evitar erro de largura infinita em PaginatedDataTable
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        int rowsPerPage = 10;
                        // Move ValueNotifier para fora do LayoutBuilder para não ser recriado a cada rebuild
                        final ValueNotifier<int> pageNotifier =
                            ValueNotifier<int>(0);
                        return Column(
                          children: [
                            // Botões centralizados e espaçados
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(
                                      context,
                                    ).pushNamed('/register-participant');
                                  },
                                  icon: const Icon(Icons.person_add, size: 18),
                                  label: const Text('Participante'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(130, 36),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    textStyle: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.download, size: 18),
                                  label: const Text('Participantes CSV'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(130, 36),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    textStyle: const TextStyle(fontSize: 14),
                                  ),
                                  onPressed: () async {
                                    final equipasSnapshot =
                                        await FirebaseFirestore.instance
                                            .collection('equipas')
                                            .get();
                                    if (!context.mounted) {
                                      return;
                                    }
                                    final Map<String, String> equipas = {
                                      for (var doc in equipasSnapshot.docs)
                                        doc.id: doc['nome'] ?? '',
                                    };
                                    final snapshot =
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .get();
                                    if (!context.mounted) {
                                      return;
                                    }
                                    final buffer = StringBuffer();
                                    buffer.writeln(
                                      'Nome,Email,Telefone,Emergência,T-Shirt,Equipa',
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
                                              equipas[d['equipaId']] ?? '',
                                            ]
                                            .map(
                                              (v) =>
                                                  '"${v.toString().replaceAll('"', '""')}"',
                                            )
                                            .join(','),
                                      );
                                    }
                                    final bytes = utf8.encode(
                                      buffer.toString(),
                                    );
                                    final blob = html.Blob([bytes]);
                                    final url = html
                                        .Url.createObjectUrlFromBlob(blob);
                                    html.AnchorElement(href: url)
                                      ..setAttribute(
                                        'download',
                                        'participantes.csv',
                                      )
                                      ..click();
                                    html.Url.revokeObjectUrl(url);
                                  },
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.groups, size: 18),
                                  label: const Text('Lista Completa'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(130, 36),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    textStyle: const TextStyle(fontSize: 14),
                                  ),
                                  onPressed: () async {
                                    final usersSnapshot =
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .get();
                                    if (!context.mounted) {
                                      return;
                                    }
                                    final veiculosSnapshot =
                                        await FirebaseFirestore.instance
                                            .collection('veiculos')
                                            .get();
                                    if (!context.mounted) {
                                      return;
                                    }
                                    final equipasSnapshot =
                                        await FirebaseFirestore.instance
                                            .collection('equipas')
                                            .get();
                                    if (!context.mounted) {
                                      return;
                                    }

                                    final veiculos = {
                                      for (var doc in veiculosSnapshot.docs)
                                        doc.id: doc.data(),
                                    };
                                    final equipas = {
                                      for (var doc in equipasSnapshot.docs)
                                        doc.id: doc.data()['nome'] ?? '',
                                    };

                                    final buffer = StringBuffer();
                                    buffer.writeln(
                                      'Condutor,Matricula,Modelo,Distico,Grupo,Telefone,T-Shirt,Acompanhantes,Equipa',
                                    );

                                    for (var doc in usersSnapshot.docs) {
                                      final data = doc.data();
                                      final nome = data['nome'] ?? '';
                                      final telefone = data['telefone'] ?? '';
                                      final tshirt = data['tshirt'] ?? '';
                                      final veiculoId = data['veiculoId'];
                                      final equipaId = data['equipaId'];
                                      final veiculo = veiculos[veiculoId];
                                      final matricula =
                                          veiculo?['matricula'] ?? '';
                                      final modelo = veiculo?['modelo'] ?? '';
                                      final distico = veiculo?['distico'] ?? '';
                                      final grupo = veiculo?['grupo'] ?? '';
                                      final acompanhantes =
                                          (veiculo?['passageiros'] ?? [])
                                              .map(
                                                (p) =>
                                                    '${p['nome'] ?? ''} (${p['tshirt'] ?? ''})',
                                              )
                                              .join(' | ');
                                      final equipaNome =
                                          equipas[equipaId] ?? '';

                                      buffer.writeln(
                                        [
                                              nome,
                                              matricula,
                                              modelo,
                                              distico,
                                              grupo,
                                              telefone,
                                              tshirt,
                                              acompanhantes,
                                              equipaNome,
                                            ]
                                            .map(
                                              (v) =>
                                                  '"${v.toString().replaceAll('"', '""')}"',
                                            )
                                            .join(','),
                                      );
                                    }

                                    final bytes = utf8.encode(
                                      buffer.toString(),
                                    );
                                    final blob = html.Blob([bytes]);
                                    final url = html
                                        .Url.createObjectUrlFromBlob(blob);
                                    html.AnchorElement(href: url)
                                      ..setAttribute(
                                        'download',
                                        'lista_completa.csv',
                                      )
                                      ..click();
                                    html.Url.revokeObjectUrl(url);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return ValueListenableBuilder<int>(
                                  valueListenable: pageNotifier,
                                  builder: (context, page, _) {
                                    List<QueryDocumentSnapshot> currentData =
                                        users
                                            .skip(page * rowsPerPage)
                                            .take(rowsPerPage)
                                            .toList();
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        SizedBox(
                                          width: constraints.maxWidth,
                                          child: Theme(
                                            data: Theme.of(context).copyWith(
                                              textTheme: Theme.of(
                                                context,
                                              ).textTheme.copyWith(
                                                bodyMedium: const TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                              dataTableTheme:
                                                  const DataTableThemeData(
                                                    dataTextStyle: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                            ),
                                            child: DataTable(
                                              columns: const [
                                                DataColumn(
                                                  label: Text(
                                                    'Condutor',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Email',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Telefone',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'T-Shirt',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Ações',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              rows:
                                                  currentData.asMap().entries.map((
                                                    entry,
                                                  ) {
                                                    final index = entry.key;
                                                    final doc = entry.value;
                                                    final data =
                                                        doc.data()
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >;
                                                    return DataRow(
                                                      color:
                                                          WidgetStateProperty.resolveWith<
                                                            Color?
                                                          >(
                                                            (
                                                              Set<WidgetState>
                                                              states,
                                                            ) =>
                                                                index.isEven
                                                                    ? Colors
                                                                        .grey
                                                                        .shade100
                                                                    : null,
                                                          ),
                                                      cells: [
                                                        DataCell(
                                                          Text(
                                                            data['nome'] ?? '',
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .black,
                                                                ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            data['email'] ?? '',
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .black,
                                                                ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            data['telefone'] ??
                                                                '',
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .black,
                                                                ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            data['tshirt'] ??
                                                                '',
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .black,
                                                                ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Row(
                                                            children: [
                                                              // IconButton(
                                                              //   icon: const Icon(
                                                              //     Icons.edit,
                                                              //     color:
                                                              //         Colors
                                                              //             .orange,
                                                              //   ),
                                                              //   tooltip:
                                                              //       'Editar Participante',
                                                              //   onPressed: () {
                                                              //     Navigator.of(
                                                              //       context,
                                                              //     ).pushNamed(
                                                              //       '/register-participant',
                                                              //       arguments: {
                                                              //         'userId':
                                                              //             doc.id,
                                                              //         'grupo':
                                                              //             (data['grupo'] ==
                                                              //                         'A' ||
                                                              //                     data['grupo'] ==
                                                              //                         'B')
                                                              //                 ? data['grupo']
                                                              //                 : null,
                                                              //       },
                                                              //     );
                                                              //   },
                                                              // ),
                                                              IconButton(
                                                                icon: const Icon(
                                                                  Icons.group,
                                                                  color:
                                                                      Colors
                                                                          .blueGrey,
                                                                ),
                                                                onPressed: () async {
                                                                  final veiculoId =
                                                                      data['veiculoId'];
                                                                  if (veiculoId ==
                                                                          null ||
                                                                      veiculoId
                                                                          .toString()
                                                                          .trim()
                                                                          .isEmpty) {
                                                                    showDialog(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (
                                                                            _,
                                                                          ) => const AlertDialog(
                                                                            title: Text(
                                                                              'Acompanhantes',
                                                                            ),
                                                                            content: Text(
                                                                              'ID do veículo não definido.',
                                                                              style: TextStyle(
                                                                                color:
                                                                                    Colors.black,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                    );
                                                                    return;
                                                                  }
                                                                  final veiculoDoc =
                                                                      await FirebaseFirestore
                                                                          .instance
                                                                          .collection(
                                                                            'veiculos',
                                                                          )
                                                                          .doc(
                                                                            veiculoId,
                                                                          )
                                                                          .get();
                                                                  if (!context
                                                                      .mounted) {
                                                                    return;
                                                                  }
                                                                  final veiculo =
                                                                      veiculoDoc
                                                                          .data();
                                                                  final acompanhantes =
                                                                      veiculo?['passageiros'] ??
                                                                      [];
                                                                  showDialog(
                                                                    context:
                                                                        context,
                                                                    builder: (
                                                                      _,
                                                                    ) {
                                                                      return AlertDialog(
                                                                        title: const Text(
                                                                          'Acompanhantes',
                                                                          style: TextStyle(
                                                                            color:
                                                                                Colors.black,
                                                                          ),
                                                                        ),
                                                                        content:
                                                                            acompanhantes.isEmpty
                                                                                ? const Text(
                                                                                  'Nenhum acompanhante encontrado.',
                                                                                  style: TextStyle(
                                                                                    color:
                                                                                        Colors.black,
                                                                                  ),
                                                                                )
                                                                                : Column(
                                                                                  mainAxisSize:
                                                                                      MainAxisSize.min,
                                                                                  crossAxisAlignment:
                                                                                      CrossAxisAlignment.start,
                                                                                  children:
                                                                                      (acompanhantes
                                                                                              as List)
                                                                                          .map<
                                                                                            Widget
                                                                                          >(
                                                                                            (
                                                                                              p,
                                                                                            ) {
                                                                                              return ListTile(
                                                                                                title: Text(
                                                                                                  'Nome: ${p['nome'] ?? ''}',
                                                                                                  style: const TextStyle(
                                                                                                    color:
                                                                                                        Colors.black,
                                                                                                  ),
                                                                                                ),
                                                                                                subtitle: Column(
                                                                                                  crossAxisAlignment:
                                                                                                      CrossAxisAlignment.start,
                                                                                                  children: [
                                                                                                    Text(
                                                                                                      'Telefone: ${p['telefone'] ?? ''}',
                                                                                                      style: const TextStyle(
                                                                                                        color:
                                                                                                            Colors.black,
                                                                                                      ),
                                                                                                    ),
                                                                                                    Text(
                                                                                                      'T-Shirt: ${p['tshirt'] ?? ''}',
                                                                                                      style: const TextStyle(
                                                                                                        color:
                                                                                                            Colors.black,
                                                                                                      ),
                                                                                                    ),
                                                                                                  ],
                                                                                                ),
                                                                                              );
                                                                                            },
                                                                                          )
                                                                                          .toList(),
                                                                                ),
                                                                        actions: [
                                                                          TextButton(
                                                                            onPressed:
                                                                                () => Navigator.pop(
                                                                                  context,
                                                                                ),
                                                                            child: const Text(
                                                                              'Fechar',
                                                                              style: TextStyle(
                                                                                color:
                                                                                    Colors.black,
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
                                                                  Icons
                                                                      .directions_car,
                                                                  color:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                                onPressed: () async {
                                                                  final veiculoId =
                                                                      data['veiculoId'];
                                                                  if (veiculoId ==
                                                                      null) {
                                                                    return;
                                                                  }
                                                                  final veiculoDoc =
                                                                      await FirebaseFirestore
                                                                          .instance
                                                                          .collection(
                                                                            'veiculos',
                                                                          )
                                                                          .doc(
                                                                            veiculoId,
                                                                          )
                                                                          .get();
                                                                  if (!context
                                                                      .mounted) {
                                                                    return;
                                                                  }
                                                                  final veiculo =
                                                                      veiculoDoc
                                                                          .data();
                                                                  showDialog(
                                                                    context:
                                                                        context,
                                                                    builder: (
                                                                      ctx,
                                                                    ) {
                                                                      final controller = TextEditingController(
                                                                        text:
                                                                            veiculo?['registro'] ??
                                                                            '',
                                                                      );
                                                                      return AlertDialog(
                                                                        title: const Text(
                                                                          'Veículo',
                                                                          style: TextStyle(
                                                                            color:
                                                                                Colors.black,
                                                                          ),
                                                                        ),
                                                                        content:
                                                                            veiculo ==
                                                                                    null
                                                                                ? const Text(
                                                                                  'Veículo não encontrado.',
                                                                                  style: TextStyle(
                                                                                    color:
                                                                                        Colors.black,
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
                                                                                        color:
                                                                                            Colors.black,
                                                                                      ),
                                                                                    ),
                                                                                    Text(
                                                                                      'Modelo: ${veiculo['modelo'] ?? ''}',
                                                                                      style: const TextStyle(
                                                                                        color:
                                                                                            Colors.black,
                                                                                      ),
                                                                                    ),
                                                                                    Text(
                                                                                      'Matrícula: ${veiculo['matricula'] ?? ''}',
                                                                                      style: const TextStyle(
                                                                                        color:
                                                                                            Colors.black,
                                                                                      ),
                                                                                    ),
                                                                                    const SizedBox(
                                                                                      height:
                                                                                          10,
                                                                                    ),
                                                                                    TextField(
                                                                                      controller:
                                                                                          controller,
                                                                                      decoration: const InputDecoration(
                                                                                        labelText:
                                                                                            'Distíco',
                                                                                        labelStyle: TextStyle(
                                                                                          color:
                                                                                              Colors.black,
                                                                                        ),
                                                                                        enabledBorder: UnderlineInputBorder(
                                                                                          borderSide: BorderSide(
                                                                                            color:
                                                                                                Colors.black,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      style: const TextStyle(
                                                                                        color:
                                                                                            Colors.black,
                                                                                      ),
                                                                                      onSubmitted: (
                                                                                        value,
                                                                                      ) async {
                                                                                        await FirebaseFirestore.instance
                                                                                            .collection(
                                                                                              'veiculos',
                                                                                            )
                                                                                            .doc(
                                                                                              veiculoId,
                                                                                            )
                                                                                            .update(
                                                                                              {
                                                                                                'distico':
                                                                                                    value,
                                                                                              },
                                                                                            );
                                                                                      },
                                                                                    ),
                                                                                    const SizedBox(
                                                                                      height:
                                                                                          10,
                                                                                    ),
                                                                                    DropdownButtonFormField<
                                                                                      String
                                                                                    >(
                                                                                      value:
                                                                                          veiculo['grupo'],
                                                                                      decoration: const InputDecoration(
                                                                                        labelText:
                                                                                            'Grupo',
                                                                                        labelStyle: TextStyle(
                                                                                          color:
                                                                                              Colors.black,
                                                                                        ),
                                                                                        enabledBorder: UnderlineInputBorder(
                                                                                          borderSide: BorderSide(
                                                                                            color:
                                                                                                Colors.black,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      items:
                                                                                          [
                                                                                            'A',
                                                                                            'B',
                                                                                          ].map(
                                                                                            (
                                                                                              String value,
                                                                                            ) {
                                                                                              return DropdownMenuItem<
                                                                                                String
                                                                                              >(
                                                                                                value:
                                                                                                    value,
                                                                                                child: Text(
                                                                                                  value,
                                                                                                  style: const TextStyle(
                                                                                                    color:
                                                                                                        Colors.black,
                                                                                                  ),
                                                                                                ),
                                                                                              );
                                                                                            },
                                                                                          ).toList(),
                                                                                      onChanged: (
                                                                                        String? newValue,
                                                                                      ) async {
                                                                                        if (newValue !=
                                                                                            null) {
                                                                                          await FirebaseFirestore.instance
                                                                                              .collection(
                                                                                                'veiculos',
                                                                                              )
                                                                                              .doc(
                                                                                                veiculoId,
                                                                                              )
                                                                                              .update(
                                                                                                {
                                                                                                  'grupo':
                                                                                                      newValue,
                                                                                                },
                                                                                              );
                                                                                        }
                                                                                      },
                                                                                      style: const TextStyle(
                                                                                        color:
                                                                                            Colors.black,
                                                                                      ),
                                                                                      dropdownColor:
                                                                                          Colors.white,
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                        actions: [
                                                                          TextButton(
                                                                            onPressed:
                                                                                () => Navigator.pop(
                                                                                  ctx,
                                                                                ),
                                                                            child: const Text(
                                                                              'Fechar',
                                                                              style: TextStyle(
                                                                                color:
                                                                                    Colors.black,
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
                                                                                color:
                                                                                    Colors.orange,
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
                                                                  Icons
                                                                      .info_outline,
                                                                  color:
                                                                      Colors
                                                                          .deepPurple,
                                                                ),
                                                                tooltip:
                                                                    'Ver detalhes',
                                                                onPressed: () {
                                                                  showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (
                                                                          _,
                                                                        ) => AlertDialog(
                                                                          title: const Text(
                                                                            'Detalhes do Participante',
                                                                            style: TextStyle(
                                                                              color:
                                                                                  Colors.black,
                                                                            ),
                                                                          ),
                                                                          content: SingleChildScrollView(
                                                                            child: Column(
                                                                              mainAxisSize:
                                                                                  MainAxisSize.min,
                                                                              crossAxisAlignment:
                                                                                  CrossAxisAlignment.start,
                                                                              children: [
                                                                                Text(
                                                                                  'Nome: ${data['nome'] ?? ''}',
                                                                                  style: const TextStyle(
                                                                                    color:
                                                                                        Colors.black,
                                                                                  ),
                                                                                ),
                                                                                Text(
                                                                                  'Email: ${data['email'] ?? ''}',
                                                                                  style: const TextStyle(
                                                                                    color:
                                                                                        Colors.black,
                                                                                  ),
                                                                                ),
                                                                                Text(
                                                                                  'Telefone: ${data['telefone'] ?? ''}',
                                                                                  style: const TextStyle(
                                                                                    color:
                                                                                        Colors.black,
                                                                                  ),
                                                                                ),
                                                                                Text(
                                                                                  'Emergência: ${data['emergencia'] ?? ''}',
                                                                                  style: const TextStyle(
                                                                                    color:
                                                                                        Colors.black,
                                                                                  ),
                                                                                ),
                                                                                Text(
                                                                                  'T-Shirt: ${data['tshirt'] ?? ''}',
                                                                                  style: const TextStyle(
                                                                                    color:
                                                                                        Colors.black,
                                                                                  ),
                                                                                ),
                                                                                Text(
                                                                                  'Equipa: ${data['equipaId'] ?? 'N/A'}',
                                                                                  style: const TextStyle(
                                                                                    color:
                                                                                        Colors.black,
                                                                                  ),
                                                                                ),
                                                                                Text(
                                                                                  'Evento: ${data['eventoNome'] ?? ''}',
                                                                                  style: const TextStyle(
                                                                                    color:
                                                                                        Colors.black,
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(
                                                                                  height:
                                                                                      12,
                                                                                ),
                                                                                const Text(
                                                                                  '--- Equipa ---',
                                                                                  style: TextStyle(
                                                                                    color:
                                                                                        Colors.black,
                                                                                    fontWeight:
                                                                                        FontWeight.bold,
                                                                                  ),
                                                                                ),
                                                                                if (data['equipaId'] ==
                                                                                        null ||
                                                                                    data['equipaId'].toString().isEmpty)
                                                                                  const Text(
                                                                                    'Equipa não definida',
                                                                                    style: TextStyle(
                                                                                      color:
                                                                                          Colors.black,
                                                                                    ),
                                                                                  )
                                                                                else
                                                                                  FutureBuilder<
                                                                                    DocumentSnapshot
                                                                                  >(
                                                                                    future:
                                                                                        FirebaseFirestore.instance
                                                                                            .collection(
                                                                                              'equipas',
                                                                                            )
                                                                                            .doc(
                                                                                              data['equipaId'],
                                                                                            )
                                                                                            .get(),
                                                                                    builder: (
                                                                                      context,
                                                                                      snapshot,
                                                                                    ) {
                                                                                      if (!snapshot.hasData ||
                                                                                          !snapshot.data!.exists) {
                                                                                        return const Text(
                                                                                          'Equipa não encontrada',
                                                                                          style: TextStyle(
                                                                                            color:
                                                                                                Colors.black,
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
                                                                                            CrossAxisAlignment.start,
                                                                                        children: [
                                                                                          Text(
                                                                                            'Nome da Equipa: ${equipa['nome'] ?? ''}',
                                                                                            style: const TextStyle(
                                                                                              color:
                                                                                                  Colors.black,
                                                                                            ),
                                                                                          ),
                                                                                          Text(
                                                                                            'Hino: ${equipa['hino'] ?? ''}',
                                                                                            style: const TextStyle(
                                                                                              color:
                                                                                                  Colors.black,
                                                                                            ),
                                                                                          ),
                                                                                          Text(
                                                                                            'Pontuação Total: ${equipa['pontuacaoTotal'] ?? 0}',
                                                                                            style: const TextStyle(
                                                                                              color:
                                                                                                  Colors.black,
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      );
                                                                                    },
                                                                                  ),
                                                                                const SizedBox(
                                                                                  height:
                                                                                      12,
                                                                                ),
                                                                                const Text(
                                                                                  '--- Veículo ---',
                                                                                  style: TextStyle(
                                                                                    color:
                                                                                        Colors.black,
                                                                                    fontWeight:
                                                                                        FontWeight.bold,
                                                                                  ),
                                                                                ),
                                                                                if (data['veiculoId'] ==
                                                                                        null ||
                                                                                    data['veiculoId'].toString().isEmpty)
                                                                                  const Text(
                                                                                    'Veículo não definido',
                                                                                    style: TextStyle(
                                                                                      color:
                                                                                          Colors.black,
                                                                                    ),
                                                                                  )
                                                                                else
                                                                                  FutureBuilder<
                                                                                    DocumentSnapshot
                                                                                  >(
                                                                                    future:
                                                                                        FirebaseFirestore.instance
                                                                                            .collection(
                                                                                              'veiculos',
                                                                                            )
                                                                                            .doc(
                                                                                              data['veiculoId'],
                                                                                            )
                                                                                            .get(),
                                                                                    builder: (
                                                                                      context,
                                                                                      snapshot,
                                                                                    ) {
                                                                                      if (!snapshot.hasData ||
                                                                                          !snapshot.data!.exists) {
                                                                                        return const Text(
                                                                                          'Veículo não encontrado',
                                                                                          style: TextStyle(
                                                                                            color:
                                                                                                Colors.black,
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
                                                                                            CrossAxisAlignment.start,
                                                                                        children: [
                                                                                          Text(
                                                                                            'Marca: ${v['marca'] ?? ''}',
                                                                                            style: const TextStyle(
                                                                                              color:
                                                                                                  Colors.black,
                                                                                            ),
                                                                                          ),
                                                                                          Text(
                                                                                            'Modelo: ${v['modelo'] ?? ''}',
                                                                                            style: const TextStyle(
                                                                                              color:
                                                                                                  Colors.black,
                                                                                            ),
                                                                                          ),
                                                                                          Text(
                                                                                            'Matrícula: ${v['matricula'] ?? ''}',
                                                                                            style: const TextStyle(
                                                                                              color:
                                                                                                  Colors.black,
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      );
                                                                                    },
                                                                                  ),
                                                                                const SizedBox(
                                                                                  height:
                                                                                      12,
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          actions: [
                                                                            TextButton(
                                                                              onPressed:
                                                                                  () => Navigator.pop(
                                                                                    context,
                                                                                  ),
                                                                              child: const Text(
                                                                                'Fechar',
                                                                                style: TextStyle(
                                                                                  color:
                                                                                      Colors.black,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                  );
                                                                },
                                                              ),
                                                              IconButton(
                                                                icon: const Icon(
                                                                  Icons.delete,
                                                                  color:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                                tooltip:
                                                                    'Eliminar participante',
                                                                onPressed: () async {
                                                                  final confirm = await showDialog<
                                                                    bool
                                                                  >(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (
                                                                          ctx,
                                                                        ) => AlertDialog(
                                                                          title: const Text(
                                                                            'Eliminar Participante',
                                                                            style: TextStyle(
                                                                              color:
                                                                                  Colors.black,
                                                                            ),
                                                                          ),
                                                                          content: const Text(
                                                                            'Tem certeza que deseja eliminar este participante, o veículo associado e a equipa?',
                                                                            style: TextStyle(
                                                                              color:
                                                                                  Colors.black,
                                                                            ),
                                                                          ),
                                                                          actions: [
                                                                            TextButton(
                                                                              onPressed:
                                                                                  () => Navigator.of(
                                                                                    ctx,
                                                                                  ).pop(
                                                                                    false,
                                                                                  ),
                                                                              child: const Text(
                                                                                'Cancelar',
                                                                                style: TextStyle(
                                                                                  color:
                                                                                      Colors.black,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            TextButton(
                                                                              onPressed:
                                                                                  () => Navigator.of(
                                                                                    ctx,
                                                                                  ).pop(
                                                                                    true,
                                                                                  ),
                                                                              child: const Text(
                                                                                'Eliminar',
                                                                                style: TextStyle(
                                                                                  color:
                                                                                      Colors.black,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                  );
                                                                  if (confirm ==
                                                                      true) {
                                                                    final userId =
                                                                        doc.id;
                                                                    final veiculoId =
                                                                        data['veiculoId'];
                                                                    final equipaId =
                                                                        data['equipaId'];
                                                                    await FirebaseFirestore
                                                                        .instance
                                                                        .collection(
                                                                          'users',
                                                                        )
                                                                        .doc(
                                                                          userId,
                                                                        )
                                                                        .delete();
                                                                    if (!context
                                                                        .mounted) {
                                                                      return;
                                                                    }
                                                                    if (veiculoId !=
                                                                        null) {
                                                                      await FirebaseFirestore
                                                                          .instance
                                                                          .collection(
                                                                            'veiculos',
                                                                          )
                                                                          .doc(
                                                                            veiculoId,
                                                                          )
                                                                          .delete();
                                                                      if (!context
                                                                          .mounted) {
                                                                        return;
                                                                      }
                                                                    }
                                                                    if (equipaId !=
                                                                        null) {
                                                                      final equipaUsada =
                                                                          await FirebaseFirestore
                                                                              .instance
                                                                              .collection(
                                                                                'users',
                                                                              )
                                                                              .where(
                                                                                'equipaId',
                                                                                isEqualTo:
                                                                                    equipaId,
                                                                              )
                                                                              .get();
                                                                      if (!context
                                                                          .mounted) {
                                                                        return;
                                                                      }
                                                                      if (equipaUsada
                                                                              .docs
                                                                              .length <=
                                                                          1) {
                                                                        await FirebaseFirestore
                                                                            .instance
                                                                            .collection(
                                                                              'equipas',
                                                                            )
                                                                            .doc(
                                                                              equipaId,
                                                                            )
                                                                            .delete();
                                                                        if (!context
                                                                            .mounted) {
                                                                          return;
                                                                        }
                                                                      }
                                                                    }
                                                                    if (Navigator.of(
                                                                      context,
                                                                    ).mounted) {
                                                                      ScaffoldMessenger.of(
                                                                        context,
                                                                      ).showSnackBar(
                                                                        const SnackBar(
                                                                          content: Text(
                                                                            'Participante eliminado com sucesso',
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
                                                                  }
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }).toList(),
                                            ),
                                          ),
                                        ),
                                        // PAGINAÇÃO CENTRALIZADA ABAIXO DA TABELA
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            TextButton(
                                              onPressed:
                                                  page > 0
                                                      ? () =>
                                                          pageNotifier.value =
                                                              page - 1
                                                      : null,
                                              child: const Text('Anterior'),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              'Página ${page + 1} de ${(users.length / rowsPerPage).ceil()}',
                                              style: const TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            TextButton(
                                              onPressed:
                                                  (page + 1) * rowsPerPage <
                                                          users.length
                                                      ? () =>
                                                          pageNotifier.value =
                                                              page + 1
                                                      : null,
                                              child: const Text('Próximo'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
