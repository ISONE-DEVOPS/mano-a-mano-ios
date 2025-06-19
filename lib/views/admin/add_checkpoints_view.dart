import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  final _percursoController = TextEditingController();
  final _tempoMinimoController = TextEditingController();
  final _pergunta1IdController = TextEditingController();
  final _jogoIdController = TextEditingController();

  bool _finalJogos = false;

  final bool _usarGeo = false;

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
    if (_nomeController.text.isNotEmpty) {
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
          'name': _nomeController.text.trim(),
          'descricao': _descricaoController.text.trim(),
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
          'tempoMinimo': int.tryParse(_tempoMinimoController.text.trim()) ?? 1,
          'pergunta1Id': _pergunta1IdController.text.trim(),
          'jogoId': _jogoIdController.text.trim(),
          'finalComJogosFinais': _finalJogos,
        });
        _nomeController.clear();
        _descricaoController.clear();
        _latController.clear();
        _lngController.clear();
        _percursoController.clear();
        _tempoMinimoController.clear();
        _pergunta1IdController.clear();
        _jogoIdController.clear();
        _finalJogos = false;
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
        'descricao': item['descricao'],
        'ordem': item['codigo'],
        'localizacao': GeoPoint(item['lat'], item['lng']),
        'tempoMinimo': item['tempoMinimo'] ?? 1,
        'pergunta1Ref': FirebaseFirestore.instance
            .collection('perguntas')
            .doc(item['pergunta1Id']),
        'jogoRef': FirebaseFirestore.instance
            .collection('jogos')
            .doc(item['jogoId']),
        'finalComJogosFinais': item['finalComJogosFinais'] ?? false,
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
    }
  }

  Widget buildDropdownFields() {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('perguntas').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final perguntas = snapshot.data!.docs;
              return DropdownButtonFormField<String>(
                value:
                    _pergunta1IdController.text.isEmpty
                        ? null
                        : _pergunta1IdController.text,
                onChanged:
                    (value) => setState(
                      () => _pergunta1IdController.text = value ?? '',
                    ),
                items:
                    perguntas.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final texto = data['pergunta'] ?? '---';
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(
                          texto.length > 40
                              ? '${texto.substring(0, 40)}...'
                              : texto,
                        ),
                      );
                    }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Selecionar Pergunta',
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        const SizedBox(width: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('jogos').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final jogos = snapshot.data!.docs;
              return DropdownButtonFormField<String>(
                value:
                    _jogoIdController.text.isEmpty
                        ? null
                        : _jogoIdController.text,
                onChanged:
                    (value) =>
                        setState(() => _jogoIdController.text = value ?? ''),
                items:
                    jogos.map((doc) {
                      final nome = doc['nome'] ?? 'Sem nome';
                      return DropdownMenuItem(value: doc.id, child: Text(nome));
                    }).toList(),
                decoration: const InputDecoration(labelText: 'Selecionar Jogo'),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkpoints')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _latController,
                    decoration: const InputDecoration(labelText: 'Latitude'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lngController,
                    decoration: const InputDecoration(labelText: 'Longitude'),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tempoMinimoController,
                    decoration: const InputDecoration(
                      labelText: 'Tempo Mínimo',
                    ),
                  ),
                  const SizedBox(height: 12),
                  buildDropdownFields(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _finalJogos,
                        onChanged: (value) {
                          setState(() {
                            _finalJogos = value ?? false;
                          });
                        },
                      ),
                      const Text('Final com Jogos Finais'),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _addCheckpoint,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Checkpoint'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveCheckpoints,
              icon: const Icon(Icons.save),
              label: const Text('Salvar Todos'),
            ),
          ],
        ),
      ),
    );
  }
}
