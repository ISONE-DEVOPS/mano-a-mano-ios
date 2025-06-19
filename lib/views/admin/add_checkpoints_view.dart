import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AddCheckpointsView extends StatefulWidget {
  const AddCheckpointsView({super.key});

  @override
  State<AddCheckpointsView> createState() => _AddCheckpointsViewState();
}

class _AddCheckpointsViewState extends State<AddCheckpointsView> {
  int _ordemA = 0;
  int _ordemB = 0;
  String _percurso = 'ambos';
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

  List<String> _jogosSelecionados = [];

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
    if (_finalJogos && _jogosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione ao menos 1 jogo para o checkpoint final.'),
        ),
      );
      return;
    }
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
          'jogosIds': _finalJogos ? List.from(_jogosSelecionados) : [],
          'ordemA': _ordemA,
          'ordemB': _ordemB,
          'percurso': _percurso,
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
        _jogosSelecionados.clear();
        _ordemA = 0;
        _ordemB = 0;
        _percurso = 'ambos';
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
        'jogoRef':
            item['finalComJogosFinais'] == true
                ? null
                : FirebaseFirestore.instance
                    .collection('jogos')
                    .doc(item['jogoId']),
        'finalComJogosFinais': item['finalComJogosFinais'] ?? false,
        'jogosRefs':
            item['finalComJogosFinais'] == true
                ? (item['jogosIds'] as List<String>)
                    .map(
                      (id) => FirebaseFirestore.instance
                          .collection('jogos')
                          .doc(id),
                    )
                    .toList()
                : [],
        'ordemA': item['ordemA'] ?? 0,
        'ordemB': item['ordemB'] ?? 0,
        'percurso': item['percurso'] ?? 'ambos',
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
      setState(() {
        _checkpoints.clear();
        _ordemA = 0;
        _ordemB = 0;
        _percurso = 'ambos';
      });
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
              if (_finalJogos) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      jogos.map((doc) {
                        final nome = doc['nome'] ?? 'Sem nome';
                        final id = doc.id;
                        return CheckboxListTile(
                          title: Text(nome),
                          value: _jogosSelecionados.contains(id),
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _jogosSelecionados.add(id);
                              } else {
                                _jogosSelecionados.remove(id);
                              }
                            });
                          },
                        );
                      }).toList(),
                );
              } else {
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
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(nome),
                        );
                      }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Selecionar Jogo',
                  ),
                );
              }
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe a descrição';
                      }
                      return null;
                    },
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
                    validator: (value) {
                      if (value == null || int.tryParse(value.trim()) == null) {
                        return 'Informe um tempo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Ordem A'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _ordemA = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Ordem B'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _ordemB = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _percurso,
                    onChanged: (value) {
                      setState(() {
                        _percurso = value ?? 'ambos';
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Percurso'),
                    items: const [
                      DropdownMenuItem(value: 'A', child: Text('A')),
                      DropdownMenuItem(value: 'B', child: Text('B')),
                      DropdownMenuItem(value: 'ambos', child: Text('Ambos')),
                    ],
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
            if (_checkpoints.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _checkpoints.length,
                itemBuilder: (context, index) {
                  final checkpoint = _checkpoints[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${checkpoint['codigo']}. ${checkpoint['name']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(checkpoint['descricao'] ?? ''),
                          const SizedBox(height: 8),
                          FutureBuilder<List<DocumentSnapshot>>(
                            future: Future.wait(
                              (checkpoint['jogosRefs'] as List<dynamic>? ?? [])
                                  .map(
                                    (ref) => (ref as DocumentReference).get(),
                                  ),
                            ),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Text('Carregando jogos...');
                              }
                              final jogos = snapshot.data!;
                              if (jogos.isEmpty) return const SizedBox();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Jogos Associados:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...jogos.map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    return Text(
                                      '- ${data['nome']} (${data['tipo']})',
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _nomeController.text = checkpoint['name'];
                                    _descricaoController.text =
                                        checkpoint['descricao'];
                                    _latController.text =
                                        checkpoint['lat'].toString();
                                    _lngController.text =
                                        checkpoint['lng'].toString();
                                    _tempoMinimoController.text =
                                        checkpoint['tempoMinimo'].toString();
                                    _pergunta1IdController.text =
                                        checkpoint['pergunta1Id'];
                                    _jogoIdController.text =
                                        checkpoint['jogoId'];
                                    _finalJogos =
                                        checkpoint['finalComJogosFinais'] ??
                                        false;
                                    _jogosSelecionados = List<String>.from(
                                      checkpoint['jogosIds'] ?? [],
                                    );
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _checkpoints.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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
