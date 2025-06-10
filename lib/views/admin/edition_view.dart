import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';
import 'package:mano_mano_dashboard/views/admin/events_view.dart';

class EditionView extends StatefulWidget {
  const EditionView({super.key});

  @override
  State<EditionView> createState() => _EditionViewState();
}

class _EditionViewState extends State<EditionView> {
  final _nomeController = TextEditingController();
  final _anoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _entidadeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _anoController.text = DateTime.now().year.toString();
  }

  void _salvarEdicao() async {
    final nome = _nomeController.text.trim();
    final ano = _anoController.text.trim();
    final descricao = _descricaoController.text.trim();
    final entidade = _entidadeController.text.trim();

    if (nome.isEmpty || ano.isEmpty || descricao.isEmpty || entidade.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('editions').add({
        'nome': nome,
        'ano': int.tryParse(ano) ?? DateTime.now().year,
        'descricao': descricao,
        'entidade': entidade,
        'percurso': {
          'inicio': const GeoPoint(14.9169, -23.6153),
          'fim': const GeoPoint(14.9201, -23.6200),
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Edição salva com sucesso')));

      _nomeController.clear();
      _anoController.clear();
      _descricaoController.clear();
      _entidadeController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              children: [
                TextField(
                  controller: _anoController,
                  decoration: InputDecoration(
                    labelText: 'Ano',
                    hintText: 'Ex: 2025',
                    labelStyle: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.black87),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black26),
                    ),
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome da Edição',
                    hintText: 'Ex: Shell ao KM 2025',
                    labelStyle: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.black87),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black26),
                    ),
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descricaoController,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Ex: Corrida solidária com checkpoints',
                    labelStyle: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.black87),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black26),
                    ),
                  ),
                  maxLines: 2,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _entidadeController,
                  decoration: InputDecoration(
                    labelText: 'Entidade beneficiária',
                    hintText: 'Ex: Associação Cabo Verde Solidário',
                    labelStyle: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.black87),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black26),
                    ),
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _salvarEdicao,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Salvar Edição',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Edições criadas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('editions')
                          .orderBy('ano', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;

                    return SizedBox(
                      height: 400,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            AppColors.secondaryDark.withAlpha(51),
                          ),
                          columns: [
                            DataColumn(
                              label: Text(
                                'ANO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'NOME',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'ENTIDADE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'DESCRIÇÃO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'CRIADO EM',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'AÇÕES',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                          rows:
                              docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final timestamp = data['createdAt'];
                                final createdAt =
                                    (timestamp != null &&
                                            timestamp is Timestamp)
                                        ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}'
                                        : 'N/A';
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        '${data['ano'] ?? ''}',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        data['nome'] ?? '',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        data['entidade'] ?? '',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        data['descricao'] ?? '',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        createdAt,
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () {
                                              final nomeController =
                                                  TextEditingController(
                                                    text: data['nome'],
                                                  );
                                              final anoController =
                                                  TextEditingController(
                                                    text:
                                                        data['ano'].toString(),
                                                  );
                                              final descricaoController =
                                                  TextEditingController(
                                                    text: data['descricao'],
                                                  );
                                              final entidadeController =
                                                  TextEditingController(
                                                    text: data['entidade'],
                                                  );

                                              showDialog(
                                                context: context,
                                                builder: (_) {
                                                  return AlertDialog(
                                                    title: const Text(
                                                      'Editar Edição',
                                                    ),
                                                    content: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        TextField(
                                                          controller:
                                                              anoController,
                                                          decoration:
                                                              const InputDecoration(
                                                                labelText:
                                                                    'Ano',
                                                              ),
                                                        ),
                                                        TextField(
                                                          controller:
                                                              nomeController,
                                                          decoration:
                                                              const InputDecoration(
                                                                labelText:
                                                                    'Nome',
                                                              ),
                                                        ),
                                                        TextField(
                                                          controller:
                                                              descricaoController,
                                                          decoration:
                                                              const InputDecoration(
                                                                labelText:
                                                                    'Descrição',
                                                              ),
                                                        ),
                                                        TextField(
                                                          controller:
                                                              entidadeController,
                                                          decoration:
                                                              const InputDecoration(
                                                                labelText:
                                                                    'Entidade',
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                            ),
                                                        child: const Text(
                                                          'Cancelar',
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () async {
                                                          await doc.reference.update({
                                                            'ano':
                                                                int.tryParse(
                                                                  anoController
                                                                      .text,
                                                                ) ??
                                                                DateTime.now()
                                                                    .year,
                                                            'nome':
                                                                nomeController
                                                                    .text
                                                                    .trim(),
                                                            'descricao':
                                                                descricaoController
                                                                    .text
                                                                    .trim(),
                                                            'entidade':
                                                                entidadeController
                                                                    .text
                                                                    .trim(),
                                                          });
                                                          if (context.mounted) {
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                          }
                                                        },
                                                        child: const Text(
                                                          'Salvar',
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
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () async {
                                              await doc.reference.delete();
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Edição removida',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.event,
                                              color: Colors.orange,
                                            ),
                                            tooltip: 'Gerenciar Eventos',
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => EventsView(edicaoId: doc.id),
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
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
