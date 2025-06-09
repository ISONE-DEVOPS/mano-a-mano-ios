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
    if (!_formKey.currentState!.validate()) return;
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
        .doc(widget.eventId)
        .collection('checkpoints');

    final batch = FirebaseFirestore.instance.batch();
    for (var item in _checkpoints) {
      final docRef = ref.doc(item['posto']);
      batch.set(docRef, {
        'nome': item['name'],
        'descricao': '',
        'ordem': item['codigo'],
        'localizacao': GeoPoint(item['lat'], item['lng']),
        'origem': item['origem'],
      });
    }
    await batch.commit();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checkpoints salvos com sucesso.')),
    );
    Navigator.pop(context);
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
              title: Row(
                children: [
                  Expanded(child: Text('P${item['codigo']} - ${item['name']}')),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      item['origem'] == 'geolocalizacao' ? 'Geo' : 'Manual',
                    ),
                    backgroundColor:
                        item['origem'] == 'geolocalizacao'
                            ? AppColors.secondary.withAlpha((255 * 0.2).round())
                            : AppColors.primary.withAlpha((255 * 0.2).round()),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
    ];
  }
}
