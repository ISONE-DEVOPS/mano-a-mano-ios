import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';

class JogosCreateView extends StatefulWidget {
  const JogosCreateView({super.key});

  @override
  State<JogosCreateView> createState() => _JogosCreateViewState();
}

class _JogosCreateViewState extends State<JogosCreateView> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _pontuacaoController = TextEditingController();
  final _regrasController = TextEditingController();
  final _tempoController = TextEditingController();
  final _localPadraoController = TextEditingController();
  final _materialController = TextEditingController();
  final _ordemController = TextEditingController();

  String _tipoSelecionado = 'pontaria';
  String _grupoSelecionado = 'ambos';
  String _dificuldadeSelecionada = 'média';
  bool _avaliacaoAutomatica = true;
  bool _visivelParaAdmin = true;

  final List<String> _tipos = [
    'pontaria',
    'conhecimento',
    'equilibrio',
    'resistencia',
    'criatividade',
  ];
  final List<String> _grupos = ['A', 'B', 'ambos'];
  final List<String> _dificuldades = ['fácil', 'média', 'difícil'];

  void _salvarJogo() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('jogos').add({
        'nome': _nomeController.text,
        'descricao': _descricaoController.text,
        'pontuacaoMax': int.tryParse(_pontuacaoController.text) ?? 0,
        'regras': _regrasController.text,
        'tipo': _tipoSelecionado,
        'grupo': _grupoSelecionado,
        'tempoEstimado': int.tryParse(_tempoController.text) ?? 0,
        'materialNecessario':
            _materialController.text.split(',').map((e) => e.trim()).toList(),
        'avaliacaoAutomatica': _avaliacaoAutomatica,
        'visivelParaAdmin': _visivelParaAdmin,
        'ordemRecomendada': int.tryParse(_ordemController.text) ?? 0,
        'nivelDificuldade': _dificuldadeSelecionada,
        'localPadrao': _localPadraoController.text,
      });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Jogo salvo com sucesso')));
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
      _formKey.currentState!.reset();
      setState(() {
        _tipoSelecionado = 'pontaria';
        _grupoSelecionado = 'ambos';
        _dificuldadeSelecionada = 'média';
        _avaliacaoAutomatica = true;
        _visivelParaAdmin = true;
      });
    }
  }

  void _deletarJogo(String id) async {
    await FirebaseFirestore.instance.collection('jogos').doc(id).delete();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Jogo deletado com sucesso')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text('Registrar Novo Jogo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            labelStyle: TextStyle(color: Colors.black),
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator:
                              (v) =>
                                  v == null || v.isEmpty ? 'Obrigatório' : null,
                        ),
                        TextFormField(
                          controller: _descricaoController,
                          decoration: const InputDecoration(
                            labelText: 'Descrição',
                            labelStyle: TextStyle(color: Colors.black),
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator:
                              (v) =>
                                  v == null || v.isEmpty ? 'Obrigatório' : null,
                        ),
                        TextFormField(
                          controller: _pontuacaoController,
                          decoration: const InputDecoration(
                            labelText: 'Pontuação Máxima',
                            labelStyle: TextStyle(color: Colors.black),
                          ),
                          style: const TextStyle(color: Colors.black),
                          keyboardType: TextInputType.number,
                        ),
                        TextFormField(
                          controller: _regrasController,
                          decoration: const InputDecoration(
                            labelText: 'Regras',
                            labelStyle: TextStyle(color: Colors.black),
                          ),
                          style: const TextStyle(color: Colors.black),
                        ),
                        DropdownButtonFormField<String>(
                          value: _tipoSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            labelStyle: TextStyle(color: Colors.black),
                          ),
                          dropdownColor: const Color(0xFFFFF8E1),
                          items:
                              _tipos
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(
                                        e,
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setState(() => _tipoSelecionado = v!),
                          style: const TextStyle(color: Colors.black),
                        ),
                        DropdownButtonFormField<String>(
                          value: _grupoSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Grupo',
                            labelStyle: TextStyle(color: Colors.black),
                          ),
                          dropdownColor: const Color(0xFFFFF8E1),
                          items:
                              _grupos
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(
                                        e,
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setState(() => _grupoSelecionado = v!),
                          style: const TextStyle(color: Colors.black),
                        ),
                        TextFormField(
                          controller: _tempoController,
                          decoration: const InputDecoration(
                            labelText: 'Tempo Estimado (min)',
                            labelStyle: TextStyle(color: Colors.black),
                          ),
                          style: const TextStyle(color: Colors.black),
                          keyboardType: TextInputType.number,
                        ),
                        TextFormField(
                          controller: _materialController,
                          decoration: const InputDecoration(
                            labelText:
                                'Materiais necessários (separados por vírgula)',
                            labelStyle: TextStyle(color: Colors.black),
                          ),
                          style: const TextStyle(color: Colors.black),
                        ),
                        DropdownButtonFormField<String>(
                          value: _dificuldadeSelecionada,
                          decoration: const InputDecoration(
                            labelText: 'Dificuldade',
                            labelStyle: TextStyle(color: Colors.black),
                          ),
                          dropdownColor: const Color(0xFFFFF8E1),
                          items:
                              _dificuldades
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(
                                        e,
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) =>
                                  setState(() => _dificuldadeSelecionada = v!),
                          style: const TextStyle(color: Colors.black),
                        ),
                        TextFormField(
                          controller: _localPadraoController,
                          decoration: const InputDecoration(
                            labelText: 'Local Padrão',
                            labelStyle: TextStyle(color: Colors.black),
                          ),
                          style: const TextStyle(color: Colors.black),
                        ),
                        TextFormField(
                          controller: _ordemController,
                          decoration: const InputDecoration(
                            labelText: 'Ordem Recomendada',
                            labelStyle: TextStyle(color: Colors.black),
                          ),
                          style: const TextStyle(color: Colors.black),
                          keyboardType: TextInputType.number,
                        ),
                        SwitchListTile(
                          title: const Text(
                            'Avaliação Automática',
                            style: TextStyle(color: Colors.black),
                          ),
                          value: _avaliacaoAutomatica,
                          onChanged:
                              (v) => setState(() => _avaliacaoAutomatica = v),
                        ),
                        SwitchListTile(
                          title: const Text(
                            'Visível para Admin',
                            style: TextStyle(color: Colors.black),
                          ),
                          value: _visivelParaAdmin,
                          onChanged:
                              (v) => setState(() => _visivelParaAdmin = v),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: _salvarJogo,
                          icon: const Icon(Icons.save),
                          label: const Text(
                            'Salvar',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Jogos Criados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('jogos').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Erro ao carregar jogos');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final jogos = snapshot.data!.docs;
                  if (jogos.isEmpty) {
                    return const Text('Nenhum jogo encontrado.');
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) => const Color(
                          0xFFE7DFA8,
                        ), // header like Eventos screen
                      ),
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      dataTextStyle: const TextStyle(color: Colors.black),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Nome',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Tipo',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Dificuldade',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Pontuação Máxima',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Ações',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                      rows:
                          jogos.map((doc) {
                            final data = doc.data()! as Map<String, dynamic>;
                            return DataRow(
                              cells: [
                                DataCell(Text(data['nome'] ?? '')),
                                DataCell(Text(data['tipo'] ?? '')),
                                DataCell(Text(data['nivelDificuldade'] ?? '')),
                                DataCell(
                                  Text((data['pontuacaoMax'] ?? 0).toString()),
                                ),
                                DataCell(
                                  Row(
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
                                          String tipoController =
                                              data['tipo'] ?? 'pontaria';
                                          String dificuldadeController =
                                              data['nivelDificuldade'] ??
                                              'fácil';
                                          final pontuacaoController =
                                              TextEditingController(
                                                text:
                                                    (data['pontuacaoMax'] ?? 0)
                                                        .toString(),
                                              );

                                          showDialog(
                                            context: context,
                                            builder:
                                                (context) => AlertDialog(
                                                  title: const Text(
                                                    'Editar Jogo',
                                                  ),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      TextFormField(
                                                        controller:
                                                            nomeController,
                                                        decoration:
                                                            const InputDecoration(
                                                              labelText: 'Nome',
                                                            ),
                                                      ),
                                                      TextFormField(
                                                        controller:
                                                            pontuacaoController,
                                                        decoration:
                                                            const InputDecoration(
                                                              labelText:
                                                                  'Pontuação Máxima',
                                                            ),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                      ),
                                                      DropdownButtonFormField<
                                                        String
                                                      >(
                                                        value: tipoController,
                                                        decoration:
                                                            const InputDecoration(
                                                              labelText: 'Tipo',
                                                            ),
                                                        items:
                                                            _tipos
                                                                .map(
                                                                  (
                                                                    e,
                                                                  ) => DropdownMenuItem(
                                                                    value: e,
                                                                    child: Text(
                                                                      e,
                                                                    ),
                                                                  ),
                                                                )
                                                                .toList(),
                                                        onChanged:
                                                            (v) =>
                                                                tipoController =
                                                                    v ??
                                                                    tipoController,
                                                      ),
                                                      DropdownButtonFormField<
                                                        String
                                                      >(
                                                        value:
                                                            dificuldadeController,
                                                        decoration:
                                                            const InputDecoration(
                                                              labelText:
                                                                  'Dificuldade',
                                                            ),
                                                        items:
                                                            _dificuldades
                                                                .map(
                                                                  (
                                                                    e,
                                                                  ) => DropdownMenuItem(
                                                                    value: e,
                                                                    child: Text(
                                                                      e,
                                                                    ),
                                                                  ),
                                                                )
                                                                .toList(),
                                                        onChanged:
                                                            (v) =>
                                                                dificuldadeController =
                                                                    v ??
                                                                    dificuldadeController,
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(),
                                                      child: const Text(
                                                        'Cancelar',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection('jogos')
                                                            .doc(doc.id)
                                                            .update({
                                                              'nome':
                                                                  nomeController
                                                                      .text,
                                                              'tipo':
                                                                  tipoController,
                                                              'nivelDificuldade':
                                                                  dificuldadeController,
                                                              'pontuacaoMax':
                                                                  int.tryParse(
                                                                    pontuacaoController
                                                                        .text,
                                                                  ) ??
                                                                  0,
                                                            });
                                                        if (!context.mounted) {
                                                          return;
                                                        }
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Jogo atualizado com sucesso',
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: const Text(
                                                        'Salvar',
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
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder:
                                                (context) => AlertDialog(
                                                  title: const Text(
                                                    'Confirmar exclusão',
                                                  ),
                                                  content: const Text(
                                                    'Tem certeza que deseja deletar este jogo?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(),
                                                      child: const Text(
                                                        'Cancelar',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                        _deletarJogo(doc.id);
                                                      },
                                                      child: const Text(
                                                        'Deletar',
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
            ],
          ),
        ),
      ),
    );
  }
}
