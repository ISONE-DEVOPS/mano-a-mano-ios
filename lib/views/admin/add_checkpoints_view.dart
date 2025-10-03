import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:mano_mano_dashboard/widgets/shared/admin_page_wrapper.dart';

class AddCheckpointsView extends StatefulWidget {
  const AddCheckpointsView({super.key});

  @override
  State<AddCheckpointsView> createState() => _AddCheckpointsViewState();
}

class _AddCheckpointsViewState extends State<AddCheckpointsView>
    with SingleTickerProviderStateMixin {
  // Controllers
  late TabController _tabController;
  late String edicaoId;
  late String eventId;

  // Form Keys
  final _formKey = GlobalKey<FormState>();

  // Data
  final List<Map<String, dynamic>> _checkpoints = [];

  // Text Controllers
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _tempoMinimoController = TextEditingController();
  final _pergunta1IdController = TextEditingController();
  final _jogoIdController = TextEditingController();

  // States
  int _ordemA = 1;
  int _ordemB = 1;
  String _percurso = 'ambos';
  bool _finalJogos = false;
  bool _isLoading = false;
  bool _usarLocalizacaoManual = true;
  List<String> _jogosSelecionados = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final args = Get.arguments;
    if (args == null ||
        args is! Map ||
        !args.containsKey('edicaoId') ||
        !args.containsKey('eventId')) {
      Future.microtask(() {
        if (!mounted) return;
        Get.snackbar(
          'Erro',
          'Argumentos inválidos ou ausentes',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Navigator.pop(context);
      });
      return;
    }
    edicaoId = args['edicaoId'];
    eventId = args['eventId'];

    // Set default values
    _tempoMinimoController.text = '5';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomeController.dispose();
    _descricaoController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _tempoMinimoController.dispose();
    _pergunta1IdController.dispose();
    _jogoIdController.dispose();
    super.dispose();
  }

  void _addCheckpoint() {
    if (!_formKey.currentState!.validate()) return;

    if (_finalJogos && _jogosSelecionados.isEmpty) {
      _showSnackBar(
        'Selecione ao menos 1 jogo para o checkpoint final',
        isError: true,
      );
      return;
    }

    if (_pergunta1IdController.text.isEmpty) {
      _showSnackBar('Selecione uma pergunta para o checkpoint', isError: true);
      return;
    }

    if (!_finalJogos && _jogoIdController.text.isEmpty) {
      _showSnackBar('Selecione um jogo para o checkpoint', isError: true);
      return;
    }

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (_usarLocalizacaoManual && (lat == null || lng == null)) {
      _showSnackBar('Coordenadas inválidas', isError: true);
      return;
    }

    setState(() {
      final newCheckpoint = {
        'name': _nomeController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'codigo': _checkpoints.length + 1,
        'lat': lat ?? 0.0,
        'lng': lng ?? 0.0,
        'origem': _usarLocalizacaoManual ? 'manual' : 'geolocalizacao',
        'tempoMinimo': int.tryParse(_tempoMinimoController.text.trim()) ?? 5,
        'pergunta1Id': _pergunta1IdController.text.trim(),
        'jogoId': _finalJogos ? null : _jogoIdController.text.trim(),
        'finalComJogosFinais': _finalJogos,
        'jogosIds': _finalJogos ? List<String>.from(_jogosSelecionados) : [],
        'ordemA': _ordemA,
        'ordemB': _ordemB,
        'percurso': _percurso,
      };

      _checkpoints.add(newCheckpoint);
      _resetForm();
      _showSnackBar('Checkpoint adicionado à lista');

      // Switch to list tab
      _tabController.animateTo(1);
    });
  }

  void _resetForm() {
    _nomeController.clear();
    _descricaoController.clear();
    _latController.clear();
    _lngController.clear();
    _tempoMinimoController.text = '5';
    _pergunta1IdController.clear();
    _jogoIdController.clear();
    _finalJogos = false;
    _jogosSelecionados.clear();
    _ordemA = 1;
    _ordemB = 1;
    _percurso = 'ambos';
  }

  void _editCheckpoint(int index) {
    final checkpoint = _checkpoints[index];
    setState(() {
      _nomeController.text = checkpoint['name'];
      _descricaoController.text = checkpoint['descricao'];
      _latController.text = checkpoint['lat'].toString();
      _lngController.text = checkpoint['lng'].toString();
      _tempoMinimoController.text = checkpoint['tempoMinimo'].toString();
      _pergunta1IdController.text = checkpoint['pergunta1Id'];
      _jogoIdController.text = checkpoint['jogoId'] ?? '';
      _finalJogos = checkpoint['finalComJogosFinais'] ?? false;
      _jogosSelecionados = List<String>.from(checkpoint['jogosIds'] ?? []);
      _ordemA = checkpoint['ordemA'] ?? 1;
      _ordemB = checkpoint['ordemB'] ?? 1;
      _percurso = checkpoint['percurso'] ?? 'ambos';

      // Remove from list
      _checkpoints.removeAt(index);

      // Switch to form tab
      _tabController.animateTo(0);
    });
  }

  void _deleteCheckpoint(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: Text(
              'Deseja realmente excluir o checkpoint "${_checkpoints[index]['name']}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _checkpoints.removeAt(index);
                  });
                  Navigator.pop(context);
                  _showSnackBar('Checkpoint removido');
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveCheckpoints() async {
    if (_checkpoints.isEmpty) {
      _showSnackBar('Adicione pelo menos um checkpoint', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
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
          'tempoMinimo': item['tempoMinimo'] ?? 5,
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
          'ordemA': item['ordemA'] ?? 1,
          'ordemB': item['ordemB'] ?? 1,
          'percurso': item['percurso'] ?? 'ambos',
        });
      }

      await batch.commit();

      _showSnackBar(
        '${_checkpoints.length} checkpoint(s) salvos com sucesso!',
        isSuccess: true,
      );

      // Clear and go back
      setState(() {
        _checkpoints.clear();
        _resetForm();
      });

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Erro ao salvar: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error
                  : isSuccess
                  ? Icons.check_circle
                  : Icons.info,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError
                ? Colors.red
                : isSuccess
                ? Colors.green
                : Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageWrapper(
      title: 'Adicionar Checkpoints',
      child: Column(
        children: [
          // Tab Bar
          Container(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  icon: const Icon(Icons.add_location),
                  text: 'Adicionar Checkpoint',
                ),
                Tab(
                  icon: Badge(
                    label: Text('${_checkpoints.length}'),
                    isLabelVisible: _checkpoints.isNotEmpty,
                    child: const Icon(Icons.list_alt),
                  ),
                  text: 'Lista de Checkpoints',
                ),
              ],
            ),
          ),

          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildFormTab(), _buildListTab()],
            ),
          ),

          // Action Buttons
          if (_checkpoints.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    '${_checkpoints.length} checkpoint(s) pendentes',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _checkpoints.clear();
                      });
                    },
                    child: const Text('Limpar Lista'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveCheckpoints,
                    icon:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Icon(Icons.cloud_upload),
                    label: Text(_isLoading ? 'Salvando...' : 'Salvar Todos'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informações Básicas
            _buildSectionCard(
              title: 'Informações Básicas',
              icon: Icons.info_outline,
              children: [
                TextFormField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome do Checkpoint*',
                    hintText: 'Ex: Posto Shell Fazenda',
                    prefixIcon: const Icon(Icons.place),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descricaoController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descrição*',
                    hintText: 'Descreva o checkpoint e suas características',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tempoMinimoController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Tempo Mínimo (minutos)*',
                    hintText: 'Tempo mínimo no checkpoint',
                    prefixIcon: const Icon(Icons.timer),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || int.tryParse(value.trim()) == null) {
                      return 'Informe um tempo válido';
                    }
                    return null;
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Localização
            _buildSectionCard(
              title: 'Localização',
              icon: Icons.location_on,
              children: [
                SwitchListTile(
                  title: const Text('Usar coordenadas manuais'),
                  subtitle: const Text('Inserir latitude e longitude'),
                  value: _usarLocalizacaoManual,
                  onChanged: (value) {
                    setState(() {
                      _usarLocalizacaoManual = value;
                    });
                  },
                ),
                if (_usarLocalizacaoManual) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Latitude',
                            hintText: 'Ex: 14.9195',
                            prefixIcon: const Icon(Icons.navigation),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Longitude',
                            hintText: 'Ex: -23.5086',
                            prefixIcon: const Icon(Icons.navigation),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'A localização será obtida automaticamente via GPS',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Configuração do Percurso
            _buildSectionCard(
              title: 'Configuração do Percurso',
              icon: Icons.route,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _percurso,
                  decoration: InputDecoration(
                    labelText: 'Percurso*',
                    prefixIcon: const Icon(Icons.alt_route),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'A', child: Text('Percurso A')),
                    DropdownMenuItem(value: 'B', child: Text('Percurso B')),
                    DropdownMenuItem(
                      value: 'ambos',
                      child: Text('Ambos os Percursos'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _percurso = value ?? 'ambos';
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _ordemA.toString(),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Ordem no Percurso A',
                          prefixIcon: const Icon(Icons.looks_one),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _ordemA = int.tryParse(value) ?? 1;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: _ordemB.toString(),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Ordem no Percurso B',
                          prefixIcon: const Icon(Icons.looks_two),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _ordemB = int.tryParse(value) ?? 1;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Desafios
            _buildSectionCard(
              title: 'Desafios',
              icon: Icons.quiz,
              children: [
                _buildPerguntaDropdown(),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Checkpoint Final com Múltiplos Jogos'),
                  subtitle: const Text(
                    'Marque para permitir seleção de vários jogos',
                  ),
                  value: _finalJogos,
                  onChanged: (value) {
                    setState(() {
                      _finalJogos = value ?? false;
                      _jogosSelecionados.clear();
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                _buildJogosSelector(),
              ],
            ),

            const SizedBox(height: 24),

            // Add Button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _addCheckpoint,
                icon: const Icon(Icons.add_location),
                label: const Text(
                  'Adicionar Checkpoint à Lista',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTab() {
    if (_checkpoints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhum checkpoint adicionado',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione checkpoints usando a aba "Adicionar"',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _checkpoints.length,
      itemBuilder: (context, index) {
        final checkpoint = _checkpoints[index];
        return _buildCheckpointCard(checkpoint, index);
      },
    );
  }

  Widget _buildCheckpointCard(Map<String, dynamic> checkpoint, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _editCheckpoint(index),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${checkpoint['codigo']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          checkpoint['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          checkpoint['descricao'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editCheckpoint(index);
                      } else if (value == 'delete') {
                        _deleteCheckpoint(index);
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Excluir',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Info chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.timer,
                    '${checkpoint['tempoMinimo']} min',
                  ),
                  _buildInfoChip(
                    Icons.route,
                    'Percurso ${checkpoint['percurso'].toString().toUpperCase()}',
                  ),
                  _buildInfoChip(Icons.looks_one, 'A: ${checkpoint['ordemA']}'),
                  _buildInfoChip(Icons.looks_two, 'B: ${checkpoint['ordemB']}'),
                  if (checkpoint['finalComJogosFinais'] == true)
                    _buildInfoChip(Icons.flag, 'Final', color: Colors.orange),
                ],
              ),

              if (checkpoint['jogosIds'] != null &&
                  (checkpoint['jogosIds'] as List).isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sports_esports,
                        size: 20,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(checkpoint['jogosIds'] as List).length} jogos finais',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).primaryColor).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? Theme.of(context).primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPerguntaDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('perguntas').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final perguntas = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          initialValue:
              _pergunta1IdController.text.isEmpty
                  ? null
                  : _pergunta1IdController.text,
          decoration: InputDecoration(
            labelText: 'Selecione a Pergunta*',
            prefixIcon: const Icon(Icons.quiz),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          hint: const Text('Escolha uma pergunta'),
          items:
              perguntas.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final texto = data['pergunta'] ?? 'Sem título';
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(
                    texto.length > 50 ? '${texto.substring(0, 50)}...' : texto,
                  ),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _pergunta1IdController.text = value ?? '';
            });
          },
        );
      },
    );
  }

  Widget _buildJogosSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('jogos').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final jogos = snapshot.data!.docs;

        if (_finalJogos) {
          // Multiple selection
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sports_esports, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Selecione os Jogos Finais (${_jogosSelecionados.length} selecionados)',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: jogos.length,
                    itemBuilder: (context, index) {
                      final doc = jogos[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final nome = data['nome'] ?? 'Sem nome';
                      final tipo = data['tipo'] ?? '';
                      final id = doc.id;

                      return CheckboxListTile(
                        title: Text(nome),
                        subtitle: tipo.isNotEmpty ? Text(tipo) : null,
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
                        dense: true,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        } else {
          // Single selection
          return DropdownButtonFormField<String>(
            initialValue:
                _jogoIdController.text.isEmpty ? null : _jogoIdController.text,
            decoration: InputDecoration(
              labelText: 'Selecione o Jogo*',
              prefixIcon: const Icon(Icons.sports_esports),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            hint: const Text('Escolha um jogo'),
            items:
                jogos.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nome = data['nome'] ?? 'Sem nome';
                  final tipo = data['tipo'] ?? '';
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text('$nome${tipo.isNotEmpty ? " ($tipo)" : ""}'),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _jogoIdController.text = value ?? '';
              });
            },
          );
        }
      },
    );
  }
}
