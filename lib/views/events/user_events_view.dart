import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../widgets/shared/nav_bottom.dart';

class UserEventsView extends StatefulWidget {
  const UserEventsView({super.key});

  @override
  State<UserEventsView> createState() => _UserEventsViewState();
}

class _UserEventsViewState extends State<UserEventsView> {
  late Future<List<Map<String, dynamic>>> _futureEdicoes;

  @override
  void initState() {
    super.initState();
    _futureEdicoes = _loadEdicoesComEventos();
  }

  Future<List<Map<String, dynamic>>> _loadEdicoesComEventos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Future.error('not_logged_in');

    final userEventsSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('events')
            .get();

    final Set<String> inscritos =
        userEventsSnapshot.docs
            .where((doc) => doc.data()['ativo'] == true)
            .map((doc) => doc.data()['eventoId'] as String)
            .toSet();

    final edicoesSnapshot =
        await FirebaseFirestore.instance.collection('editions').get();

    List<Map<String, dynamic>> edicoes = [];

    for (final ed in edicoesSnapshot.docs) {
      final edId = ed.id;
      final eventosSnapshot =
          await FirebaseFirestore.instance
              .collection('editions')
              .doc(edId)
              .collection('events')
              .get();

      final eventos =
          eventosSnapshot.docs.map((e) {
            final data = e.data();
            return {
              'id': e.id,
              'inscrito': inscritos.contains('editions/$edId/events/${e.id}'),
              ...data,
            };
          }).toList();

      edicoes.add({
        'id': edId,
        'nome': ed.data()['nome'] ?? edId,
        'eventos': eventos,
      });
    }

    return edicoes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos'), centerTitle: true),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index != 1) {
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureEdicoes,
        builder: (ctx, snapshot) {
          if (snapshot.hasError && snapshot.error == 'not_logged_in') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/login');
            });
            return const SizedBox.shrink();
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma edição encontrada.'));
          }
          final edicoes = snapshot.data!;
          return ListView.builder(
            itemCount: edicoes.length,
            itemBuilder: (ctx, i) {
              final ed = edicoes[i];
              final eventos = ed['eventos'] as List<Map<String, dynamic>>;
              return ExpansionTile(
                leading: const Icon(Icons.event_note),
                backgroundColor: Colors.grey.shade100,
                title: Text(ed['nome'] ?? ed['id']),
                children:
                    eventos.map((evento) {
                      final data = (evento['data'] as Timestamp).toDate();
                      final isPast = data.isBefore(DateTime.now());
                      return ListTile(
                        onTap: () {
                          Navigator.of(context).pushNamed('/event-details', arguments: evento);
                        },
                        title: Text(evento['nome'] ?? 'Evento'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('dd/MM/yyyy HH:mm').format(data)),
                            if (evento['local'] != null)
                              Text('Local: ${evento['local']}'),
                            if (evento['entidade'] != null)
                              Text('Organizador: ${evento['entidade']}'),
                          ],
                        ),
                        trailing: Icon(
                          evento['inscrito'] == true
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color:
                              evento['inscrito'] == true
                                  ? Colors.green
                                  : Colors.grey,
                        ),
                        tileColor: isPast ? Colors.grey.shade100 : null,
                      );
                    }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
