import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mano_mano_dashboard/widgets/shared/staff_app_bar.dart';
import 'package:mano_mano_dashboard/widgets/shared/staff_nav_bottom.dart';

class PontuacaoQrView extends StatelessWidget {
  const PontuacaoQrView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StaffAppBar(title: 'Jogos Disponíveis'),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('jogos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum jogo encontrado.'));
          }

          final jogos = snapshot.data!.docs;

          return ListView.builder(
            itemCount: jogos.length,
            itemBuilder: (context, index) {
              final jogo = jogos[index];
              final nome = jogo['nome'] ?? 'Sem nome';
              final descricao = jogo['descricao'] ?? '';
              final tipo = jogo['tipo'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(descricao),
                      const SizedBox(height: 4),
                      Text('Tipo: $tipo', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const StaffNavBottom(),
    );
  }
}