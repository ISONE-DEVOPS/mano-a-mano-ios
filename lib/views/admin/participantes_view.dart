import 'package:flutter/material.dart';
import 'edit_participantes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';

class ParticipantesView extends StatefulWidget {
  const ParticipantesView({super.key});

  @override
  State<ParticipantesView> createState() => _ParticipantesViewState();
}

class _ParticipantesViewState extends State<ParticipantesView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterRole = 'Todos';
  String _filterTshirt = 'Todos';
  String _filterGrupo = 'Todos';
  bool _isFilterExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho compacto
            _buildCompactHeader(),

            // Conteúdo principal expandido
            Expanded(child: _buildParticipantesList()),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Linha principal com título, pesquisa e botões principais
          Row(
            children: [
              // Título
              const Text(
                'Participantes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 16),

              // Pesquisa compacta
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Pesquisar...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Colors.grey.shade100,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Botão de filtros
              IconButton(
                onPressed: () {
                  setState(() {
                    _isFilterExpanded = !_isFilterExpanded;
                  });
                },
                icon: Icon(
                  _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
                  color: _isFilterExpanded ? Colors.blue : Colors.grey.shade700,
                ),
                tooltip: 'Filtros',
              ),

              // Botões principais compactos
              const SizedBox(width: 8),
              _buildCompactButton(
                Icons.person_add,
                'Novo',
                AppColors.secondary,
                () => Navigator.of(context).pushNamed('/register-participant'),
              ),
              const SizedBox(width: 8),
              _buildCompactButton(
                Icons.download,
                'CSV',
                AppColors.primary,
                _exportParticipantesCsv,
              ),
              const SizedBox(width: 8),
              _buildCompactButton(
                Icons.more_horiz,
                'Mais',
                Colors.orange,
                _showBulkActions,
              ),
            ],
          ),

          // Filtros expansíveis
          if (_isFilterExpanded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCompactDropdown(
                      'Papel',
                      _filterRole,
                      ['Todos', 'admin', 'user', 'staff'],
                      (value) => setState(() => _filterRole = value!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactDropdown(
                      'T-Shirt',
                      _filterTshirt,
                      ['Todos', 'XS', 'S', 'M', 'L', 'XL', 'XXL'],
                      (value) => setState(() => _filterTshirt = value!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactDropdown(
                      'Grupo',
                      _filterGrupo,
                      ['Todos', 'A', 'B'],
                      (value) => setState(() => _filterGrupo = value!),
                      displayMap: {
                        'Todos': 'Todos',
                        'A': 'Grupo A',
                        'B': 'Grupo B',
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: Colors.black),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
        elevation: 2,
        shadowColor: Colors.black26,
      ),
    );
  }

  Widget _buildCompactDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    Map<String, String>? displayMap,
  }) {
    return SizedBox(
      height: 32,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: Colors.black87),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          isDense: true,
          fillColor: Colors.white,
          filled: true,
        ),
        style: const TextStyle(fontSize: 12, color: Colors.black),
        dropdownColor: Colors.white,
        items:
            items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  displayMap?[item] ?? item,
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              );
            }).toList(),
        onChanged: onChanged,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
      ),
    );
  }

  Widget _buildParticipantesList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .orderBy('createdAt', descending: false)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhum participante encontrado',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data!.docs;
        final filteredUsers = _filterUsers(users);

        return Column(
          children: [
            // Contador de resultados
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredUsers.length} participante(s)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (filteredUsers.isNotEmpty)
                    Row(
                      children: [
                        IconButton(
                          onPressed: _exportListaCompleta,
                          icon: const Icon(
                            Icons.groups,
                            size: 18,
                            color: Colors.black87,
                          ),
                          tooltip: 'Lista Completa',
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Lista otimizada
            Expanded(
              child:
                  filteredUsers.isEmpty
                      ? const Center(
                        child: Text(
                          'Nenhum participante corresponde aos filtros',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final doc = filteredUsers[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildOptimizedParticipanteCard(doc, data);
                        },
                      ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptimizedParticipanteCard(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar compacto
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary,
              child: Text(
                (data['nome'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Informações principais
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['nome'] ?? 'Nome não informado',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildCompactRoleBadge(data['role'] ?? 'user'),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['email'] ?? 'Email não informado',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Informações secundárias compactas
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone, size: 12, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data['telefone'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.local_offer,
                        size: 12,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data['tshirt'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status e ações
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Status da equipa/veículo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildCompactStatusChip(data),
                        const SizedBox(height: 4),
                        _buildCompactVeiculoChip(data),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Menu de ações compacto
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleAction(value, doc, data),
                    icon: const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Colors.black87,
                    ),
                    iconSize: 18,
                    color: Colors.white,
                    itemBuilder:
                        (context) => [
                          _buildCompactMenuItem(
                            Icons.edit,
                            'Editar',
                            'editar',
                            Colors.orange,
                          ),
                          _buildCompactMenuItem(
                            Icons.directions_car,
                            'Veículo',
                            'veiculo',
                            Colors.green,
                          ),
                          _buildCompactMenuItem(
                            Icons.group,
                            'Acompanhantes',
                            'acompanhantes',
                            Colors.blue,
                          ),
                          _buildCompactMenuItem(
                            Icons.groups,
                            'Equipa',
                            'equipa',
                            Colors.purple,
                          ),
                          _buildCompactMenuItem(
                            Icons.info,
                            'Detalhes',
                            'detalhes',
                            Colors.deepPurple,
                          ),
                          _buildCompactMenuItem(
                            Icons.qr_code,
                            'QR Code',
                            'qr',
                            Colors.indigo,
                          ),
                          const PopupMenuDivider(),
                          _buildCompactMenuItem(
                            Icons.delete,
                            'Eliminar',
                            'eliminar',
                            Colors.red,
                          ),
                        ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildCompactMenuItem(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRoleBadge(String role) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (role) {
      case 'admin':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = 'Admin';
        break;
      case 'staff':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = 'Staff';
        break;
      default:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        label = 'User';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCompactStatusChip(Map<String, dynamic> data) {
    return FutureBuilder<DocumentSnapshot?>(
      future: _getEquipaInfo(data['equipaId']),
      builder: (context, snapshot) {
        if (snapshot.data?.exists == true) {
          final equipa = snapshot.data!.data() as Map<String, dynamic>;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.shade300, width: 0.5),
            ),
            child: Text(
              '${equipa['nome'] ?? 'Equipa'} (${equipa['grupo'] ?? '?'})',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green.shade800,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.red.shade300, width: 0.5),
          ),
          child: Text(
            'Sem equipa',
            style: TextStyle(
              fontSize: 10,
              color: Colors.red.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactVeiculoChip(Map<String, dynamic> data) {
    return FutureBuilder<DocumentSnapshot?>(
      future: _getVeiculoInfo(data['veiculoId']),
      builder: (context, snapshot) {
        if (snapshot.data?.exists == true) {
          final veiculo = snapshot.data!.data() as Map<String, dynamic>;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.shade300, width: 0.5),
            ),
            child: Text(
              veiculo['matricula'] ?? 'Veículo',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.red.shade300, width: 0.5),
          ),
          child: Text(
            'Sem veículo',
            style: TextStyle(
              fontSize: 10,
              color: Colors.red.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  // ============= MÉTODOS DE FUNCIONALIDADE =============

  List<QueryDocumentSnapshot> _filterUsers(List<QueryDocumentSnapshot> users) {
    return users.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // Filtro por pesquisa
      if (_searchQuery.isNotEmpty) {
        final nome = (data['nome'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final telefone = (data['telefone'] ?? '').toString().toLowerCase();

        if (!nome.contains(_searchQuery) &&
            !email.contains(_searchQuery) &&
            !telefone.contains(_searchQuery)) {
          return false;
        }
      }

      // Filtro por papel
      if (_filterRole != 'Todos') {
        final role = data['role'] ?? 'user';
        if (role != _filterRole) {
          return false;
        }
      }

      // Filtro por t-shirt
      if (_filterTshirt != 'Todos') {
        final tshirt = data['tshirt'] ?? '';
        if (tshirt != _filterTshirt) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<DocumentSnapshot?> _getEquipaInfo(String? equipaId) async {
    if (equipaId == null || equipaId.isEmpty) return null;
    try {
      return await FirebaseFirestore.instance
          .collection('equipas')
          .doc(equipaId)
          .get();
    } catch (e) {
      return null;
    }
  }

  Future<DocumentSnapshot?> _getVeiculoInfo(String? veiculoId) async {
    if (veiculoId == null || veiculoId.isEmpty) return null;
    try {
      return await FirebaseFirestore.instance
          .collection('veiculos')
          .doc(veiculoId)
          .get();
    } catch (e) {
      return null;
    }
  }

  void _handleAction(
    String action,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    switch (action) {
      case 'editar':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EditParticipantesView(userId: doc.id),
          ),
        );
        break;
      case 'veiculo':
        _editarVeiculo(context, doc.id, data);
        break;
      case 'acompanhantes':
        _editarAcompanhantes(context, data);
        break;
      case 'equipa':
        _editarEquipa(context, doc.id, data);
        break;
      case 'detalhes':
        _verDetalhes(context, data);
        break;
      case 'qr':
        _gerarQrCode(context, doc.id, data);
        break;
      case 'eliminar':
        _eliminarParticipante(context, doc, data);
        break;
    }
  }

  // ============= DIÁLOGO PARA EDITAR/CRIAR EQUIPA =============
  void _editarEquipa(
    BuildContext context,
    String userId,
    Map<String, dynamic> userData,
  ) async {
    final equipaId = userData['equipaId'];
    DocumentSnapshot? equipaDoc;

    // Se existe equipaId, buscar dados da equipa
    if (equipaId != null && equipaId.isNotEmpty) {
      equipaDoc = await _getEquipaInfo(equipaId);
    }

    // Verificar se o widget ainda está montado antes de usar context
    if (!mounted) return;

    // CORREÇÃO: Mover declaração de equipaData para antes do uso
    final equipaData = equipaDoc?.data() as Map<String, dynamic>?;
    final isEdit = equipaData != null;

    // Controllers para o formulário
    final nomeController = TextEditingController(
      text: equipaData?['nome'] ?? '',
    );
    final hinoController = TextEditingController(
      text: equipaData?['hino'] ?? '',
    );
    String selectedGrupo = equipaData?['grupo'] ?? 'A';

    if (!mounted) return; // Verificação adicional antes de showDialog

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              isEdit ? 'Editar Equipa' : 'Criar Nova Equipa',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nome da Equipa
                    TextField(
                      controller: nomeController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Nome da Equipa',
                        labelStyle: const TextStyle(color: Colors.black87),
                        hintText: 'Digite o nome da equipa',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.groups,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Hino (Grito de Guerra)
                    TextField(
                      controller: hinoController,
                      style: const TextStyle(color: Colors.black),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Hino/Grito de Guerra',
                        labelStyle: const TextStyle(color: Colors.black87),
                        hintText: 'Digite o grito de guerra da equipa',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.campaign,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Seleção do Grupo
                    DropdownButtonFormField<String>(
                      value: selectedGrupo,
                      style: const TextStyle(color: Colors.black),
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: 'Grupo',
                        labelStyle: const TextStyle(color: Colors.black87),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(Icons.flag, color: Colors.green),
                      ),
                      items:
                          ['A', 'B'].map((grupo) {
                            return DropdownMenuItem(
                              value: grupo,
                              child: Text(
                                'Grupo $grupo',
                                style: const TextStyle(color: Colors.black),
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        selectedGrupo = value!;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nomeController.text.trim().isEmpty) {
                    if (!mounted) return;
                    _showErrorSnackBar(
                      context,
                      'O nome da equipa é obrigatório',
                    );
                    return;
                  }

                  try {
                    final equipaDataToSave = {
                      'nome': nomeController.text.trim(),
                      'hino': hinoController.text.trim(),
                      'grupo': selectedGrupo,
                      'pontuacaoTotal': equipaData?['pontuacaoTotal'] ?? 0,
                      'ranking': equipaData?['ranking'] ?? 1,
                      'membros': equipaData?['membros'] ?? [userId],
                      'bandeiraUrl': equipaData?['bandeiraUrl'] ?? '',
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    String finalEquipaId;

                    if (isEdit) {
                      // Atualizar equipa existente
                      await FirebaseFirestore.instance
                          .collection('equipas')
                          .doc(equipaId)
                          .update(equipaDataToSave);
                      finalEquipaId = equipaId;
                    } else {
                      // Criar nova equipa
                      equipaDataToSave['createdAt'] =
                          FieldValue.serverTimestamp();
                      final docRef = await FirebaseFirestore.instance
                          .collection('equipas')
                          .add(equipaDataToSave);
                      finalEquipaId = docRef.id;
                    }

                    // Atualizar o user com o equipaId
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .update({'equipaId': finalEquipaId});

                    if (!mounted) return;
                    Navigator.pop(ctx);
                    _showSuccessSnackBar(
                      context,
                      isEdit
                          ? 'Equipa atualizada com sucesso!'
                          : 'Equipa criada com sucesso!',
                    );
                  } catch (e) {
                    if (!mounted) return;
                    _showErrorSnackBar(
                      context,
                      'Erro ao ${isEdit ? 'atualizar' : 'criar'} equipa: $e',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(isEdit ? 'Atualizar' : 'Criar'),
              ),
            ],
          ),
    );
  }

  // ============= DIÁLOGO PARA EDITAR/CRIAR VEÍCULO =============
  void _editarVeiculo(
    BuildContext context,
    String userId,
    Map<String, dynamic> userData,
  ) async {
    final veiculoId = userData['veiculoId'];
    DocumentSnapshot? veiculoDoc;

    // Se existe veiculoId, buscar dados do veículo
    if (veiculoId != null && veiculoId.isNotEmpty) {
      veiculoDoc = await _getVeiculoInfo(veiculoId);
    }

    // Verificar se o widget ainda está montado antes de usar context
    if (!mounted) return;

    // CORREÇÃO: Mover declaração de veiculoData para antes do uso
    final veiculoData = veiculoDoc?.data() as Map<String, dynamic>?;
    final isEdit = veiculoData != null;

    // Controllers para o formulário
    final matriculaController = TextEditingController(
      text: veiculoData?['matricula'] ?? '',
    );
    final modeloController = TextEditingController(
      text: veiculoData?['modelo'] ?? '',
    );
    final disticoController = TextEditingController(
      text: veiculoData?['distico'] ?? '',
    );

    if (!mounted) return; // Verificação adicional antes de showDialog

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              isEdit ? 'Editar Veículo' : 'Registar Novo Veículo',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Matrícula
                    TextField(
                      controller: matriculaController,
                      style: const TextStyle(color: Colors.black),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Matrícula',
                        labelStyle: const TextStyle(color: Colors.black87),
                        hintText: 'Ex: AA-123-BB',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.directions_car,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Modelo
                    TextField(
                      controller: modeloController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Modelo do Veículo',
                        labelStyle: const TextStyle(color: Colors.black87),
                        hintText: 'Ex: Toyota Corolla',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.car_repair,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dístico (código único)
                    TextField(
                      controller: disticoController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Dístico (Código)',
                        labelStyle: const TextStyle(color: Colors.black87),
                        hintText: 'Código único do veículo',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.qr_code,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Informação adicional
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'O condutor atual será definido como proprietário do veículo.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (matriculaController.text.trim().isEmpty) {
                    if (!mounted) return;
                    _showErrorSnackBar(context, 'A matrícula é obrigatória');
                    return;
                  }

                  try {
                    // Buscar nome da equipa se existir
                    String nomeEquipa = '';
                    if (userData['equipaId'] != null &&
                        userData['equipaId'].toString().isNotEmpty) {
                      final equipaDoc = await _getEquipaInfo(
                        userData['equipaId'],
                      );
                      if (equipaDoc?.exists == true) {
                        final equipaData =
                            equipaDoc!.data() as Map<String, dynamic>;
                        nomeEquipa = equipaData['nome'] ?? '';
                      }
                    }

                    final veiculoDataToSave = {
                      'matricula':
                          matriculaController.text.trim().toUpperCase(),
                      'modelo': modeloController.text.trim(),
                      'distico': disticoController.text.trim(),
                      'ownerId': userId,
                      'nome_equipa': nomeEquipa,
                      'passageiros': veiculoData?['passageiros'] ?? [userId],
                      'checkpointId': veiculoData?['checkpointId'] ?? [],
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    String finalVeiculoId;

                    if (isEdit) {
                      // Atualizar veículo existente
                      await FirebaseFirestore.instance
                          .collection('veiculos')
                          .doc(veiculoId)
                          .update(veiculoDataToSave);
                      finalVeiculoId = veiculoId;
                    } else {
                      // Criar novo veículo
                      veiculoDataToSave['createdAt'] =
                          FieldValue.serverTimestamp();
                      final docRef = await FirebaseFirestore.instance
                          .collection('veiculos')
                          .add(veiculoDataToSave);
                      finalVeiculoId = docRef.id;
                    }

                    // Atualizar o user com o veiculoId
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .update({'veiculoId': finalVeiculoId});

                    if (!mounted) return;
                    Navigator.pop(ctx);
                    _showSuccessSnackBar(
                      context,
                      isEdit
                          ? 'Veículo atualizado com sucesso!'
                          : 'Veículo registado com sucesso!',
                    );
                  } catch (e) {
                    if (!mounted) return;
                    _showErrorSnackBar(
                      context,
                      'Erro ao ${isEdit ? 'atualizar' : 'registar'} veículo: $e',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(isEdit ? 'Atualizar' : 'Registar'),
              ),
            ],
          ),
    );
  }

  // ============= MÉTODOS AUXILIARES =============
  void _showBulkActions() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Ações em Lote',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.groups, color: Colors.purple),
                  title: const Text(
                    'Criar Equipas Automáticas',
                    style: TextStyle(color: Colors.black),
                  ),
                  subtitle: const Text(
                    'Organizar participantes em equipas',
                    style: TextStyle(color: Colors.black54),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _criarEquipasAutomaticas();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.qr_code, color: Colors.blue),
                  title: const Text(
                    'Gerar QR Codes',
                    style: TextStyle(color: Colors.black),
                  ),
                  subtitle: const Text(
                    'Para todos os participantes',
                    style: TextStyle(color: Colors.black54),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _gerarQrCodesTodos();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.green),
                  title: const Text(
                    'Enviar Convites',
                    style: TextStyle(color: Colors.black),
                  ),
                  subtitle: const Text(
                    'Para participantes sem equipas',
                    style: TextStyle(color: Colors.black54),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _enviarConvites();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Fechar',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
    );
  }

  void _editarAcompanhantes(BuildContext context, Map<String, dynamic> data) {
    _showInfoDialog(
      context,
      'Editar Acompanhantes',
      'Funcionalidade em desenvolvimento...',
    );
  }

  void _verDetalhes(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Detalhes do Participante',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow('Nome', data['nome'] ?? 'N/A'),
                    _buildDetailRow('Email', data['email'] ?? 'N/A'),
                    _buildDetailRow('Telefone', data['telefone'] ?? 'N/A'),
                    _buildDetailRow('Emergência', data['emergencia'] ?? 'N/A'),
                    _buildDetailRow('T-Shirt', data['tshirt'] ?? 'N/A'),
                    _buildDetailRow('Papel', data['role'] ?? 'user'),
                    _buildDetailRow(
                      'Ativo',
                      (data['ativo'] == true) ? 'Sim' : 'Não',
                    ),
                    if (data['createdAt'] != null)
                      _buildDetailRow(
                        'Registado em',
                        (data['createdAt'] as Timestamp)
                            .toDate()
                            .toString()
                            .split(' ')[0],
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Fechar',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _gerarQrCode(
    BuildContext context,
    String userId,
    Map<String, dynamic> data,
  ) {
    _showInfoDialog(context, 'QR Code', 'Funcionalidade em desenvolvimento...');
  }

  void _eliminarParticipante(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Confirmar Eliminação',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Tem certeza que deseja eliminar o participante "${data['nome']}"?\n\nEsta ação não pode ser desfeita.',
              style: const TextStyle(color: Colors.black),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(doc.id)
                        .delete();

                    if (!mounted) return;
                    Navigator.pop(ctx);
                    _showSuccessSnackBar(
                      context,
                      'Participante eliminado com sucesso!',
                    );
                  } catch (e) {
                    if (!mounted) return;
                    _showErrorSnackBar(
                      context,
                      'Erro ao eliminar participante: $e',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  Future<void> _exportParticipantesCsv() async {
    _showSuccessSnackBar(context, 'Exportação em desenvolvimento...');
  }

  Future<void> _exportListaCompleta() async {
    _showSuccessSnackBar(context, 'Lista completa em desenvolvimento...');
  }

  void _criarEquipasAutomaticas() {
    _showInfoDialog(
      context,
      'Criar Equipas Automáticas',
      'Funcionalidade em desenvolvimento...',
    );
  }

  void _gerarQrCodesTodos() {
    _showInfoDialog(
      context,
      'Gerar QR Codes',
      'Funcionalidade em desenvolvimento...',
    );
  }

  void _enviarConvites() {
    _showInfoDialog(
      context,
      'Enviar Convites',
      'Funcionalidade em desenvolvimento...',
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
    );
  }
}
