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
  final List<TextEditingController> _opcoes = List.generate(
    3,
    (_) => TextEditingController(),
  );
  int _respostaCorreta = 0;
  List<String> _postos = [];

  @override
  void initState() {
    super.initState();
    _carregarEdicoes();
  }

  void _carregarEdicoes() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('editions').get();
    final mapa = {
      for (var doc in snapshot.docs) doc.id: doc['nome'] ?? 'Sem nome',
    };
    setState(() {
      _edicoes = Map<String, String>.from(mapa);
    });
  }

  void _carregarEventos(String editionId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('editions')
        .doc(editionId)
        .collection('events')
        .get();
    final mapa = {
      for (var doc in snapshot.docs) doc.id: doc['nome'] ?? 'Sem nome',
    };
    setState(() {
      _eventos = Map<String, String>.from(mapa);
    });
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
    final nomes = snapshot.docs.map((doc) => doc.id).toList()..sort();
    setState(() => _postos = nomes);
  }

  void _salvarPergunta() async {
    final pergunta = _perguntaController.text.trim();
    final categoria = _categoriaController.text.trim();
    final opcoes = _opcoes.map((c) => c.text.trim()).toList();

    // Verificação se o evento e o posto são válidos
    if (_edicaoSelecionada == null || _eventoSelecionado == null || _checkpointSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma edição, um evento e um checkpoint válido'),
        ),
      );
      return;
    }

    if (pergunta.isEmpty || categoria.isEmpty || opcoes.any((o) => o.isEmpty)) {
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
        'pontos': 10,
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
      for (final c in _opcoes) {
        c.clear();
      }
      setState(() {
        _respostaCorreta = 0;
        _postos = [];
        _eventos = {};
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
                    DropdownButtonFormField<String>(
                      style: const TextStyle(color: Colors.black),
                      onChanged: (value) {
                        setState(() {
                          _edicaoSelecionada = value;
                          _eventoSelecionado = null;
                          _checkpointSelecionado = null;
                          _eventos = {};
                          _postos = [];
                          if (value != null) {
                            _carregarEventos(value);
                          }
                        });
                      },
                      items: _edicoes.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      style: const TextStyle(color: Colors.black),
                      onChanged: (value) {
                        setState(() {
                          _eventoSelecionado = value;
                          _checkpointSelecionado = null;
                          _postos = [];
                          if (value != null) {
                            _carregarPostos(value);
                          }
                        });
                      },
                      items: _eventos.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      style: const TextStyle(color: Colors.black),
                      value: _checkpointSelecionado,
                      onChanged: (value) {
                        setState(() {
                          _checkpointSelecionado = value;
                        });
                      },
                      items: _postos.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(
                            p,
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: 'Checkpoint',
                        labelStyle: const TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                                  style: const TextStyle(
                                    color: Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Opção ${index + 1}',
                                    labelStyle: const TextStyle(
                                      color: Colors.black,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: _salvarPergunta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
            // O restante do código permanece igual, com consts adicionados nos widgets apropriados, como:
            // const EdgeInsets.all(...), const SizedBox(...), const TextStyle(...), const Icon(...), const NeverScrollableScrollPhysics(), etc.
          ],
        ),
      ),
    );
  }
}
