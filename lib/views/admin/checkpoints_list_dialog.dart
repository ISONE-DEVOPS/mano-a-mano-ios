import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckpointsListDialog extends StatelessWidget {
  final String edicaoId;
  final String eventId;

  const CheckpointsListDialog({super.key, required this.edicaoId, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 600,
          height: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Checkpoints do Evento',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Divider(),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('editions')
                          .doc(edicaoId)
                          .collection('events')
                          .doc(eventId)
                          .collection('checkpoints')
                          .orderBy('ordem')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Text('Nenhum checkpoint encontrado.');
                    }
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        try {
                          final data = docs[index].data()! as Map<String, dynamic>;
                          final localizacao = data['localizacao'];
                          final coordenadas = localizacao is GeoPoint
                              ? '${localizacao.latitude.toStringAsFixed(5)}, ${localizacao.longitude.toStringAsFixed(5)}'
                              : 'não definida';
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(
                                '${data['nome']} (${data['codigo'] ?? data['ordem'] ?? ''})',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                'Origem: ${data['origem']} • Localização: $coordenadas',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blueGrey,
                                    ),
                                    tooltip: 'Editar',
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Funcionalidade de edição em desenvolvimento.',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Eliminar',
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text(
                                            'Eliminar Checkpoint',
                                          ),
                                          content: const Text(
                                            'Tem certeza que deseja eliminar este checkpoint?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Cancelar'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Eliminar'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        await FirebaseFirestore.instance
                                            .collection('editions')
                                            .doc(edicaoId)
                                            .collection('events')
                                            .doc(eventId)
                                            .collection('checkpoints')
                                            .doc(docs[index].id)
                                            .delete();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        } catch (e) {
                          return Text(
                            'Erro ao carregar checkpoint: $e',
                            style: const TextStyle(color: Colors.red),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
