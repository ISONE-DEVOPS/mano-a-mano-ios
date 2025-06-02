

import 'package:flutter/material.dart';

/// Tela que permite aos participantes personalizar a equipa:
/// escolher nome da equipa, desenhar bandeira e criar grito de guerra.
class TeamCustomizationView extends StatefulWidget {
  const TeamCustomizationView({super.key});

  @override
  State<TeamCustomizationView> createState() => _TeamCustomizationViewState();
}

class _TeamCustomizationViewState extends State<TeamCustomizationView> {
  final _formKey = GlobalKey<FormState>();
  String _teamName = '';
  String _battleCry = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personalização da Equipa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nome da Equipa',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _teamName = value ?? '',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Grito de Guerra',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _battleCry = value ?? '',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Guardar Personalização'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Equipa Personalizada'),
          content: Text('Nome: $_teamName\nGrito de Guerra: $_battleCry'),
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