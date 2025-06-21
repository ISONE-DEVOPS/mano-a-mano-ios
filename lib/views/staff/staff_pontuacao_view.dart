import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mano_mano_dashboard/widgets/shared/staff_app_bar.dart';

class StaffPontuacaoView extends StatelessWidget {
  const StaffPontuacaoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StaffAppBar(title: 'Pontuação das Equipas'),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('equipas')
                .orderBy('pontuacaoTotal', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma equipa encontrada.'));
          }

          final equipas = snapshot.data!.docs;

          return ListView.builder(
            itemCount: equipas.length,
            itemBuilder: (context, index) {
              final equipa = equipas[index];
              final nome = equipa['nome'] ?? 'Sem Nome';
              final pontos = equipa['pontuacaoTotal'] ?? 0;

              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(nome),
                trailing: Text('$pontos pontos'),
              );
            },
          );
        },
      ),
    );
  }
}
