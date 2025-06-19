import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';

class PerguntasView extends StatefulWidget {
  const PerguntasView({super.key});

  @override
  State<PerguntasView> createState() => _PerguntasViewState();
}

class _PerguntasViewState extends State<PerguntasView> {
  String? _edicaoSelecionada;
  Map<String, String> _edicoes = {};
  String? _eventoSelecionado;
  Map<String, String> _eventos = {};
  String? _checkpointSelecionado;
  final _perguntaController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _pontosController =
      TextEditingController(); // Novo controlador para pontos
  final List<TextEditingController> _opcoes = List.generate(
    3,
    (_) => TextEditingController(),
  );
  int _respostaCorreta = 0;
  Map<String, String> _postos = {};

  @override
  void initState() {
    super.initState();
    _carregarEdicoes();
  }

  void _carregarEdicoes() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('editions').get();
    final mapa = {
      for (var doc in snapshot.docs)
        doc.id: doc.data()['nome']?.toString() ?? doc.id,
    };
    setState(() => _edicoes = Map<String, String>.from(mapa));
  }

  void _carregarEventos(String editionId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('editions')
            .doc(editionId)
            .collection('events')
            .get();
    final mapa = {
      for (var doc in snapshot.docs)
        doc.id: doc.data()['nome']?.toString() ?? doc.id,
    };
    setState(() => _eventos = Map<String, String>.from(mapa));
  }

  void _carregarPostos(String eventId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('editions')
            .doc(_edicaoSelecionada)
            .collection('events')
            .doc(eventId)
            .collection('checkpoints')
            .get();
    final mapa = {
      for (var doc in snapshot.docs)
        doc.id: doc.data()['nome']?.toString() ?? doc.id,
    };
    setState(() => _postos = Map<String, String>.from(mapa));
  }

  void _salvarPergunta() async {
    final pergunta = _perguntaController.text.trim();
    final categoria = _categoriaController.text.trim();
    final opcoes = _opcoes.map((c) => c.text.trim()).toList();
    final pontosText = _pontosController.text.trim();
    final pontos = int.tryParse(pontosText);

    // Verificação se o evento e o posto são válidos
    if (_edicaoSelecionada == null ||
        _eventoSelecionado == null ||
        _checkpointSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione uma edição, um evento e um checkpoint válido',
          ),
        ),
      );
      return;
    }

    if (pergunta.isEmpty ||
        categoria.isEmpty ||
        opcoes.any((o) => o.isEmpty) ||
        pontos == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('perguntas').add({
        'editionId': _edicaoSelecionada,
        'eventId': _eventoSelecionado,
        'checkpointId': _checkpointSelecionado,
        'pergunta': pergunta,
        'categoria': categoria,
        'respostas': opcoes,
        'respostaCerta': _respostaCorreta,
        'pontos': pontos,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pergunta salva com sucesso')),
      );
      _checkpointSelecionado = null;
      _eventoSelecionado = null;
      _edicaoSelecionada = null;
      _perguntaController.clear();
      _categoriaController.clear();
      _pontosController.clear();
      for (final c in _opcoes) {
        c.clear();
      }
      setState(() {
        _respostaCorreta = 0;
        // Limpa corretamente os mapas como Map<String, String>
        _postos = <String, String>{};
        _eventos = <String, String>{};
        _edicoes = _edicoes;
      });
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          shrinkWrap: true,
          children: [
            // Formulário de criação de pergunta (sem Card aninhado)
            Card(
              elevation: 4,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cadastrar Pergunta',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // 1. Edição
                    DropdownButtonFormField<String>(
                      style: const TextStyle(color: Colors.black),
                      onChanged: (value) {
                        setState(() {
                          _edicaoSelecionada = value;
                          _eventoSelecionado = null;
                          _checkpointSelecionado = null;
                          _eventos = {};
                          _postos = {};
                          if (value != null) {
                            _carregarEventos(value);
                          }
                        });
                      },
                      items:
                          _edicoes.entries
                              .map(
                                (entry) => DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              )
                              .toList(),
                      value: _edicaoSelecionada,
                      decoration: InputDecoration(
                        labelText: 'Edição',
                        labelStyle: const TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 2. Evento
                    DropdownButtonFormField<String>(
                      style: const TextStyle(color: Colors.black),
                      onChanged: (value) {
                        setState(() {
                          _eventoSelecionado = value;
                          _checkpointSelecionado = null;
                          _postos = {};
                          if (value != null) {
                            _carregarPostos(value);
                          }
                        });
                      },
                      items:
                          _eventos.entries
                              .map(
                                (entry) => DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              )
                              .toList(),
                      value: _eventoSelecionado,
                      decoration: InputDecoration(
                        labelText: 'Evento',
                        labelStyle: const TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 3. Checkpoint (mostrar nome do checkpoint, não ID)
                    DropdownButtonFormField<String>(
                      style: const TextStyle(color: Colors.black),
                      value: _checkpointSelecionado,
                      onChanged: (value) {
                        setState(() {
                          _checkpointSelecionado = value;
                        });
                      },
                      items:
                          _postos.entries
                              .map(
                                (entry) => DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              )
                              .toList(),
                      decoration: InputDecoration(
                        labelText: 'Checkpoint',
                        labelStyle: const TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 4. Pergunta
                    TextFormField(
                      controller: _perguntaController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Pergunta',
                        labelStyle: const TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 5. Opções de resposta (Radio + campos de texto)
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Opções',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: List.generate(_opcoes.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: index,
                                groupValue: _respostaCorreta,
                                onChanged: (value) {
                                  setState(() {
                                    _respostaCorreta = value!;
                                  });
                                },
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _opcoes[index],
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'Opção ${index + 1}',
                                    labelStyle: const TextStyle(
                                      color: Colors.black,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    // 6. Categoria
                    TextFormField(
                      controller: _categoriaController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        labelStyle: const TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 7. Pontuação
                    TextFormField(
                      controller: _pontosController,
                      style: const TextStyle(color: Colors.black),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Pontuação',
                        labelStyle: const TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: _salvarPergunta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Salvar Pergunta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Divider(thickness: 1.2),
            const SizedBox(height: 12),
            const Text(
              'Perguntas cadastradas',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            // Lista de perguntas cadastradas para o checkpoint selecionado
            if (_checkpointSelecionado != null)
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('perguntas')
                        .where(
                          'checkpointId',
                          isEqualTo: _checkpointSelecionado,
                        )
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text(
                      'Nenhuma pergunta cadastrada para este checkpoint.',
                    );
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(
                          data['pergunta'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Categoria: ${data['categoria'] ?? ''} | Pontos: ${data['pontos'] ?? ''}',
                        ),
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
}
