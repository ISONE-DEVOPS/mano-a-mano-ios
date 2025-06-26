import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JogosManagementView extends StatefulWidget {
  const JogosManagementView({super.key});

  @override
  State<JogosManagementView> createState() => _JogosManagementViewState();
}

class _JogosManagementViewState extends State<JogosManagementView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();

  // Controllers do formulário
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _pontuacaoController = TextEditingController();
  final _regrasController = TextEditingController();
  final _materialController = TextEditingController();
  final _tempoEstimadoController = TextEditingController();

  // Estado do formulário
  String _tipoSelecionado = 'pontaria';
  String _dificuldadeSelecionada = 'média';
  String? _selectedEditionId;
  String? _selectedEventId;
  String? _selectedCheckpointId;
  bool _avaliacaoAutomatica = false;
  bool _isEditing = false;
  String? _editingDocId;

  // Filtros
  String _filtroTipo = 'todos';
  String _filtroDificuldade = 'todos';
  String _filtroTexto = '';

  final List<String> _tipos = [
    'pontaria',
    'conhecimento',
    'equilibrio',
    'resistencia',
    'criatividade',
  ];

  final List<String> _dificuldades = ['fácil', 'média', 'difícil'];

  // Cores melhoradas
  static const Color _primaryColor = Color(0xFF2E7D32); // Verde profissional
  static const Color _secondaryColor = Color(0xFF4CAF50); // Verde claro
  static const Color _accentColor = Color(0xFFFF9800); // Laranja para destaques
  static const Color _backgroundColor = Color(0xFFF8F9FA); // Cinza muito claro
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF212529);
  static const Color _textSecondary = Color(0xFF6C757D);
  static const Color _errorColor = Color(0xFFDC3545);
  static const Color _successColor = Color(0xFF28A745);
  static const Color _warningColor = Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _filtroTexto = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _nomeController.dispose();
    _descricaoController.dispose();
    _pontuacaoController.dispose();
    _regrasController.dispose();
    _materialController.dispose();
    _tempoEstimadoController.dispose();
    super.dispose();
  }

  void _limparFormulario() {
    _nomeController.clear();
    _descricaoController.clear();
    _pontuacaoController.clear();
    _regrasController.clear();
    _materialController.clear();
    _tempoEstimadoController.clear();
    setState(() {
      _tipoSelecionado = 'pontaria';
      _dificuldadeSelecionada = 'média';
      _selectedEditionId = null;
      _selectedEventId = null;
      _selectedCheckpointId = null;
      _avaliacaoAutomatica = false;
      _isEditing = false;
      _editingDocId = null;
    });
  }

  void _carregarJogoParaEdicao(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    _nomeController.text = data['nome'] ?? '';
    _descricaoController.text = data['descricao'] ?? '';
    _pontuacaoController.text = (data['pontuacaoMax'] ?? 0).toString();
    _regrasController.text = data['regras'] ?? '';
    _materialController.text = data['materialNecessario'] ?? '';
    _tempoEstimadoController.text = (data['tempoEstimado'] ?? 0).toString();

    setState(() {
      _tipoSelecionado = data['tipo'] ?? 'pontaria';
      _dificuldadeSelecionada = data['nivelDificuldade'] ?? 'média';
      _selectedEditionId = data['editionId'];
      _selectedEventId = data['eventId'];
      _selectedCheckpointId = data['checkpointId'];
      _avaliacaoAutomatica = data['avaliacaoAutomatica'] ?? false;
      _isEditing = true;
      _editingDocId = doc.id;
    });

    _tabController.animateTo(0);
  }

  Future<void> _salvarJogo() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final jogoData = {
        'nome': _nomeController.text,
        'descricao': _descricaoController.text,
        'pontuacaoMax': int.tryParse(_pontuacaoController.text) ?? 0,
        'regras': _regrasController.text,
        'tipo': _tipoSelecionado,
        'nivelDificuldade': _dificuldadeSelecionada,
        'editionId': _selectedEditionId,
        'eventId': _selectedEventId,
        'checkpointId': _selectedCheckpointId,
        'materialNecessario': _materialController.text,
        'tempoEstimado': int.tryParse(_tempoEstimadoController.text) ?? 0,
        'avaliacaoAutomatica': _avaliacaoAutomatica,
        'criadoEm': _isEditing ? null : FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      jogoData.removeWhere((key, value) => value == null);

      if (_isEditing && _editingDocId != null) {
        await FirebaseFirestore.instance
            .collection('jogos')
            .doc(_editingDocId)
            .update(jogoData);

        if (mounted) {
          _showSnackBar('Jogo atualizado com sucesso!', _successColor);
        }
      } else {
        await FirebaseFirestore.instance.collection('jogos').add(jogoData);

        if (mounted) {
          _showSnackBar('Jogo criado com sucesso!', _successColor);
        }
      }

      _limparFormulario();
      _tabController.animateTo(1);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro ao salvar jogo: $e', _errorColor);
      }
    }
  }

  Future<void> _deletarJogo(String id, String nome) async {
    final confirmacao = await _showConfirmDialog(
      'Confirmar Exclusão',
      'Tem certeza que deseja deletar o jogo "$nome"?\n\nEsta ação não pode ser desfeita.',
      'Deletar',
      _errorColor,
    );

    if (confirmacao == true) {
      try {
        await FirebaseFirestore.instance.collection('jogos').doc(id).delete();

        if (mounted) {
          _showSnackBar('Jogo deletado com sucesso!', _warningColor);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Erro ao deletar jogo: $e', _errorColor);
        }
      }
    }
  }

  Future<void> _duplicarJogo(DocumentSnapshot doc) async {
    final data = doc.data()! as Map<String, dynamic>;

    try {
      final novoJogo = Map<String, dynamic>.from(data);
      novoJogo['nome'] = '${data['nome']} (Cópia)';
      novoJogo['criadoEm'] = FieldValue.serverTimestamp();
      novoJogo['atualizadoEm'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance.collection('jogos').add(novoJogo);

      if (mounted) {
        _showSnackBar('Jogo duplicado com sucesso!', _secondaryColor);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro ao duplicar jogo: $e', _errorColor);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    String title,
    String content,
    String actionText,
    Color actionColor,
  ) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(content, style: TextStyle(color: _textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: _textSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(actionText),
              ),
            ],
          ),
    );
  }

  Widget _buildFormularioJogo() {
    return Container(
      color: _backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho melhorado
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _isEditing
                                ? _accentColor.withAlpha(25)
                                : _secondaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isEditing ? Icons.edit : Icons.add_circle_outline,
                        color: _isEditing ? _accentColor : _secondaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Editar Jogo' : 'Criar Novo Jogo',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isEditing
                                ? 'Modifique as informações do jogo'
                                : 'Preencha os dados para criar um novo jogo',
                            style: TextStyle(
                              fontSize: 14,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_isEditing)
                      IconButton.outlined(
                        onPressed: _limparFormulario,
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          foregroundColor: _textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Formulário principal
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seção: Informações Básicas
                    _buildSecaoHeader(
                      'Informações Básicas',
                      Icons.info_outline,
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _nomeController,
                            label: 'Nome do Jogo',
                            hint: 'Ex: Torre de BaShell',
                            icon: Icons.sports_esports_outlined,
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            value: _tipoSelecionado,
                            label: 'Tipo',
                            icon: Icons.category_outlined,
                            items: _tipos,
                            onChanged:
                                (v) => setState(() => _tipoSelecionado = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            value: _dificuldadeSelecionada,
                            label: 'Dificuldade',
                            icon: Icons.trending_up_outlined,
                            items: _dificuldades,
                            onChanged:
                                (v) => setState(
                                  () => _dificuldadeSelecionada = v!,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _descricaoController,
                      label: 'Descrição',
                      hint: 'Descreva o objetivo e mecânica do jogo',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      required: true,
                    ),
                    const SizedBox(height: 32),

                    // Seção: Configurações
                    _buildSecaoHeader(
                      'Configurações do Jogo',
                      Icons.settings_outlined,
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _pontuacaoController,
                            label: 'Pontuação Máxima',
                            hint: '0',
                            icon: Icons.star_outline,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _tempoEstimadoController,
                            label: 'Tempo Estimado (min)',
                            hint: '0',
                            icon: Icons.schedule_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _regrasController,
                      label: 'Regras do Jogo',
                      hint: 'Explique como jogar e as regras específicas',
                      icon: Icons.rule_outlined,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _materialController,
                      label: 'Material Necessário',
                      hint: 'Liste os materiais e equipamentos necessários',
                      icon: Icons.inventory_2_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    // Switch melhorado
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            color: _primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Avaliação Automática',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _textPrimary,
                                  ),
                                ),
                                Text(
                                  'O jogo será pontuado automaticamente pelo sistema',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _avaliacaoAutomatica,
                            onChanged:
                                (v) => setState(() => _avaliacaoAutomatica = v),
                            activeColor: _secondaryColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Seção: Associações
                    _buildSecaoHeader('Associações', Icons.link_outlined),
                    const SizedBox(height: 20),

                    _buildEditionDropdown(),
                    const SizedBox(height: 16),

                    if (_selectedEditionId != null) _buildEventDropdown(),
                    if (_selectedEditionId != null) const SizedBox(height: 16),

                    if (_selectedEventId != null) _buildCheckpointDropdown(),
                    const SizedBox(height: 32),

                    // Botões de ação melhorados
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _salvarJogo,
                            icon: Icon(_isEditing ? Icons.update : Icons.save),
                            label: Text(
                              _isEditing ? 'Atualizar Jogo' : 'Criar Jogo',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: _limparFormulario,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Limpar'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(140, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: _textSecondary,
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListaJogos() {
    return Container(
      color: _backgroundColor,
      child: Column(
        children: [
          // Barra de filtros melhorada
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lista de Jogos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Busca melhorada
                Container(
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar jogos por nome ou descrição...',
                      hintStyle: TextStyle(color: _textSecondary),
                      prefixIcon: Icon(Icons.search, color: _textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Filtros melhorados
                Row(
                  children: [
                    Expanded(
                      child: _buildFiltroDropdown(
                        value: _filtroTipo,
                        label: 'Tipo',
                        items: ['todos', ..._tipos],
                        onChanged: (v) => setState(() => _filtroTipo = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFiltroDropdown(
                        value: _filtroDificuldade,
                        label: 'Dificuldade',
                        items: ['todos', ..._dificuldades],
                        onChanged:
                            (v) => setState(() => _filtroDificuldade = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _filtroTipo = 'todos';
                          _filtroDificuldade = 'todos';
                          _searchController.clear();
                        });
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Limpar Filtros'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _errorColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de jogos melhorada
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('jogos').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: _errorColor),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar jogos',
                          style: TextStyle(fontSize: 18, color: _textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(color: _textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: _primaryColor),
                        const SizedBox(height: 16),
                        Text(
                          'Carregando jogos...',
                          style: TextStyle(color: _textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                var jogos = snapshot.data!.docs;

                // Aplicar filtros
                jogos =
                    jogos.where((doc) {
                      final data = doc.data()! as Map<String, dynamic>;
                      final nome =
                          (data['nome'] ?? '').toString().toLowerCase();
                      final descricao =
                          (data['descricao'] ?? '').toString().toLowerCase();
                      final tipo = data['tipo'] ?? '';
                      final dificuldade = data['nivelDificuldade'] ?? '';

                      if (_filtroTexto.isNotEmpty) {
                        final busca = _filtroTexto.toLowerCase();
                        if (!nome.contains(busca) &&
                            !descricao.contains(busca)) {
                          return false;
                        }
                      }

                      if (_filtroTipo != 'todos' && tipo != _filtroTipo) {
                        return false;
                      }

                      if (_filtroDificuldade != 'todos' &&
                          dificuldade != _filtroDificuldade) {
                        return false;
                      }

                      return true;
                    }).toList();

                if (jogos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_esports_outlined,
                          size: 64,
                          color: _textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum jogo encontrado',
                          style: TextStyle(fontSize: 18, color: _textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tente ajustar os filtros ou criar um novo jogo',
                          style: TextStyle(color: _textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: jogos.length,
                  itemBuilder: (context, index) {
                    final doc = jogos[index];
                    final data = doc.data()! as Map<String, dynamic>;

                    return _buildJogoCard(doc, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJogoCard(DocumentSnapshot doc, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do card melhorado
            Row(
              children: [
                // Ícone com melhor contraste
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getColorForTipo(data['tipo']).withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForTipo(data['tipo']),
                    color: _getColorForTipo(data['tipo']),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Nome e informações
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['nome'] ?? 'Sem nome',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildChip(
                            data['tipo'] ?? '',
                            _getColorForTipo(data['tipo']),
                          ),
                          const SizedBox(width: 8),
                          _buildChip(
                            data['nivelDificuldade'] ?? '',
                            _getColorForDificuldade(data['nivelDificuldade']),
                          ),
                          if (data['avaliacaoAutomatica'] == true) ...[
                            const SizedBox(width: 8),
                            _buildChip('Auto', _secondaryColor),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Pontuação com melhor design
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _accentColor.withAlpha(38),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 18, color: _accentColor),
                      const SizedBox(width: 6),
                      Text(
                        '${data['pontuacaoMax'] ?? 0}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _accentColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Descrição com melhor tipografia
            if (data['descricao'] != null && data['descricao'].isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['descricao'],
                  style: TextStyle(
                    color: _textSecondary,
                    height: 1.5,
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const SizedBox(height: 16),

            // Informações adicionais melhoradas
            Row(
              children: [
                if (data['tempoEstimado'] != null &&
                    data['tempoEstimado'] > 0) ...[
                  Icon(Icons.schedule, size: 16, color: _textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${data['tempoEstimado']} min',
                    style: TextStyle(color: _textSecondary, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                ],
                if (data['materialNecessario'] != null &&
                    data['materialNecessario'].isNotEmpty) ...[
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: _textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Material necessário',
                    style: TextStyle(color: _textSecondary, fontSize: 13),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // Botões de ação melhorados
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _carregarJogoParaEdicao(doc),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _secondaryColor,
                      side: BorderSide(color: _secondaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _duplicarJogo(doc),
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: const Text('Duplicar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accentColor,
                      side: BorderSide(color: _accentColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deletarJogo(doc.id, data['nome'] ?? ''),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Deletar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _errorColor,
                      side: BorderSide(color: _errorColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widgets auxiliares melhorados
  Widget _buildSecaoHeader(String titulo, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: _textSecondary),
        hintStyle: TextStyle(color: _textSecondary.withAlpha(178)),
        prefixIcon: Icon(icon, color: _textSecondary),
        filled: true,
        fillColor: _backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _errorColor),
        ),
      ),
      style: TextStyle(color: _textPrimary),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator:
          required
              ? (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null
              : null,
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _textSecondary),
        prefixIcon: Icon(icon, color: _textSecondary),
        filled: true,
        fillColor: _backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor),
        ),
      ),
      items:
          items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: TextStyle(color: _textPrimary)),
                ),
              )
              .toList(),
      onChanged: onChanged,
      style: TextStyle(color: _textPrimary),
      dropdownColor: _cardColor,
    );
  }

  Widget _buildFiltroDropdown({
    required String value,
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        items:
            items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e == 'todos' ? 'Todos' : e,
                      style: TextStyle(color: _textPrimary),
                    ),
                  ),
                )
                .toList(),
        onChanged: onChanged,
        dropdownColor: _cardColor,
      ),
    );
  }

  Widget _buildEditionDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('editions').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 60,
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
                strokeWidth: 2,
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Text(
            'Erro ao carregar edições',
            style: TextStyle(color: _errorColor),
          );
        }

        final editions = snapshot.data?.docs ?? [];
        return _buildDropdown(
          value: _selectedEditionId ?? '',
          label: 'Edição',
          icon: Icons.event_outlined,
          items: ['', ...editions.map((doc) => doc.id)],
          onChanged: (val) {
            setState(() {
              _selectedEditionId = val?.isEmpty == true ? null : val;
              _selectedEventId = null;
              _selectedCheckpointId = null;
            });
          },
        );
      },
    );
  }

  Widget _buildEventDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('editions')
              .doc(_selectedEditionId)
              .collection('events')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 60,
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
                strokeWidth: 2,
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Text(
            'Erro ao carregar eventos',
            style: TextStyle(color: _errorColor),
          );
        }

        final events = snapshot.data?.docs ?? [];
        return _buildDropdown(
          value: _selectedEventId ?? '',
          label: 'Evento',
          icon: Icons.event_note_outlined,
          items: ['', ...events.map((doc) => doc.id)],
          onChanged: (val) {
            setState(() {
              _selectedEventId = val?.isEmpty == true ? null : val;
              _selectedCheckpointId = null;
            });
          },
        );
      },
    );
  }

  Widget _buildCheckpointDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('editions')
              .doc(_selectedEditionId)
              .collection('events')
              .doc(_selectedEventId)
              .collection('checkpoints')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 60,
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
                strokeWidth: 2,
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Text(
            'Erro ao carregar checkpoints',
            style: TextStyle(color: _errorColor),
          );
        }

        final checkpoints = snapshot.data?.docs ?? [];
        return _buildDropdown(
          value: _selectedCheckpointId ?? '',
          label: 'Checkpoint (Opcional)',
          icon: Icons.location_on_outlined,
          items: ['', ...checkpoints.map((doc) => doc.id)],
          onChanged: (val) {
            setState(() {
              _selectedCheckpointId = val?.isEmpty == true ? null : val;
            });
          },
        );
      },
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Métodos auxiliares para cores e ícones
  Color _getColorForTipo(String? tipo) {
    switch (tipo) {
      case 'pontaria':
        return const Color(0xFFE91E63);
      case 'conhecimento':
        return const Color(0xFF2196F3);
      case 'equilibrio':
        return const Color(0xFF4CAF50);
      case 'resistencia':
        return const Color(0xFFFF9800);
      case 'criatividade':
        return const Color(0xFF9C27B0);
      default:
        return _textSecondary;
    }
  }

  IconData _getIconForTipo(String? tipo) {
    switch (tipo) {
      case 'pontaria':
        return Icons.gps_fixed;
      case 'conhecimento':
        return Icons.psychology_outlined;
      case 'equilibrio':
        return Icons.balance;
      case 'resistencia':
        return Icons.fitness_center_outlined;
      case 'criatividade':
        return Icons.palette_outlined;
      default:
        return Icons.sports_esports_outlined;
    }
  }

  Color _getColorForDificuldade(String? dificuldade) {
    switch (dificuldade) {
      case 'fácil':
        return _successColor;
      case 'média':
        return _warningColor;
      case 'difícil':
        return _errorColor;
      default:
        return _textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Gestão de Jogos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: _primaryColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(icon: Icon(Icons.add_circle_outline), text: 'Criar/Editar'),
                Tab(
                  icon: Icon(Icons.list_alt_outlined),
                  text: 'Lista de Jogos',
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFormularioJogo(), _buildListaJogos()],
      ),
    );
  }
}
