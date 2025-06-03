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
  final List<TextEditingController> _opcoes = List.generate(
    3,
    (_) => TextEditingController(),
  );
  int _respostaCorreta = 0;

  void _salvarPergunta() async {
    final pergunta = _perguntaController.text.trim();
    final opcoes = _opcoes.map((c) => c.text.trim()).toList();

    if (pergunta.isEmpty || opcoes.any((o) => o.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('questions').add({
        'posto': _postoController.text.trim(),
        'pergunta': pergunta,
        'opcoes': opcoes,
        'correta': _respostaCorreta,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pergunta salva com sucesso')),
      );
      _postoController.clear();
      _perguntaController.clear();
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
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Criar Pergunta',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Posto (opcional)'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value:
                  _postoController.text.isNotEmpty
                      ? _postoController.text
                      : null,
              items: List.generate(
                40,
                (index) => DropdownMenuItem(
                  value: 'posto${index + 1}',
                  child: Text('Posto ${index + 1}'),
                ),
              ),
              onChanged: (value) {
                setState(() => _postoController.text = value ?? '');
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Selecionar Posto',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Pergunta'),
            const SizedBox(height: 6),
            TextField(
              controller: _perguntaController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Text('Opções de Resposta'),
            const SizedBox(height: 6),
            for (int i = 0; i < 3; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: TextField(
                  controller: _opcoes[i],
                  decoration: InputDecoration(
                    labelText: 'Opção ${i + 1}',
                    border: const OutlineInputBorder(),
                  ),
                ),
                leading: Radio<int>(
                  value: i,
                  groupValue: _respostaCorreta,
                  onChanged: (value) {
                    setState(() => _respostaCorreta = value!);
                  },
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
                child: const Text('Salvar Pergunta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
