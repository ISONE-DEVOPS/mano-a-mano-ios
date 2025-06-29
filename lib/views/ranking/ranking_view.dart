import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/shared/nav_bottom.dart';

class RankingView extends StatelessWidget {
  const RankingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ranking',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFFDD1D21),
        elevation: 0,
        centerTitle: true,
      ),
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
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      index == 0
                                          ? Color(0xFFFFD700) // ouro
                                          : index == 1
                                          ? Color(0xFFC0C0C0) // prata
                                          : index == 2
                                          ? Color(0xFFCD7F32) // bronze
                                          : Color(0xFFDD1D21),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: const Text(
                                  'Equipa desconhecida',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'Pontos: ${data['pontuacao'] ?? 0}',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                            );
                          }
                          final equipaData =
                              snapshot.data?.data() as Map<String, dynamic>?;
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    index == 0
                                        ? Color(0xFFFFD700) // ouro
                                        : index == 1
                                        ? Color(0xFFC0C0C0) // prata
                                        : index == 2
                                        ? Color(0xFFCD7F32) // bronze
                                        : Color(0xFFDD1D21),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      equipaData?['nome'] ?? 'Equipa',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (index == 0)
                                    const Icon(
                                      Icons.emoji_events,
                                      color: Color(0xFFFFD700),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                'Pontos: ${data['pontuacao'] ?? 0}',
                                style: const TextStyle(color: Colors.black87),
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
            Navigator.pushReplacementNamed(
              context,
              [
                '/home',
                '/my-events',
                '/checkin',
                '/ranking',
                '/profile',
              ][index],
            );
          }
        },
      ),
    );
  }
}
