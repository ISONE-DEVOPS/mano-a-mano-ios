import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';

class PerguntasView extends StatefulWidget {
  const PerguntasView({super.key});

  @override
  State<PerguntasView> createState() => _PerguntasViewState();
}

class _PerguntasViewState extends State<PerguntasView> {
  final _postoController = TextEditingController();
  final _perguntaController = TextEditingController();
  final _categoriaController = TextEditingController();
  final List<TextEditingController> _opcoes = List.generate(
    3,
    (_) => TextEditingController(),
  );
  int _respostaCorreta = 0;
  List<String> _postos = [];
  Map<String, String> _eventos = {};
  String? _eventoSelecionado;

  @override
  void initState() {
    super.initState();
    _carregarEventos();
  }

  void _carregarEventos() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('events').get();
    final mapa = {
      for (var doc in snapshot.docs) doc.id: doc['nome'] ?? 'Sem nome',
    };
    setState(() {
      _eventos = Map<String, String>.from(mapa);
    });
  }

  void _carregarPostos(String eventId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .get();
    final data = doc.data();
    if (data == null || !data.containsKey('checkpoints')) return;
    final cps = Map<String, dynamic>.from(data['checkpoints']);
    setState(() => _postos = cps.keys.toList()..sort());
  }

  void _salvarPergunta() async {
    final pergunta = _perguntaController.text.trim();
    final categoria = _categoriaController.text.trim();
    final opcoes = _opcoes.map((c) => c.text.trim()).toList();

    // Verificação se o evento e o posto são válidos
    if (_eventoSelecionado == null ||
        !_postos.contains(_postoController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um evento e um posto válido')),
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
      await FirebaseFirestore.instance.collection('questions').add({
        'evento_id': _eventoSelecionado,
        'posto': _postoController.text.trim(),
        'pergunta': pergunta,
        'categoria': categoria,
        'options': opcoes,
        'correta': _respostaCorreta,
        'pontos': 10,
        'createAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pergunta salva com sucesso')),
      );
      _postoController.clear();
      _perguntaController.clear();
      _categoriaController.clear();
      for (final c in _opcoes) {
        c.clear();
      }
      setState(() => _respostaCorreta = 0);
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
            // Card para o formulário de criação
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
                    Text(
                      'Cadastrar Pergunta',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: DropdownButtonFormField<String>(
                        value: _eventoSelecionado,
                        decoration: InputDecoration(
                          labelText: 'Evento',
                          filled: true,
                          fillColor: Colors.grey.shade300,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          labelStyle: const TextStyle(color: Colors.black),
                        ),
                        style: const TextStyle(color: Colors.black),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.black54,
                        ),
                        items:
                            _eventos.entries.map((entry) {
                              return DropdownMenuItem(
                                value: entry.key,
                                child: Text(
                                  entry.value,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.black),
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _eventoSelecionado = value;
                            _carregarPostos(value!);
                            _postoController.clear();
                            _postos.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: DropdownButtonFormField<String>(
                        value:
                            _postoController.text.isNotEmpty
                                ? _postoController.text
                                : null,
                        decoration: InputDecoration(
                          labelText: 'Posto',
                          filled: true,
                          fillColor: Colors.grey.shade300,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          labelStyle: const TextStyle(color: Colors.black),
                        ),
                        style: const TextStyle(color: Colors.black),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.black54,
                        ),
                        items:
                            _postos.map((posto) {
                              return DropdownMenuItem(
                                value: posto,
                                child: Text(
                                  posto,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.black),
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() => _postoController.text = value ?? '');
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _perguntaController,
                      decoration: InputDecoration(
                        labelText: 'Pergunta',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelStyle: const TextStyle(color: Colors.black),
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _categoriaController,
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelStyle: const TextStyle(color: Colors.black),
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Opções de Resposta',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.black),
                    ),
                    const SizedBox(height: 6),
                    ...List.generate(
                      3,
                      (i) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: TextFormField(
                          controller: _opcoes[i],
                          decoration: InputDecoration(
                            labelText: 'Opção ${i + 1}',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelStyle: const TextStyle(color: Colors.black),
                          ),
                          style: const TextStyle(color: Colors.black),
                        ),
                        leading: Radio<int>(
                          value: i,
                          groupValue: _respostaCorreta,
                          onChanged: (value) {
                            setState(() => _respostaCorreta = value!);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: _salvarPergunta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryDark,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          'Salvar Pergunta',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Divider(thickness: 1.2),
            const SizedBox(height: 12),
            Text(
              'Perguntas cadastradas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.black),
            ),
            const SizedBox(height: 12),
            // StreamBuilder<QuerySnapshot>(
            //   stream: FirebaseFirestore.instance
            //       .collection('questions')
            //       .orderBy('createAt', descending: true)
            //       .snapshots(),
            //   builder: (context, snapshot) {
            //     if (!snapshot.hasData) {
            //       return const Center(child: CircularProgressIndicator());
            //     }
            //     final docs = snapshot.data!.docs;
            //     if (docs.isEmpty) {
            //       return Padding(
            //         padding: const EdgeInsets.symmetric(vertical: 24),
            //         child: Text(
            //           'Nenhuma pergunta cadastrada.',
            //           style: Theme.of(
            //             context,
            //           ).textTheme.bodyLarge?.copyWith(color: Colors.black),
            //         ),
            //       );
            //     }
            //     // Troca Column + List.generate por ListView.builder
            //     return ListView.builder(
            //       shrinkWrap: true,
            //       physics: NeverScrollableScrollPhysics(),
            //       itemCount: docs.length,
            //       itemBuilder: (context, index) {
            //         final data = docs[index].data() as Map<String, dynamic>;
            //         final opcoes = List<String>.from(data['options']);
            //         final correta = data['correta'] as int;
            //         return Card(
            //           elevation: 2,
            //           margin: const EdgeInsets.symmetric(vertical: 8),
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(12),
            //           ),
            //           child: Padding(
            //             padding: const EdgeInsets.symmetric(
            //               horizontal: 16,
            //               vertical: 16,
            //             ),
            //             child: Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               children: [
            //                 // Botões no topo do card
            //                 Row(
            //                   mainAxisAlignment: MainAxisAlignment.end,
            //                   children: [
            //                     IconButton(
            //                       icon: const Icon(
            //                         Icons.edit,
            //                         color: Colors.blue,
            //                       ),
            //                       tooltip: 'Editar',
            //                       onPressed: () {
            //                         final perguntaController =
            //                             TextEditingController(
            //                               text: data['pergunta'],
            //                             );
            //                         final opcoes = List<String>.from(
            //                           data['options'],
            //                         );
            //                         final List<TextEditingController>
            //                         opcoesControllers = List.generate(
            //                           opcoes.length,
            //                           (i) => TextEditingController(
            //                             text: opcoes[i],
            //                           ),
            //                         );
            //                         int respostaCorreta = data['correta'];
            //                         final pontosController =
            //                             TextEditingController(
            //                               text: '${data['pontos'] ?? 10}',
            //                             );
            //                         final categoriaController =
            //                             TextEditingController(
            //                               text: data['categoria'] ?? '',
            //                             );
            //
            //                         showDialog(
            //                           context: context,
            //                           builder: (_) {
            //                             return AlertDialog(
            //                               title: const Text(
            //                                 'Editar Pergunta',
            //                                 style: TextStyle(
            //                                   color: Colors.black,
            //                                 ),
            //                               ),
            //                               content: SingleChildScrollView(
            //                                 child: Column(
            //                                   mainAxisSize: MainAxisSize.min,
            //                                   children: [
            //                                     TextFormField(
            //                                       controller:
            //                                           pontosController,
            //                                       keyboardType:
            //                                           TextInputType.number,
            //                                       decoration:
            //                                           const InputDecoration(
            //                                             labelText: 'Pontos',
            //                                             labelStyle: TextStyle(
            //                                               color: Colors.black,
            //                                             ),
            //                                           ),
            //                                       style: TextStyle(
            //                                         color: Colors.black,
            //                                       ),
            //                                     ),
            //                                     const SizedBox(height: 12),
            //                                     TextFormField(
            //                                       controller:
            //                                           categoriaController,
            //                                       decoration:
            //                                           const InputDecoration(
            //                                             labelText:
            //                                                 'Categoria',
            //                                             labelStyle: TextStyle(
            //                                               color: Colors.black,
            //                                             ),
            //                                           ),
            //                                       style: TextStyle(
            //                                         color: Colors.black,
            //                                       ),
            //                                     ),
            //                                     const SizedBox(height: 12),
            //                                     TextFormField(
            //                                       controller:
            //                                           perguntaController,
            //                                       decoration:
            //                                           const InputDecoration(
            //                                             labelText: 'Pergunta',
            //                                             labelStyle: TextStyle(
            //                                               color: Colors.black,
            //                                             ),
            //                                           ),
            //                                       style: TextStyle(
            //                                         color: Colors.black,
            //                                       ),
            //                                     ),
            //                                     const SizedBox(height: 12),
            //                                     for (int i = 0; i < 3; i++)
            //                                       ListTile(
            //                                         contentPadding:
            //                                             EdgeInsets.zero,
            //                                         title: TextFormField(
            //                                           controller:
            //                                               opcoesControllers[i],
            //                                           decoration: InputDecoration(
            //                                             labelText:
            //                                                 'Opção ${i + 1}',
            //                                             labelStyle: TextStyle(
            //                                               color: Colors.black,
            //                                             ),
            //                                           ),
            //                                           style: TextStyle(
            //                                             color: Colors.black,
            //                                           ),
            //                                         ),
            //                                         leading: Radio<int>(
            //                                           value: i,
            //                                           groupValue:
            //                                               respostaCorreta,
            //                                           onChanged: (val) {
            //                                             Navigator.of(
            //                                               context,
            //                                             ).pop();
            //                                             setState(() {
            //                                               respostaCorreta =
            //                                                   val!;
            //                                               docs[index].reference.update({
            //                                                 'pergunta':
            //                                                     perguntaController
            //                                                         .text
            //                                                         .trim(),
            //                                                 'options':
            //                                                     opcoesControllers
            //                                                         .map(
            //                                                           (c) =>
            //                                                               c.text.trim(),
            //                                                         )
            //                                                         .toList(),
            //                                                 'correta':
            //                                                     respostaCorreta,
            //                                                 'pontos':
            //                                                     int.tryParse(
            //                                                       pontosController
            //                                                           .text,
            //                                                     ) ??
            //                                                     10,
            //                                                 'categoria':
            //                                                     categoriaController
            //                                                         .text
            //                                                         .trim(),
            //                                               });
            //                                             });
            //                                           },
            //                                         ),
            //                                       ),
            //                                   ],
            //                                 ),
            //                               ),
            //                               actions: [
            //                                 TextButton(
            //                                   onPressed: () {
            //                                     Navigator.pop(context);
            //                                   },
            //                                   child: const Text(
            //                                     'Cancelar',
            //                                     style: TextStyle(
            //                                       color: Colors.black,
            //                                     ),
            //                                   ),
            //                                 ),
            //                                 ElevatedButton(
            //                                   onPressed: () async {
            //                                     await docs[index].reference
            //                                         .update({
            //                                           'pergunta':
            //                                               perguntaController
            //                                                   .text
            //                                                   .trim(),
            //                                           'options':
            //                                               opcoesControllers
            //                                                   .map(
            //                                                     (c) =>
            //                                                         c.text
            //                                                             .trim(),
            //                                                   )
            //                                                   .toList(),
            //                                           'correta':
            //                                               respostaCorreta,
            //                                           'pontos':
            //                                               int.tryParse(
            //                                                 pontosController
            //                                                     .text,
            //                                               ) ??
            //                                               10,
            //                                           'categoria':
            //                                               categoriaController
            //                                                   .text
            //                                                   .trim(),
            //                                         });
            //                                     if (context.mounted) {
            //                                       Navigator.pop(context);
            //                                     }
            //                                   },
            //                                   child: const Text(
            //                                     'Salvar',
            //                                     style: TextStyle(
            //                                       color: Colors.black,
            //                                     ),
            //                                   ),
            //                                 ),
            //                               ],
            //                             );
            //                           },
            //                         );
            //                       },
            //                     ),
            //                     IconButton(
            //                       icon: const Icon(
            //                         Icons.delete,
            //                         color: Colors.red,
            //                       ),
            //                       tooltip: 'Apagar',
            //                       onPressed: () async {
            //                         await docs[index].reference.delete();
            //                         if (context.mounted) {
            //                           ScaffoldMessenger.of(
            //                             context,
            //                           ).showSnackBar(
            //                             const SnackBar(
            //                               content: Text(
            //                                 'Pergunta apagada com sucesso',
            //                               ),
            //                             ),
            //                           );
            //                         }
            //                       },
            //                     ),
            //                   ],
            //                 ),
            //                 const SizedBox(height: 6),
            //                 Text(
            //                   data['pergunta'] ?? '',
            //                   style: Theme.of(context).textTheme.titleMedium
            //                       ?.copyWith(color: Colors.black),
            //                 ),
            //                 const SizedBox(height: 2),
            //                 Text(
            //                   'Categoria: ${data['categoria'] ?? ''} | Pontos: ${data['pontos'] ?? 0}',
            //                   style: Theme.of(context).textTheme.bodySmall
            //                       ?.copyWith(color: Colors.black),
            //                 ),
            //                 const SizedBox(height: 10),
            //                 ...List.generate(opcoes.length, (i) {
            //                   final isCorreta = i == correta;
            //                   return Padding(
            //                     padding: const EdgeInsets.symmetric(
            //                       vertical: 2,
            //                     ),
            //                     child: Row(
            //                       children: [
            //                         Icon(
            //                           isCorreta
            //                               ? Icons.check_circle
            //                               : Icons.circle_outlined,
            //                           color:
            //                               isCorreta
            //                                   ? Colors.green
            //                                   : Colors.grey,
            //                           size: 18,
            //                         ),
            //                         const SizedBox(width: 6),
            //                         Expanded(
            //                           child: Text(
            //                             opcoes[i],
            //                             style: TextStyle(
            //                               color: isCorreta ? Colors.green : Colors.black,
            //                               fontWeight: isCorreta ? FontWeight.bold : FontWeight.normal,
            //                             ),
            //                           ),
            //                         ),
            //                       ],
            //                     ),
            //                   );
            //                 }),
            //               ],
            //             ),
            //           ),
            //         );
            //       },
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
