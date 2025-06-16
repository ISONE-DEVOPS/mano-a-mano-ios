import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';
import 'package:get/get.dart';

class AddCheckpointsView extends StatefulWidget {
  const AddCheckpointsView({super.key});

  @override
  State<AddCheckpointsView> createState() => _AddCheckpointsViewState();
}

class _AddCheckpointsViewState extends State<AddCheckpointsView> {
  late String edicaoId;
  late String eventId;

  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _checkpoints = [];
  final _postoController = TextEditingController();
  final _nomeController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  final _percursoController = TextEditingController();
  final _tempoMinimoController = TextEditingController();
  final _pergunta1IdController = TextEditingController();
  final _pergunta2IdController = TextEditingController();
  final _jogoIdController = TextEditingController();

  bool _usarGeo = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args == null ||
        args is! Map ||
        !args.containsKey('edicaoId') ||
        !args.containsKey('eventId')) {
      Future.microtask(() {
        if (!mounted) return;
        Get.snackbar(
          'Erro',
          'Argumentos inválidos ou ausentes para AddCheckpointsView',
        );
        Navigator.pop(context);
      });
      return;
    }
    edicaoId = args['edicaoId'];
    eventId = args['eventId'];
  }

  void _addCheckpoint() {
    if (!_formKey.currentState!.validate()) return;
    if (_postoController.text.isNotEmpty && _nomeController.text.isNotEmpty) {
      final lat = double.tryParse(_latController.text.trim());
      final lng = double.tryParse(_lngController.text.trim());
      if (!_usarGeo && (lat == null || lng == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Latitude ou Longitude inválida')),
        );
        return;
      }
      setState(() {
        _checkpoints.add({
          'posto': _postoController.text.trim(),
          'name': _nomeController.text.trim(),
          'codigo':
              (_checkpoints.isNotEmpty
                  ? _checkpoints
                      .map((e) => e['codigo'] as int)
                      .reduce((a, b) => a > b ? a : b)
                  : 0) +
              1,
          'lat': lat ?? 0.0,
          'lng': lng ?? 0.0,
          'origem': _usarGeo ? 'geolocalizacao' : 'manual',
          'percurso': _percursoController.text.trim(),
          'tempoMinimo': int.tryParse(_tempoMinimoController.text.trim()) ?? 1,
          'pergunta1Id': _pergunta1IdController.text.trim(),
          'pergunta2Id': _pergunta2IdController.text.trim(),
          'jogoId': _jogoIdController.text.trim(),
        });
        _postoController.clear();
        _nomeController.clear();
        _latController.clear();
        _lngController.clear();
        _percursoController.clear();
        _tempoMinimoController.clear();
        _pergunta1IdController.clear();
        _pergunta2IdController.clear();
        _jogoIdController.clear();
      });
    }
  }

  Future<void> _saveCheckpoints() async {
    if (_checkpoints.isEmpty) return;

    _checkpoints.sort(
      (a, b) => (a['codigo'] as int).compareTo(b['codigo'] as int),
    );

    final ref = FirebaseFirestore.instance
        .collection('editions')
        .doc(edicaoId)
        .collection('events')
        .doc(eventId)
        .collection('checkpoints');

    final batch = FirebaseFirestore.instance.batch();
    for (var item in _checkpoints) {
      final docRef = ref.doc();
      batch.set(docRef, {
        'nome': item['name'],
        'ordem': item['codigo'],
        'localizacao': GeoPoint(item['lat'], item['lng']),
        'origem': item['origem'],
        'codigo': item['posto'],
        'percurso': item['percurso'] ?? '',
        'pergunta1Ref': FirebaseFirestore.instance
            .collection('perguntas')
            .doc(item['pergunta1Id']),
        'pergunta2Ref': FirebaseFirestore.instance
            .collection('perguntas')
            .doc(item['pergunta2Id']),
        'tempoMinimo': item['tempoMinimo'] ?? 1,
        'jogoId': item['jogoId'] ?? '',
      });
    }
    try {
      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_checkpoints.length} checkpoint(s) salvo(s) com sucesso.',
          ),
        ),
      );
      setState(() => _checkpoints.clear());
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar checkpoints: $e')));
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: AppColors.background,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Adicionar Checkpoints',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                ..._buildCheckpointForm(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCheckpointForm(BuildContext context) {
    return [
      Row(
        children: [
          const Text(
            'Inserir coordenadas:',
            style: TextStyle(color: Colors.black),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Manual'),
            selected: !_usarGeo,
            onSelected: (v) => setState(() => _usarGeo = false),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Geolocalização'),
            selected: _usarGeo,
            onSelected: (v) async {
              setState(() => _usarGeo = true);
              final location = Location();
              final hasPermission = await location.hasPermission();
              if (hasPermission == PermissionStatus.denied) {
                await location.requestPermission();
              }
              final currentLocation = await location.getLocation();
              _latController.text = currentLocation.latitude?.toString() ?? '';
              _lngController.text = currentLocation.longitude?.toString() ?? '';
            },
          ),
        ],
      ),
      const SizedBox(height: 12),
      Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _postoController,
                    decoration: const InputDecoration(
                      labelText: 'Código do Posto (Ex: cidadeela)',
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Campo obrigatório'
                                : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Checkpoint',
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Campo obrigatório'
                                : null,
                  ),
                ),
                const SizedBox(width: 8),
                if (!_usarGeo) ...[
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (!_usarGeo && (value == null || value.isEmpty)) {
                          return 'Campo obrigatório';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (!_usarGeo && (value == null || value.isEmpty)) {
                          return 'Campo obrigatório';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
                IconButton(
                  onPressed: _addCheckpoint,
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppColors.secondaryDark,
                  ),
                  tooltip: 'Adicionar',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _percursoController,
                    decoration: const InputDecoration(
                      labelText: 'Percurso (A ou B)',
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _tempoMinimoController,
                    decoration: const InputDecoration(
                      labelText: 'Tempo Mínimo',
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.black),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final n = int.tryParse(value);
                        if (n == null || n < 0) {
                          return 'Valor inválido';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pergunta1IdController,
                    decoration: const InputDecoration(
                      labelText: 'Pergunta 1 ID',
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _pergunta2IdController,
                    decoration: const InputDecoration(
                      labelText: 'Pergunta 2 ID',
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _jogoIdController,
                    decoration: const InputDecoration(
                      labelText: 'Jogo ID',
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 300,
        child: ListView.separated(
          itemCount: _checkpoints.length,
          separatorBuilder: (context, _) => const Divider(),
          itemBuilder: (_, index) {
            final item = _checkpoints[index];
            return ListTile(
              title: Text(
                'P${item['codigo']} - ${item['name']}',
                style: const TextStyle(color: Colors.black),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(
                    label: Text(
                      item['origem'] == 'geolocalizacao' ? 'Geo' : 'Manual',
                    ),
                    backgroundColor:
                        item['origem'] == 'geolocalizacao'
                            ? AppColors.secondary.withAlpha((255 * 0.2).round())
                            : AppColors.primary.withAlpha((255 * 0.2).round()),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: AppColors.secondaryDark,
                    ),
                    onPressed: () {
                      final item = _checkpoints[index];
                      setState(() {
                        _postoController.text = item['posto'];
                        _nomeController.text = item['name'];
                        _latController.text = item['lat'].toString();
                        _lngController.text = item['lng'].toString();
                        _usarGeo = item['origem'] == 'geolocalizacao';
                        _percursoController.text = item['percurso'] ?? '';
                        _tempoMinimoController.text =
                            (item['tempoMinimo'] ?? '').toString();
                        _pergunta1IdController.text = item['pergunta1Id'] ?? '';
                        _pergunta2IdController.text = item['pergunta2Id'] ?? '';
                        _jogoIdController.text = item['jogoId'] ?? '';
                        _checkpoints.removeAt(index);
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: AppColors.primaryDark,
                    ),
                    onPressed: () {
                      final removido = _checkpoints[index];
                      setState(() => _checkpoints.removeAt(index));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Checkpoint "${removido['posto']}" removido.',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryDark,
          foregroundColor: Colors.black,
        ),
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text(
          'Salvar Checkpoints',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: _saveCheckpoints,
      ),
      const SizedBox(height: 24),
      const Text(
        'Checkpoints já gravados',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 300,
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
              return const Center(
                child: Text(
                  'Nenhum checkpoint inserido ainda.',
                  style: TextStyle(color: Colors.black),
                ),
              );
            }
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final data = docs[index].data()! as Map<String, dynamic>;
                String pergunta1Id = '';
                String pergunta2Id = '';
                if (data['pergunta1Ref'] != null) {
                  try {
                    pergunta1Id =
                        (data['pergunta1Ref'] as DocumentReference).id;
                  } catch (_) {}
                } else if (data['pergunta1Id'] != null) {
                  pergunta1Id = data['pergunta1Id'];
                }
                if (data['pergunta2Ref'] != null) {
                  try {
                    pergunta2Id =
                        (data['pergunta2Ref'] as DocumentReference).id;
                  } catch (_) {}
                } else if (data['pergunta2Id'] != null) {
                  pergunta2Id = data['pergunta2Id'];
                }
                return ListTile(
                  title: Text(
                    '${data['nome']} (${data['codigo'] ?? data['ordem'] ?? ''})',
                    style: const TextStyle(color: Colors.black),
                  ),
                  subtitle: Text(
                    'Origem: ${data['origem']}'
                    ' | Percurso: ${data['percurso'] ?? ''}'
                    ' | Tempo Mínimo: ${data['tempoMinimo'] ?? ''}'
                    ' | Pergunta1Id: $pergunta1Id'
                    ' | Pergunta2Id: $pergunta2Id'
                    ' | JogoId: ${data['jogoId'] ?? ''}',
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              },
            );
          },
        ),
      ),
    ];
  }
}
