


import 'package:flutter/material.dart';

/// Tela de perguntas de checkpoint onde os participantes devem responder corretamente
/// para continuar no Rally Paper. Apresenta duas perguntas com campos de resposta.
class CheckpointQuestionsView extends StatefulWidget {
  const CheckpointQuestionsView({super.key});

  @override
  State<CheckpointQuestionsView> createState() => _CheckpointQuestionsViewState();
}

class _CheckpointQuestionsViewState extends State<CheckpointQuestionsView> {
  final _formKey = GlobalKey<FormState>();
  final _answers = <String?>['', ''];

  final _questions = [
    'Qual é o nome do combustível aditivado da Shell?',
    'Qual destes produtos é um lubrificante?'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perguntas do Checkpoint')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              for (int i = 0; i < _questions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: _questions[i],
                      border: const OutlineInputBorder(),
                    ),
                    onSaved: (value) => _answers[i] = value,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Resposta obrigatória' : null,
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Submeter'),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Aqui deve-se fazer a verificação das respostas e registo no backend
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Respostas Recebidas'),
          content: Text('Resposta 1: ${_answers[0]}\nResposta 2: ${_answers[1]}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    }
  }
}