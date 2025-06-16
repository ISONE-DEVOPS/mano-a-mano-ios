import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventDetailsView extends StatelessWidget {
  const EventDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final evento =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (evento == null) {
      return const Scaffold(
        body: Center(child: Text('Evento não encontrado.')),
      );
    }

    final data = (evento['data'] as Timestamp?)?.toDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Evento'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              evento['nome'] ?? 'Evento',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (data != null)
              Text('Data: ${DateFormat('dd/MM/yyyy HH:mm').format(data)}'),
            if (evento['local'] != null) Text('Local: ${evento['local']}'),
            if (evento['entidade'] != null)
              Text('Organizador: ${evento['entidade']}'),
            if (evento['descricao'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  evento['descricao'],
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
