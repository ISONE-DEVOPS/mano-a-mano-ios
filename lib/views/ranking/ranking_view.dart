import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/shared/nav_bottom.dart';

class RankingView extends StatelessWidget {
  const RankingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ranking'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Classificação Geral',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('ranking')
                        .orderBy('pontuacao', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('Nenhum dado de ranking disponível.'),
                    );
                  }
                  final rankingDocs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: rankingDocs.length,
                    itemBuilder: (context, index) {
                      final data =
                          rankingDocs[index].data() as Map<String, dynamic>;
                      return FutureBuilder<DocumentSnapshot?>(
                        future:
                            data['equipaId'] != null &&
                                    data['equipaId'].toString().isNotEmpty
                                ? FirebaseFirestore.instance
                                    .collection('equipas')
                                    .doc(data['equipaId'])
                                    .get()
                                : Future.value(null),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data?.data() == null) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey,
                                child: Text('${index + 1}'),
                              ),
                              title: const Text('Equipa desconhecida'),
                              subtitle: Text(
                                'Pontos: ${data['pontuacao'] ?? 0}',
                              ),
                            );
                          }
                          final equipaData =
                              snapshot.data?.data() as Map<String, dynamic>?;
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.amber,
                                child: Text('${index + 1}'),
                              ),
                              title: Text(equipaData?['nome'] ?? 'Equipa'),
                              subtitle: Text(
                                'Pontos: ${data['pontuacao'] ?? 0}',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          if (index != 3) {
            Navigator.pushReplacementNamed(context, [
              '/home',
              '/my-events',
              '/checkin',
              '/ranking',
              '/profile',
            ][index]);
          }
        },
      ),
    );
  }
}
