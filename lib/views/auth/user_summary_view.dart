import 'package:flutter/material.dart';

class UserSummaryView extends StatelessWidget {
  final String nome;
  final String email;
  final String telefone;
  final String emergencia;
  final String equipa;
  final String tShirt;
  final String eventoNome;

  const UserSummaryView({
    super.key,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.emergencia,
    required this.equipa,
    required this.tShirt,
    required this.eventoNome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resumo do Registo')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 600,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    _buildTile('Nome', nome),
                    _buildTile('Email', email),
                    _buildTile('Telefone', telefone),
                    _buildTile('Contacto de Emergência', emergencia),
                    _buildTile('Nome da Equipa', equipa),
                    _buildTile('Tamanho da T-Shirt', tShirt),
                    _buildTile('Evento', eventoNome),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '🎉 Obrigado por se registar no Shell ao KM!\n\nEm breve receberá mais informações com o link para download da App Mobile.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTile(String title, String value) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value),
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}
