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
  final _descricaoController = TextEditingController();
  final _dataInicioController = TextEditingController();
  final _dataFimController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _dataInicioController.dispose();
    _dataFimController.dispose();
    super.dispose();
  }

  void _salvarEdicao() async {
    final nome = _nomeController.text.trim();
    final descricao = _descricaoController.text.trim();
    final dataInicio = DateTime.tryParse(_dataInicioController.text.trim());
    final dataFim = DateTime.tryParse(_dataFimController.text.trim());
    if (nome.isEmpty ||
        descricao.isEmpty ||
        dataInicio == null ||
        dataFim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos corretamente')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('editions')
          .doc(nome.toLowerCase().replaceAll(' ', '_'))
          .set({
            'nome': nome,
            'descricao': descricao,
            'dataInicio': dataInicio,
            'dataFim': dataFim,
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Edição salva com sucesso')));

      _nomeController.clear();
      _descricaoController.clear();
      _dataInicioController.clear();
      _dataFimController.clear();
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
                  controller: _dataInicioController,
                  decoration: InputDecoration(
                    labelText: 'Data de Início (YYYY-MM-DD)',
                    hintText: 'Ex: 2025-06-28',
                    labelStyle: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.black87),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black26),
                    ),
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dataFimController,
                  decoration: InputDecoration(
                    labelText: 'Data de Fim (YYYY-MM-DD)',
                    hintText: 'Ex: 2025-06-28',
                    labelStyle: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.black87),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: const OutlineInputBorder(
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
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: const OutlineInputBorder(
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
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black26),
                    ),
                  ),
                  maxLines: 2,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 12),
                // Campo de entidade beneficiária removido (agora faz parte apenas de events)
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
                          .orderBy('nome')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    return SizedBox(
                      height: 400,
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(3),
                          2: IntrinsicColumnWidth(),
                          3: IntrinsicColumnWidth(),
                          4: IntrinsicColumnWidth(),
                        },
                        border: TableBorder.all(color: Colors.black12),
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: AppColors.secondaryDark.withAlpha(51),
                            ),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Nome',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Descrição',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Início',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Fim',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Ações',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ...docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final inicio =
                                (data['dataInicio'] as Timestamp?)?.toDate();
                            final fim =
                                (data['dataFim'] as Timestamp?)?.toDate();
                            String format(DateTime? dt) =>
                                dt == null
                                    ? '-'
                                    : '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    data['nome'] ?? '-',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    data['descricao'] ?? '-',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    format(inicio),
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    format(fim),
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.event,
                                      color: Colors.orange,
                                    ),
                                    tooltip: 'Gerenciar Eventos',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (_) => Dialog(
                                              backgroundColor: Colors.white,
                                              insetPadding:
                                                  const EdgeInsets.all(16),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    color: AppColors.primary,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 10,
                                                        ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          'Eventos: ${data['nome'] ?? doc.id}',
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.close,
                                                            color: Colors.white,
                                                          ),
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                  ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: SizedBox(
                                                      width:
                                                          MediaQuery.of(
                                                            context,
                                                          ).size.width *
                                                          0.9,
                                                      child: EventsView(
                                                        edicaoId: doc.id,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
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
