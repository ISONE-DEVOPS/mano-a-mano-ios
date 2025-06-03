import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';

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

  bool _sortAsc = true;
  int _sortColumnIndex = 0;

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
        'ano': ano,
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
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Gestão de Edição',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _anoController,
              decoration: const InputDecoration(labelText: 'Ano'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome da Edição'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descricaoController,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _entidadeController,
              decoration: const InputDecoration(
                labelText: 'Entidade beneficiária',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _salvarEdicao,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryDark,
                foregroundColor: Colors.black,
              ),
              child: const Text('Salvar Edição'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Edições criadas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
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

                  docs.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aAno = int.tryParse(aData['ano'].toString()) ?? 0;
                    final bAno = int.tryParse(bData['ano'].toString()) ?? 0;
                    return _sortAsc ? aAno.compareTo(bAno) : bAno.compareTo(aAno);
                  });

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAsc,
                      headingRowColor: WidgetStateProperty.all(AppColors.secondaryDark.withAlpha(51)),
                      columns: [
                        DataColumn(
                          label: const Text('ANO', style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true,
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortColumnIndex = columnIndex;
                              _sortAsc = ascending;
                            });
                          },
                        ),
                        const DataColumn(label: Text('NOME')),
                        const DataColumn(label: Text('ENTIDADE')),
                        const DataColumn(label: Text('AÇÕES')),
                      ],
                      rows:
                          docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DataRow(
                              cells: [
                                DataCell(Text(data['ano'] ?? '')),
                                DataCell(Text(data['nome'] ?? '')),
                                DataCell(Text(data['entidade'] ?? '')),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.visibility,
                                          color: AppColors.secondaryDark,
                                        ),
                                        tooltip: 'Ver detalhes',
                                        onPressed: () {},
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: AppColors.primary,
                                        ),
                                        tooltip: 'Editar',
                                        onPressed: () {},
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Apagar',
                                        onPressed: () async {
                                          await doc.reference.delete();
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
            ),
          ],
        ),
      ),
    );
  }
}
