import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';

class AddCheckpointsView extends StatefulWidget {
  final String eventId;
  const AddCheckpointsView({super.key, required this.eventId});

  @override
  State<AddCheckpointsView> createState() => _AddCheckpointsViewState();
}

class _AddCheckpointsViewState extends State<AddCheckpointsView> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _checkpoints = [];
  final _postoController = TextEditingController();
  final _nomeController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _usarGeo = false;

  void _addCheckpoint() {
    if (_postoController.text.isNotEmpty && _nomeController.text.isNotEmpty) {
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
          'lat': double.tryParse(_latController.text.trim()) ?? 0.0,
          'lng': double.tryParse(_lngController.text.trim()) ?? 0.0,
          'origem': _usarGeo ? 'geolocalizacao' : 'manual',
        });
        _postoController.clear();
        _nomeController.clear();
        _latController.clear();
        _lngController.clear();
      });
    }
  }

  Future<void> _saveCheckpoints() async {
    if (_checkpoints.isEmpty) return;

    _checkpoints.sort(
      (a, b) => (a['codigo'] as int).compareTo(b['codigo'] as int),
    );

    final ref = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId);
    final Map<String, dynamic> checkpointsMap = {
      for (var item in _checkpoints)
        item['posto']: {
          'name': item['name'],
          'codigo': item['codigo'],
          'lat': item['lat'],
          'lng': item['lng'],
          'origem': item['origem'],
        },
    };

    final List<Map<String, dynamic>> percursoList = [
      for (var item in _checkpoints)
        {'posto': item['posto'], 'lat': item['lat'], 'lng': item['lng']},
    ];

    await ref.update({
      'checkpoints_totais': _checkpoints.length,
      'checkpoints': checkpointsMap,
      'percurso': percursoList,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checkpoints salvos com sucesso.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Adicionar Checkpoints'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Inserir coordenadas:'),
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
                    final position = await Geolocator.getCurrentPosition();
                    _latController.text = position.latitude.toString();
                    _lngController.text = position.longitude.toString();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Checkpoint',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!_usarGeo) ...[
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                  IconButton(
                    onPressed: _addCheckpoint,
                    icon: const Icon(Icons.add_circle, color: AppColors.secondaryDark),
                    tooltip: 'Adicionar',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _checkpoints.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, index) {
                  final item = _checkpoints[index];
                  return ListTile(
                    title: Text(
                      'P${item['codigo']} - ${item['name']} (${item['origem'] == 'geolocalizacao' ? 'Geo' : 'Manual'})',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.secondaryDark),
                          onPressed: () {
                            final item = _checkpoints[index];
                            setState(() {
                              _postoController.text = item['posto'];
                              _nomeController.text = item['name'];
                              _latController.text = item['lat'].toString();
                              _lngController.text = item['lng'].toString();
                              _usarGeo = item['origem'] == 'geolocalizacao';
                              _checkpoints.removeAt(index);
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.primaryDark),
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryDark,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.save),
              label: const Text('Salvar Checkpoints'),
              onPressed: _saveCheckpoints,
            ),
          ],
        ),
      ),
    );
  }
}
