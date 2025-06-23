import 'package:flutter/material.dart';
import 'edit_participantes.dart';
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
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum participante encontrado.',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                final users = snapshot.data!.docs;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        int rowsPerPage = 10;
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
                                    foregroundColor: Colors.black,
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
                                    foregroundColor: Colors.black,
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
                                    foregroundColor: Colors.black,
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
                                                              IconButton(
                                                                icon: const Icon(
                                                                  Icons.edit,
                                                                  color:
                                                                      Colors
                                                                          .orange,
                                                                ),
                                                                tooltip:
                                                                    'Editar Participante',
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                    context,
                                                                  ).push(
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (
                                                                            _,
                                                                          ) => EditParticipantesView(
                                                                            userId:
                                                                                doc.id,
                                                                          ),
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                              IconButton(
                                                                icon: const Icon(
                                                                  Icons.group,
                                                                  color:
                                                                      Colors
                                                                          .blueGrey,
                                                                ),
                                                                tooltip:
                                                                    'Editar Acompanhantes',
                                                                onPressed:
                                                                    () => _editarAcompanhantes(
                                                                      context,
                                                                      data,
                                                                    ),
                                                              ),
                                                              IconButton(
                                                                icon: const Icon(
                                                                  Icons
                                                                      .directions_car,
                                                                  color:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                                tooltip:
                                                                    'Editar Veículo',
                                                                onPressed:
                                                                    () => _editarVeiculo(
                                                                      context,
                                                                      data,
                                                                    ),
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
                                                                onPressed:
                                                                    () => _verDetalhes(
                                                                      context,
                                                                      data,
                                                                    ),
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
                                                                onPressed:
                                                                    () => _eliminarParticipante(
                                                                      context,
                                                                      doc,
                                                                      data,
                                                                    ),
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
                                              child: const Text(
                                                'Anterior',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              'Página ${page + 1} de ${(users.length / rowsPerPage).ceil()}',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500,
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
                                              child: const Text(
                                                'Próximo',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
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

  // MÉTODO PARA EDITAR ACOMPANHANTES - MELHORADO
  void _editarAcompanhantes(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final veiculoId = data['veiculoId'];
    if (veiculoId == null || veiculoId.toString().trim().isEmpty) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Acompanhantes',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: const Text(
                'ID do veículo não definido.',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
      );
      return;
    }

    final veiculoDoc =
        await FirebaseFirestore.instance
            .collection('veiculos')
            .doc(veiculoId)
            .get();
    if (!context.mounted) return;

    final veiculo = veiculoDoc.data();
    final acompanhantes = veiculo?['passageiros'] ?? [];

    showDialog(
      context: context,
      builder: (_) {
        // Controllers para cada acompanhante
        final List<TextEditingController> nomeControllers = List.generate(
          acompanhantes.length,
          (i) => TextEditingController(text: acompanhantes[i]['nome'] ?? ''),
        );
        final List<TextEditingController> telefoneControllers = List.generate(
          acompanhantes.length,
          (i) =>
              TextEditingController(text: acompanhantes[i]['telefone'] ?? ''),
        );
        final List<TextEditingController> tshirtControllers = List.generate(
          acompanhantes.length,
          (i) => TextEditingController(text: acompanhantes[i]['tshirt'] ?? ''),
        );

        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Editar Acompanhantes',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: SizedBox(
            width: 500,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    acompanhantes.isEmpty
                        ? [
                          const Text(
                            'Nenhum acompanhante cadastrado.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                        ]
                        : List.generate(acompanhantes.length, (index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Acompanhante ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: nomeControllers[index],
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'Nome',
                                    labelStyle: const TextStyle(color: Colors.black),
                                    hintStyle: const TextStyle(color: Colors.black),
                                    floatingLabelStyle: const TextStyle(color: Colors.black),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Colors.black),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: telefoneControllers[index],
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'Telefone',
                                    labelStyle: const TextStyle(color: Colors.black),
                                    hintStyle: const TextStyle(color: Colors.black),
                                    floatingLabelStyle: const TextStyle(color: Colors.black),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Colors.black),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value:
                                      (tshirtControllers[index]
                                                  .text
                                                  .isNotEmpty &&
                                              [
                                                'XS',
                                                'S',
                                                'M',
                                                'L',
                                                'XL',
                                                'XXL',
                                              ].contains(
                                                tshirtControllers[index].text,
                                              ))
                                          ? tshirtControllers[index].text
                                          : null,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'Tamanho T-Shirt',
                                    labelStyle: const TextStyle(color: Colors.black),
                                    hintStyle: const TextStyle(color: Colors.black),
                                    floatingLabelStyle: const TextStyle(color: Colors.black),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Colors.black),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Colors.grey),
                                    ),
                                  ),
                                  dropdownColor: Colors.white,
                                  items:
                                      ['XS', 'S', 'M', 'L', 'XL', 'XXL'].map((
                                        String value,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(
                                            value,
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      tshirtControllers[index].text = newValue;
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final updated = List.generate(acompanhantes.length, (index) {
                  return {
                    'nome': nomeControllers[index].text,
                    'telefone': telefoneControllers[index].text,
                    'tshirt': tshirtControllers[index].text,
                  };
                });
                await FirebaseFirestore.instance
                    .collection('veiculos')
                    .doc(veiculoId)
                    .update({'passageiros': updated});
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Acompanhantes atualizados com sucesso'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  // MÉTODO PARA EDITAR VEÍCULO - MELHORADO
  void _editarVeiculo(BuildContext context, Map<String, dynamic> data) async {
    final veiculoId = data['veiculoId'];
    if (veiculoId == null) return;

    final veiculoDoc =
        await FirebaseFirestore.instance
            .collection('veiculos')
            .doc(veiculoId)
            .get();
    if (!context.mounted) return;

    final veiculo = veiculoDoc.data();

    // Carrega equipa correspondente
    final equipaId = data['equipaId'];
    DocumentSnapshot? equipaDoc;
    Map<String, dynamic>? equipa;
    if (equipaId != null && equipaId.toString().isNotEmpty) {
      equipaDoc =
          await FirebaseFirestore.instance
              .collection('equipas')
              .doc(equipaId)
              .get();
      if (!context.mounted) return;
      if (equipaDoc.exists) {
        equipa = equipaDoc.data() as Map<String, dynamic>?;
      }
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        final modeloController = TextEditingController(
          text: veiculo?['modelo'] ?? '',
        );
        final disticoController = TextEditingController(
          text: veiculo?['distico'] ?? '',
        );
        String? selectedGrupo =
            (equipa != null &&
                    equipa['grupo'] != null &&
                    ['A', 'B'].contains(equipa['grupo']))
                ? equipa['grupo'] as String
                : null;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Editar Veículo',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content:
                  veiculo == null
                      ? const Text(
                        'Veículo não encontrado.',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      )
                      : SizedBox(
                        width: 400,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Informações do Veículo',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Marca: ${veiculo['marca'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Matrícula: ${veiculo['matricula'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: modeloController,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  labelText: 'Modelo',
                                  labelStyle: const TextStyle(color: Colors.black),
                                  hintStyle: const TextStyle(color: Colors.black),
                                  floatingLabelStyle: const TextStyle(color: Colors.black),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.black),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: disticoController,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  labelText: 'Distíco',
                                  labelStyle: const TextStyle(color: Colors.black),
                                  hintStyle: const TextStyle(color: Colors.black),
                                  floatingLabelStyle: const TextStyle(color: Colors.black),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.black),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: selectedGrupo,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  labelText: 'Grupo',
                                  labelStyle: const TextStyle(color: Colors.black),
                                  hintStyle: const TextStyle(color: Colors.black),
                                  floatingLabelStyle: const TextStyle(color: Colors.black),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.black),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.grey),
                                  ),
                                ),
                                dropdownColor: Colors.white,
                                items:
                                    ['A', 'B'].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          'Grupo $value',
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedGrupo = newValue;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('veiculos')
                        .doc(veiculoId)
                        .update({
                          'modelo': modeloController.text,
                          'distico': disticoController.text,
                          'grupo': selectedGrupo,
                        });
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veículo atualizado com sucesso'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // MÉTODO PARA VER DETALHES - MELHORADO
  void _verDetalhes(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Detalhes do Participante',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: SizedBox(
              width: 500,
              height: 600,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações Pessoais
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informações Pessoais',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow('Nome:', data['nome'] ?? 'N/A'),
                          _buildDetailRow('Email:', data['email'] ?? 'N/A'),
                          _buildDetailRow(
                            'Telefone:',
                            data['telefone'] ?? 'N/A',
                          ),
                          _buildDetailRow(
                            'Emergência:',
                            data['emergencia'] ?? 'N/A',
                          ),
                          _buildDetailRow('T-Shirt:', data['tshirt'] ?? 'N/A'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Informações da Equipa
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informações da Equipa',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (data['equipaId'] == null ||
                              data['equipaId'].toString().isEmpty)
                            const Text(
                              'Equipa não definida',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            )
                          else
                            FutureBuilder<DocumentSnapshot>(
                              future:
                                  FirebaseFirestore.instance
                                      .collection('equipas')
                                      .doc(data['equipaId'])
                                      .get(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData ||
                                    !snapshot.data!.exists) {
                                  return const Text(
                                    'Equipa não encontrada',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  );
                                }
                                final equipa =
                                    snapshot.data!.data()
                                        as Map<String, dynamic>;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRow(
                                      'Nome da Equipa:',
                                      equipa['nome'] ?? 'N/A',
                                    ),
                                    _buildDetailRow(
                                      'Hino:',
                                      equipa['hino'] ?? 'N/A',
                                    ),
                                    _buildDetailRow(
                                      'Pontuação Total:',
                                      '${equipa['pontuacaoTotal'] ?? 0}',
                                    ),
                                    _buildDetailRow(
                                      'Grupo:',
                                      equipa['grupo'] ?? 'N/A',
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Informações do Veículo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informações do Veículo',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (data['veiculoId'] == null ||
                              data['veiculoId'].toString().isEmpty)
                            const Text(
                              'Veículo não definido',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            )
                          else
                            FutureBuilder<DocumentSnapshot>(
                              future:
                                  FirebaseFirestore.instance
                                      .collection('veiculos')
                                      .doc(data['veiculoId'])
                                      .get(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData ||
                                    !snapshot.data!.exists) {
                                  return const Text(
                                    'Veículo não encontrado',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  );
                                }
                                final v =
                                    snapshot.data!.data()
                                        as Map<String, dynamic>;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRow(
                                      'Marca:',
                                      v['marca'] ?? 'N/A',
                                    ),
                                    _buildDetailRow(
                                      'Modelo:',
                                      v['modelo'] ?? 'N/A',
                                    ),
                                    _buildDetailRow(
                                      'Matrícula:',
                                      v['matricula'] ?? 'N/A',
                                    ),
                                    _buildDetailRow(
                                      'Distíco:',
                                      v['distico'] ?? 'N/A',
                                    ),
                                    _buildDetailRow(
                                      'Grupo:',
                                      v['grupo'] ?? 'N/A',
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade600,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            TextSpan(
              text: ' $value',
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // MÉTODO PARA ELIMINAR PARTICIPANTE - MELHORADO
  void _eliminarParticipante(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Eliminar Participante',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tem certeza que deseja eliminar este participante?',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Esta ação irá eliminar:',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• O participante',
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                      const Text(
                        '• O veículo associado',
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                      const Text(
                        '• A equipa (se não tiver outros membros)',
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esta ação não pode ser desfeita.',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final userId = doc.id;
      final veiculoId = data['veiculoId'];
      final equipaId = data['equipaId'];

      try {
        // Eliminar participante
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .delete();
        if (!context.mounted) return;

        // Eliminar veículo se existir
        if (veiculoId != null) {
          await FirebaseFirestore.instance
              .collection('veiculos')
              .doc(veiculoId)
              .delete();
          if (!context.mounted) return;
        }

        // Verificar se a equipa tem outros membros antes de eliminar
        if (equipaId != null) {
          final equipaUsada =
              await FirebaseFirestore.instance
                  .collection('users')
                  .where('equipaId', isEqualTo: equipaId)
                  .get();
          if (!context.mounted) return;

          if (equipaUsada.docs.length <= 1) {
            await FirebaseFirestore.instance
                .collection('equipas')
                .doc(equipaId)
                .delete();
            if (!context.mounted) return;
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Participante eliminado com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao eliminar participante: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
