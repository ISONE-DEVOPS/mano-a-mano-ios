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

  String _tipoSelecionado = 'pontaria';

  // Novas variáveis de estado para edição/evento
  String? _selectedEditionId;
  String? _selectedEventId;

  final List<String> _tipos = [
    'pontaria',
    'conhecimento',
    'equilibrio',
    'resistencia',
    'criatividade',
  ];
  final List<String> _dificuldades = ['fácil', 'média', 'difícil'];

  void _salvarJogo() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('jogos').add({
        'nome': _nomeController.text,
        'descricao': _descricaoController.text,
        'pontuacaoMax': int.tryParse(_pontuacaoController.text) ?? 0,
        'regras': _regrasController.text,
        'tipo': _tipoSelecionado,
        // Novos campos
        'editionId': _selectedEditionId,
        'eventId': _selectedEventId,
        // Removed: checkpointId, 'grupo', 'tempoEstimado', 'materialNecessario', 'avaliacaoAutomatica', 'visivelParaAdmin', 'ordemRecomendada', 'nivelDificuldade', 'localPadrao'
      });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
      }
      _formKey.currentState!.reset();
      setState(() {
        _tipoSelecionado = 'pontaria';
        _selectedEditionId = null;
        _selectedEventId = null;
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
                        // --- Edição Dropdown ---
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('editions')
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: LinearProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return const Text('Erro ao carregar edições');
                            }
                            final editions = snapshot.data?.docs ?? [];
                            return DropdownButtonFormField<String>(
                              value: _selectedEditionId,
                              decoration: InputDecoration(
                                labelText: 'Edição',
                                labelStyle: const TextStyle(
                                  color: Colors.black,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items:
                                  editions
                                      .map(
                                        (doc) => DropdownMenuItem<String>(
                                          value: doc.id,
                                          child: Text(
                                            doc['nome'] ?? doc.id,
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedEditionId = val;
                                  _selectedEventId = null;
                                });
                              },
                              style: const TextStyle(color: Colors.black),
                              validator:
                                  (v) => v == null ? 'Obrigatório' : null,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // --- Evento Dropdown ---
                        if (_selectedEditionId != null)
                          StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('editions')
                                    .doc(_selectedEditionId)
                                    .collection('events')
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: LinearProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return const Text('Erro ao carregar eventos');
                              }
                              final events = snapshot.data?.docs ?? [];
                              return DropdownButtonFormField<String>(
                                value: _selectedEventId,
                                decoration: InputDecoration(
                                  labelText: 'Evento',
                                  labelStyle: const TextStyle(
                                    color: Colors.black,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items:
                                    events
                                        .map(
                                          (doc) => DropdownMenuItem<String>(
                                            value: doc.id,
                                            child: Text(
                                              doc['nome'] ?? doc.id,
                                              style: const TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedEventId = val;
                                  });
                                },
                                style: const TextStyle(color: Colors.black),
                                validator:
                                    (v) => v == null ? 'Obrigatório' : null,
                              );
                            },
                          ),
                        if (_selectedEditionId != null)
                          const SizedBox(height: 12),
                        // --- Checkpoint Dropdown REMOVIDO ---
                        TextFormField(
                          controller: _nomeController,
                          decoration: InputDecoration(
                            labelText: 'Nome',
                            labelStyle: const TextStyle(color: Colors.black),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator:
                              (v) =>
                                  v == null || v.isEmpty ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descricaoController,
                          decoration: InputDecoration(
                            labelText: 'Descrição',
                            labelStyle: const TextStyle(color: Colors.black),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator:
                              (v) =>
                                  v == null || v.isEmpty ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pontuacaoController,
                          decoration: InputDecoration(
                            labelText: 'Pontuação Máxima',
                            labelStyle: const TextStyle(color: Colors.black),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _regrasController,
                          decoration: InputDecoration(
                            labelText: 'Regras',
                            labelStyle: const TextStyle(color: Colors.black),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.black),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _tipoSelecionado,
                          decoration: InputDecoration(
                            labelText: 'Tipo',
                            labelStyle: const TextStyle(color: Colors.black),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
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
                        // Removed dropdown de grupo
                        // Removed campo tempoEstimado
                        // Removed campo materialNecessario
                        // Removed dropdown de dificuldade
                        // Removed campo localPadrao
                        // Removed campo ordemRecomendada
                        // Removed SwitchListTile de avaliação automática
                        // Removed SwitchListTile de visível para admin
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
