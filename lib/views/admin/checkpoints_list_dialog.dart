import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckpointsListDialog extends StatelessWidget {
  final String edicaoId;
  final String eventId;

  const CheckpointsListDialog({
    super.key,
    required this.edicaoId,
    required this.eventId,
  });

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
                      return const Text(
                        'Nenhum checkpoint encontrado.',
                        style: TextStyle(color: Colors.black),
                      );
                    }
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        try {
                          final data =
                              docs[index].data()! as Map<String, dynamic>;
                          final localizacao = data['localizacao'];
                          GeoPoint? ponto;
                          String coordenadas = 'não definida';
                          String? mapsUrl;
                          if (localizacao is GeoPoint) {
                            ponto = localizacao;
                            coordenadas =
                                '${ponto.latitude.toStringAsFixed(5)}, ${ponto.longitude.toStringAsFixed(5)}';
                            mapsUrl =
                                'https://www.google.com/maps/search/?api=1&query=${ponto.latitude},${ponto.longitude}';
                          }
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: ListTile(
                                title: Text(
                                  '${data['nome']} (${data['codigo'] ?? data['ordem'] ?? ''})',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Descrição: ${data['descricao'] ?? '-'} • Tempo Mínimo: ${data['tempoMinimo']} min',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Localização: $coordenadas',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (data['pergunta1Ref'] != null)
                                      FutureBuilder<DocumentSnapshot>(
                                        future:
                                            (data['pergunta1Ref']
                                                    as DocumentReference)
                                                .get(),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const SizedBox();
                                          }
                                          final texto =
                                              snapshot.data!.get('texto') ??
                                              '---';
                                          return Text(
                                            'Pergunta: $texto',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (mapsUrl != null)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.map,
                                          color: Colors.green,
                                        ),
                                        tooltip: 'Abrir no Google Maps',
                                        onPressed:
                                            () =>
                                                launchUrl(Uri.parse(mapsUrl!)),
                                      ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blueGrey,
                                      ),
                                      tooltip: 'Editar',
                                      onPressed: () async {
                                        final formKey = GlobalKey<FormState>();
                                        // Preenche os campos iniciais com os valores atuais
                                        String nome = data['nome'] ?? '';
                                        String codigo = data['codigo'] ?? '';
                                        // 'origem' removido ou opcional
                                        // String origem = data['origem'] ?? '';
                                        GeoPoint? localizacaoGeo =
                                            data['localizacao'] is GeoPoint
                                                ? data['localizacao']
                                                : null;
                                        String latitude =
                                            localizacaoGeo != null
                                                ? localizacaoGeo.latitude
                                                    .toString()
                                                : '';
                                        String longitude =
                                            localizacaoGeo != null
                                                ? localizacaoGeo.longitude
                                                    .toString()
                                                : '';
                                        await showDialog(
                                          context: context,
                                          builder: (ctx) {
                                            return AlertDialog(
                                              title: const Text(
                                                'Editar Checkpoint',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                              content: Form(
                                                key: formKey,
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      TextFormField(
                                                        initialValue: nome,
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                        decoration:
                                                            const InputDecoration(
                                                              labelText: 'Nome',
                                                              labelStyle:
                                                                  TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .black,
                                                                  ),
                                                            ),
                                                        validator:
                                                            (value) =>
                                                                value == null ||
                                                                        value
                                                                            .isEmpty
                                                                    ? 'Informe o nome'
                                                                    : null,
                                                        onChanged:
                                                            (value) =>
                                                                nome = value,
                                                      ),
                                                      TextFormField(
                                                        initialValue: codigo,
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                        decoration:
                                                            const InputDecoration(
                                                              labelText:
                                                                  'Código',
                                                              labelStyle:
                                                                  TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .black,
                                                                  ),
                                                            ),
                                                        onChanged:
                                                            (value) =>
                                                                codigo = value,
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: TextFormField(
                                                              initialValue:
                                                                  latitude,
                                                              style: const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .black,
                                                              ),
                                                              decoration: const InputDecoration(
                                                                labelText:
                                                                    'Latitude',
                                                                labelStyle:
                                                                    TextStyle(
                                                                      color:
                                                                          Colors
                                                                              .black,
                                                                    ),
                                                              ),
                                                              keyboardType:
                                                                  const TextInputType.numberWithOptions(
                                                                    decimal:
                                                                        true,
                                                                  ),
                                                              onChanged:
                                                                  (value) =>
                                                                      latitude =
                                                                          value,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Expanded(
                                                            child: TextFormField(
                                                              initialValue:
                                                                  longitude,
                                                              style: const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .black,
                                                              ),
                                                              decoration: const InputDecoration(
                                                                labelText:
                                                                    'Longitude',
                                                                labelStyle:
                                                                    TextStyle(
                                                                      color:
                                                                          Colors
                                                                              .black,
                                                                    ),
                                                              ),
                                                              keyboardType:
                                                                  const TextInputType.numberWithOptions(
                                                                    decimal:
                                                                        true,
                                                                  ),
                                                              onChanged:
                                                                  (value) =>
                                                                      longitude =
                                                                          value,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () =>
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop(),
                                                  child: const Text(
                                                    'Cancelar',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    if (formKey.currentState!
                                                        .validate()) {
                                                      try {
                                                        Map<String, dynamic>
                                                        updateData = {
                                                          'nome': nome,
                                                          'codigo': codigo,
                                                          // 'origem': origem, // removido ou opcional
                                                        };
                                                        if (latitude
                                                                .isNotEmpty &&
                                                            longitude
                                                                .isNotEmpty) {
                                                          final lat =
                                                              double.tryParse(
                                                                latitude,
                                                              );
                                                          final lng =
                                                              double.tryParse(
                                                                longitude,
                                                              );
                                                          if (lat != null &&
                                                              lng != null) {
                                                            updateData['localizacao'] =
                                                                GeoPoint(
                                                                  lat,
                                                                  lng,
                                                                );
                                                          }
                                                        }
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                              'editions',
                                                            )
                                                            .doc(edicaoId)
                                                            .collection(
                                                              'events',
                                                            )
                                                            .doc(eventId)
                                                            .collection(
                                                              'checkpoints',
                                                            )
                                                            .doc(docs[index].id)
                                                            .update(updateData);
                                                        if (!context.mounted) {
                                                          return;
                                                        }
                                                        Navigator.of(ctx).pop();
                                                      } catch (e) {
                                                        if (!context.mounted) {
                                                          return;
                                                        }
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'Erro ao atualizar: $e',
                                                              style: const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .black,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  child: const Text(
                                                    'Salvar',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
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
                                        final confirmed = await showDialog<
                                          bool
                                        >(
                                          context: context,
                                          builder:
                                              (ctx) => AlertDialog(
                                                title: const Text(
                                                  'Eliminar Checkpoint',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                content: const Text(
                                                  'Tem certeza que deseja eliminar este checkpoint?',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          ctx,
                                                          false,
                                                        ),
                                                    child: const Text(
                                                      'Cancelar',
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          ctx,
                                                          true,
                                                        ),
                                                    child: const Text(
                                                      'Eliminar',
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                      ),
                                                    ),
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
                  child: const Text(
                    'Fechar',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
