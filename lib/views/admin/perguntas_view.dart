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
  final _perguntaController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _pontosController =
      TextEditingController(); // Novo controlador para pontos
  final List<TextEditingController> _opcoes = List.generate(
    3,
    (_) => TextEditingController(),
  );
  int _respostaCorreta = 0;
  String? _perguntaIdEmEdicao;

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

  void _salvarPergunta() async {
    final pergunta = _perguntaController.text.trim();
    final categoria = _categoriaController.text.trim();
    final opcoes = _opcoes.map((c) => c.text.trim()).toList();
    final pontosText = _pontosController.text.trim();
    final pontos = int.tryParse(pontosText);

    if (_edicaoSelecionada == null || _eventoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma edição e um evento válido'),
        ),
      );
      return;
    }

    if (pergunta.isEmpty ||
        categoria.isEmpty ||
        opcoes.any((o) => o.isEmpty) ||
        pontos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha todos os campos',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
        ),
      );
      return;
    }

    try {
      if (_perguntaIdEmEdicao != null) {
        // Verificação de ID inválido antes de atualizar
        if (_perguntaIdEmEdicao != null && _perguntaIdEmEdicao!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro interno: ID da pergunta inválido'),
            ),
          );
          return;
        }
        // atualizar
        await FirebaseFirestore.instance
            .collection('perguntas')
            .doc(_perguntaIdEmEdicao!)
            .update({
              'editionId': _edicaoSelecionada,
              'eventId': _eventoSelecionado,
              'pergunta': pergunta,
              'categoria': categoria,
              'respostas': opcoes,
              'respostaCerta': _respostaCorreta,
              'pontos': pontos,
            });
      } else {
        // criar novo
        await FirebaseFirestore.instance.collection('perguntas').add({
          'editionId': _edicaoSelecionada,
          'eventId': _eventoSelecionado,
          'pergunta': pergunta,
          'categoria': categoria,
          'respostas': opcoes,
          'respostaCerta': _respostaCorreta,
          'pontos': pontos,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pergunta salva com sucesso',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
        ),
      );

      _edicaoSelecionada = null;
      _eventoSelecionado = null;
      _perguntaController.clear();
      _categoriaController.clear();
      _pontosController.clear();
      for (final c in _opcoes) {
        c.clear();
      }

      setState(() {
        _respostaCorreta = 0;
        _eventos = <String, String>{};
        _perguntaIdEmEdicao = null;
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
                      initialValue: _edicaoSelecionada,
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
                      initialValue: _eventoSelecionado,
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
                    // 3. Checkpoint removido
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
                    // Implementação sem Radio.groupValue (deprecated):
                    // Mantemos os campos de texto das opções e usamos um SegmentedButton
                    // para escolher qual é a resposta correta.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Campos de texto das opções
                        ...List.generate(_opcoes.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              controller: _opcoes[index],
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Opção ${index + 1}',
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
                          );
                        }),
                        const SizedBox(height: 12),
                        const Text(
                          'Selecione a resposta correta',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Novo seletor de opção correta usando Material 3 SegmentedButton
                        SegmentedButton<int>(
                          segments: [
                            for (int i = 0; i < _opcoes.length; i++)
                              ButtonSegment<int>(
                                value: i,
                                label: Text('Opção ${i + 1}'),
                              ),
                          ],
                          multiSelectionEnabled: false,
                          selected: {_respostaCorreta},
                          onSelectionChanged: (selection) {
                            if (selection.isEmpty) return;
                            setState(() => _respostaCorreta = selection.first);
                          },
                        ),
                      ],
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
                    const SizedBox(height: 12),
                    if (_perguntaIdEmEdicao != null)
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text(
                            'Cancelar edição',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            setState(() {
                              _perguntaIdEmEdicao = null;
                              _perguntaController.clear();
                              _categoriaController.clear();
                              _pontosController.clear();
                              _respostaCorreta = 0;
                              for (final c in _opcoes) {
                                c.clear();
                              }
                            });
                          },
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
            // Lista de todas as perguntas cadastradas, ordenadas por data de criação
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('perguntas')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('Nenhuma pergunta cadastrada.');
                }
                final docs = snapshot.data!.docs;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isEditing =
                        _perguntaIdEmEdicao == snapshot.data!.docs[index].id;
                    return ListTile(
                      tileColor: isEditing ? Colors.yellow[100] : null,
                      title: Text(
                        data['pergunta'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        'Categoria: ${data['categoria'] ?? ''} | Pontos: ${data['pontos'] ?? ''}',
                        style: const TextStyle(color: Colors.black),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () {
                              final pergunta = data['pergunta'] ?? '';
                              final categoria = data['categoria'] ?? '';
                              final pontos = data['pontos']?.toString() ?? '';
                              final respostas = data['respostas'] ?? [];
                              final respostaCerta = data['respostaCerta'] ?? 0;

                              setState(() {
                                _perguntaIdEmEdicao =
                                    snapshot.data!.docs[index].id;
                                _perguntaController.text = pergunta;
                                _categoriaController.text = categoria;
                                _pontosController.text = pontos;
                                _respostaCorreta = respostaCerta;
                                for (int i = 0; i < _opcoes.length; i++) {
                                  _opcoes[i].text =
                                      i < respostas.length ? respostas[i] : '';
                                }
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text(
                                        'Eliminar Pergunta',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      content: const Text(
                                        'Tem certeza que deseja eliminar esta pergunta?',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.of(ctx).pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(ctx).pop(true),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirm == true) {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('perguntas')
                                      .doc(snapshot.data!.docs[index].id)
                                      .delete();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Pergunta eliminada com sucesso',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Erro ao eliminar pergunta: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
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
