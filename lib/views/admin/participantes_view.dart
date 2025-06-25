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

  int _currentPage = 0;
  static const int _itemsPerPage = 10;

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
                        _currentPage = 0; // Reset para primeira página
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
                () => _showMessage(
                  'Exportação em desenvolvimento...',
                  Colors.orange,
                ),
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
                      (value) => setState(() {
                        _filterRole = value!;
                        _currentPage = 0; // Reset para primeira página
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactDropdown(
                      'T-Shirt',
                      _filterTshirt,
                      ['Todos', 'XS', 'S', 'M', 'L', 'XL', 'XXL'],
                      (value) => setState(() {
                        _filterTshirt = value!;
                        _currentPage = 0; // Reset para primeira página
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactDropdown(
                      'Grupo',
                      _filterGrupo,
                      ['Todos', 'A', 'B'],
                      (value) => setState(() {
                        _filterGrupo = value!;
                        _currentPage = 0; // Reset para primeira página
                      }),
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

        // Cálculo correto da paginação
        final totalPages = (filteredUsers.length / _itemsPerPage).ceil();

        // Garantir que currentPage não excede o total de páginas
        if (_currentPage >= totalPages && totalPages > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _currentPage = totalPages - 1;
            });
          });
        }

        // Paginação
        final startIndex = _currentPage * _itemsPerPage;
        final endIndex = (_currentPage + 1) * _itemsPerPage;
        final pagedUsers = filteredUsers.sublist(
          startIndex,
          endIndex > filteredUsers.length ? filteredUsers.length : endIndex,
        );

        return Column(
          children: [
            // Contador de resultados melhorado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '${filteredUsers.length} participante(s)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      if (filteredUsers.isNotEmpty && totalPages > 1)
                        Text(
                          ' • Página ${_currentPage + 1} de $totalPages',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  if (filteredUsers.isNotEmpty)
                    Row(
                      children: [
                        IconButton(
                          onPressed:
                              () => _showMessage(
                                'Lista completa em desenvolvimento...',
                                Colors.orange,
                              ),
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
                        itemCount: pagedUsers.length,
                        itemBuilder: (context, index) {
                          final doc = pagedUsers[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildOptimizedParticipanteCard(doc, data);
                        },
                      ),
            ),

            // Paginação melhorada
            if (filteredUsers.isNotEmpty && totalPages > 1)
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Primeira página
                    IconButton(
                      onPressed:
                          _currentPage > 0
                              ? () => setState(() => _currentPage = 0)
                              : null,
                      icon: const Icon(Icons.first_page),
                      tooltip: 'Primeira página',
                    ),

                    // Página anterior
                    IconButton(
                      onPressed:
                          _currentPage > 0
                              ? () => setState(() => _currentPage--)
                              : null,
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Página anterior',
                    ),

                    const SizedBox(width: 16),

                    // Indicador de página atual
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        '${_currentPage + 1} / $totalPages',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Próxima página
                    IconButton(
                      onPressed:
                          _currentPage < totalPages - 1
                              ? () => setState(() => _currentPage++)
                              : null,
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Próxima página',
                    ),

                    // Última página
                    IconButton(
                      onPressed:
                          _currentPage < totalPages - 1
                              ? () =>
                                  setState(() => _currentPage = totalPages - 1)
                              : null,
                      icon: const Icon(Icons.last_page),
                      tooltip: 'Última página',
                    ),
                  ],
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
          // Mostra passageiros se existirem
          final passageiros = veiculo['passageiros'] as List? ?? [];
          final passageiroCount = passageiros.length;

          return GestureDetector(
            onTap: () => _showPassageirosDialog(veiculo),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade300, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      veiculo['matricula'] ?? 'Veículo',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (passageiroCount > 1) ...[
                    const SizedBox(width: 2),
                    Icon(Icons.people, size: 10, color: Colors.blue.shade800),
                    Text(
                      '$passageiroCount',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
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
        _editarVeiculo(doc.id, data);
        break;
      case 'acompanhantes':
        _gerirAcompanhantes(doc.id, data);
        break;
      case 'equipa':
        _editarEquipa(doc.id, data);
        break;
      case 'detalhes':
        _verDetalhes(data);
        break;
      case 'qr':
        _showMessage('Funcionalidade em desenvolvimento...', Colors.orange);
        break;
      case 'eliminar':
        _eliminarParticipante(doc, data);
        break;
    }
  }

  // ============= MÉTODOS PARA DIÁLOGOS SEM BUILDCONTEXT ASYNC =============

  void _editarEquipa(String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => _EquipaDialog(
            userId: userId,
            userData: userData,
            onSuccess: (message) {
              if (mounted) {
                _showMessage(message, Colors.green);
              }
            },
            onError: (message) {
              if (mounted) {
                _showMessage(message, Colors.red);
              }
            },
          ),
    );
  }

  void _editarVeiculo(String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => _VeiculoDialog(
            userId: userId,
            userData: userData,
            onSuccess: (message) {
              if (mounted) {
                _showMessage(message, Colors.green);
              }
            },
            onError: (message) {
              if (mounted) {
                _showMessage(message, Colors.red);
              }
            },
          ),
    );
  }

  void _gerirAcompanhantes(String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => _AcompanhantesDialog(
            userId: userId,
            userData: userData,
            onSuccess: (message) {
              if (mounted) {
                _showMessage(message, Colors.green);
              }
            },
            onError: (message) {
              if (mounted) {
                _showMessage(message, Colors.red);
              }
            },
          ),
    );
  }

  void _showPassageirosDialog(Map<String, dynamic> veiculoData) {
    showDialog(
      context: context,
      builder: (dialogContext) => _PassageirosDialog(veiculoData: veiculoData),
    );
  }

  void _showBulkActions() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
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
                    Navigator.pop(dialogContext);
                    _showMessage(
                      'Funcionalidade em desenvolvimento...',
                      Colors.orange,
                    );
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
                    Navigator.pop(dialogContext);
                    _showMessage(
                      'Funcionalidade em desenvolvimento...',
                      Colors.orange,
                    );
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
                    Navigator.pop(dialogContext);
                    _showMessage(
                      'Funcionalidade em desenvolvimento...',
                      Colors.orange,
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Fechar',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
    );
  }

  void _verDetalhes(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
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
                onPressed: () => Navigator.pop(dialogContext),
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

  void _eliminarParticipante(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
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
                onPressed: () => Navigator.pop(dialogContext),
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

                    if (mounted) {
                      Navigator.of(context).pop();
                      _showMessage(
                        'Participante eliminado com sucesso!',
                        Colors.green,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      _showMessage(
                        'Erro ao eliminar participante: $e',
                        Colors.red,
                      );
                    }
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

  void _showMessage(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }
}

// ============= DIÁLOGO PARA ACOMPANHANTES/PASSAGEIROS =============
class _AcompanhantesDialog extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final Function(String) onSuccess;
  final Function(String) onError;

  const _AcompanhantesDialog({
    required this.userId,
    required this.userData,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_AcompanhantesDialog> createState() => _AcompanhantesDialogState();
}

class _AcompanhantesDialogState extends State<_AcompanhantesDialog> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  String _selectedTshirt = 'M';
  List<Map<String, dynamic>> _passageiros = [];
  Map<String, dynamic>? _veiculoData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPassageiros();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPassageiros() async {
    try {
      final veiculoId = widget.userData['veiculoId'];

      // Se não tem veículo, mostra apenas opção de adicionar acompanhantes sem veículo
      if (veiculoId == null || veiculoId.isEmpty) {
        // Carregar acompanhantes diretos do user (se houver)
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final acompanhantes = userData['acompanhantes'] as List? ?? [];

          _passageiros = [];
          for (var acompanhante in acompanhantes) {
            _passageiros.add({
              'id': null, // Não é um user real
              'nome': acompanhante['nome'] ?? 'Nome não informado',
              'telefone': acompanhante['telefone'] ?? '',
              'tshirt': acompanhante['tshirt'] ?? 'M',
              'isCondutor': false,
              'isOriginal': false, // Acompanhante direto
              'isAcompanhanteOnly': true, // Marca como acompanhante sem veículo
            });
          }
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Carregar dados do veículo
      final veiculoDoc =
          await FirebaseFirestore.instance
              .collection('veiculos')
              .doc(veiculoId)
              .get();

      if (!veiculoDoc.exists) {
        widget.onError('Veículo não encontrado');
        return;
      }

      _veiculoData = veiculoDoc.data() as Map<String, dynamic>;

      // Verificar se passageiros é um array de strings ou array de objetos
      final passageirosData = _veiculoData!['passageiros'];
      _passageiros = [];

      if (passageirosData is List) {
        for (var i = 0; i < passageirosData.length; i++) {
          final passageiroData = passageirosData[i];

          if (passageiroData is String) {
            // Passageiro é um ID de usuário - carregar dados do Firestore
            try {
              final userDoc =
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(passageiroData)
                      .get();

              if (userDoc.exists) {
                final userData = userDoc.data() as Map<String, dynamic>;
                _passageiros.add({
                  'id': passageiroData,
                  'nome': userData['nome'] ?? 'Nome não informado',
                  'telefone': userData['telefone'] ?? '',
                  'tshirt': userData['tshirt'] ?? 'M',
                  'isCondutor': passageiroData == _veiculoData!['ownerId'],
                  'isOriginal': true, // Passageiro já existente
                  'isAcompanhanteOnly': false,
                });
              }
            } catch (e) {
              // Se não conseguir carregar um passageiro específico, continua
            }
          } else if (passageiroData is Map) {
            // Passageiro é um objeto direto no array
            _passageiros.add({
              'id': null, // Não tem ID porque é objeto direto
              'nome': passageiroData['nome'] ?? 'Nome não informado',
              'telefone': passageiroData['telefone'] ?? '',
              'tshirt': passageiroData['tshirt'] ?? 'M',
              'isCondutor': i == 0, // Primeiro passageiro é sempre o condutor
              'isOriginal': true, // Passageiro já existente
              'isAcompanhanteOnly': false,
              'isDirectObject': true, // Marca como objeto direto
            });
          }
        }
      }
    } catch (e) {
      widget.onError('Erro ao carregar dados: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        backgroundColor: Colors.white,
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: Colors.white,
      title: Row(
        children: [
          const Icon(Icons.directions_car, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gerir Passageiros do Veículo',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _veiculoData?['matricula'] ?? 'Veículo',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          children: [
            // Formulário para adicionar passageiro
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adicionar Novo Passageiro',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nomeController,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _telefoneController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: 'Telefone',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedTshirt,
                        items:
                            ['XS', 'S', 'M', 'L', 'XL', 'XXL']
                                .map(
                                  (size) => DropdownMenuItem(
                                    value: size,
                                    child: Text(size),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTshirt = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _adicionarPassageiro,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lista de passageiros
            Expanded(
              child:
                  _passageiros.isEmpty
                      ? const Center(
                        child: Text(
                          'Nenhum passageiro no veículo',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _passageiros.length,
                        itemBuilder: (context, index) {
                          final passageiro = _passageiros[index];
                          final isCondutor = passageiro['isCondutor'] == true;
                          //final isOriginal = passageiro['isOriginal'] == true;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color:
                                isCondutor
                                    ? Colors.green.shade50
                                    : Colors.white,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isCondutor
                                        ? Colors.green.shade100
                                        : Colors.blue.shade100,
                                child: Text(
                                  (passageiro['nome'] ?? '?')[0].toUpperCase(),
                                  style: TextStyle(
                                    color:
                                        isCondutor
                                            ? Colors.green.shade800
                                            : Colors.blue.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      passageiro['nome'] ??
                                          'Nome não informado',
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  if (isCondutor)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Condutor',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                '${passageiro['telefone'] ?? 'Sem telefone'} • T-Shirt: ${passageiro['tshirt'] ?? 'N/A'}',
                                style: const TextStyle(color: Colors.black87),
                              ),
                              trailing:
                                  isCondutor
                                      ? null
                                      : IconButton(
                                        onPressed:
                                            () => _removerPassageiro(index),
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Remover passageiro',
                                      ),
                            ),
                          );
                        },
                      ),
            ),

            // Informação adicional
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'O condutor não pode ser removido. Novos passageiros serão registados como utilizadores temporários.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _salvarPassageiros,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  void _adicionarPassageiro() {
    if (_nomeController.text.trim().isEmpty) {
      widget.onError('Nome é obrigatório');
      return;
    }

    final hasVeiculo =
        widget.userData['veiculoId'] != null &&
        widget.userData['veiculoId'].toString().isNotEmpty;

    setState(() {
      _passageiros.add({
        'id': null, // Será criado ao salvar
        'nome': _nomeController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'tshirt': _selectedTshirt,
        'isCondutor': false,
        'isOriginal': false, // Novo passageiro/acompanhante
        'isAcompanhanteOnly': !hasVeiculo, // Se não tem veículo, é acompanhante
      });
      _nomeController.clear();
      _telefoneController.clear();
      _selectedTshirt = 'M';
    });
  }

  void _removerPassageiro(int index) {
    final passageiro = _passageiros[index];
    if (passageiro['isCondutor'] == true) {
      widget.onError('Não é possível remover o condutor');
      return;
    }

    setState(() {
      _passageiros.removeAt(index);
    });
  }

  Future<void> _salvarPassageiros() async {
    try {
      final veiculoId = widget.userData['veiculoId'];
      List<String> passageiroIds = [];

      // Processar cada passageiro
      for (var passageiro in _passageiros) {
        if (passageiro['isOriginal'] == true) {
          // Passageiro já existente, manter ID
          passageiroIds.add(passageiro['id']);
        } else {
          // Novo passageiro, criar utilizador temporário
          final novoUser = {
            'nome': passageiro['nome'],
            'telefone': passageiro['telefone'],
            'tshirt': passageiro['tshirt'],
            'email': '', // Email vazio para passageiros temporários
            'role': 'passageiro',
            'ativo': true,
            'veiculoId': veiculoId,
            'isTemporary': true, // Marcar como temporário
            'createdAt': FieldValue.serverTimestamp(),
          };

          final docRef = await FirebaseFirestore.instance
              .collection('users')
              .add(novoUser);

          passageiroIds.add(docRef.id);
        }
      }

      // Atualizar lista de passageiros no veículo
      await FirebaseFirestore.instance
          .collection('veiculos')
          .doc(veiculoId)
          .update({
            'passageiros': passageiroIds,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess(
          'Passageiros atualizados com sucesso! Total: ${passageiroIds.length}',
        );
      }
    } catch (e) {
      widget.onError('Erro ao salvar passageiros: $e');
    }
  }
}

// ============= DIÁLOGO PARA VISUALIZAR PASSAGEIROS =============
class _PassageirosDialog extends StatelessWidget {
  final Map<String, dynamic> veiculoData;

  const _PassageirosDialog({required this.veiculoData});

  @override
  Widget build(BuildContext context) {
    final passageiros = veiculoData['passageiros'] as List? ?? [];

    return AlertDialog(
      backgroundColor: Colors.white,
      title: Row(
        children: [
          const Icon(Icons.directions_car, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  veiculoData['matricula'] ?? 'Veículo',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  veiculoData['modelo'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Passageiros (${passageiros.length}):',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  passageiros.isEmpty
                      ? const Center(
                        child: Text(
                          'Nenhum passageiro registado',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        itemCount: passageiros.length,
                        itemBuilder: (context, index) {
                          final passageiroId = passageiros[index];
                          return FutureBuilder<DocumentSnapshot>(
                            future:
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(passageiroId)
                                    .get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const ListTile(
                                  leading: CircularProgressIndicator(),
                                  title: Text('Carregando...'),
                                );
                              }

                              if (!snapshot.data!.exists) {
                                return ListTile(
                                  leading: const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                  ),
                                  title: const Text(
                                    'Utilizador não encontrado',
                                  ),
                                  subtitle: Text('ID: $passageiroId'),
                                );
                              }

                              final userData =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      (userData['nome'] ?? '?')[0]
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.blue.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    userData['nome'] ?? 'Nome não informado',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  subtitle: Text(
                                    userData['telefone'] ?? 'Sem telefone',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                  trailing:
                                      index == 0
                                          ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Condutor',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                          : null,
                                ),
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar', style: TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }
}

// ============= DIÁLOGO SEPARADO PARA EQUIPA =============
class _EquipaDialog extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final Function(String) onSuccess;
  final Function(String) onError;

  const _EquipaDialog({
    required this.userId,
    required this.userData,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_EquipaDialog> createState() => _EquipaDialogState();
}

class _EquipaDialogState extends State<_EquipaDialog> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _hinoController = TextEditingController();
  String _selectedGrupo = 'A';
  bool _isLoading = true;
  bool _isEdit = false;
  String? _equipaId;
  Map<String, dynamic>? _equipaData;

  @override
  void initState() {
    super.initState();
    _loadEquipaData();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _hinoController.dispose();
    super.dispose();
  }

  Future<void> _loadEquipaData() async {
    final equipaId = widget.userData['equipaId'];
    if (equipaId != null && equipaId.isNotEmpty) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('equipas')
                .doc(equipaId)
                .get();

        if (doc.exists) {
          _equipaData = doc.data() as Map<String, dynamic>;
          _equipaId = equipaId;
          _isEdit = true;

          _nomeController.text = _equipaData?['nome'] ?? '';
          _hinoController.text = _equipaData?['hino'] ?? '';
          _selectedGrupo = _equipaData?['grupo'] ?? 'A';
        }
      } catch (e) {
        // Erro ao carregar, mas continua como criação
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        backgroundColor: Colors.white,
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        _isEdit ? 'Editar Equipa' : 'Criar Nova Equipa',
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
              TextField(
                controller: _nomeController,
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
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.groups, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _hinoController,
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
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.campaign, color: Colors.orange),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGrupo,
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
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
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
                  setState(() {
                    _selectedGrupo = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _salvarEquipa,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text(_isEdit ? 'Atualizar' : 'Criar'),
        ),
      ],
    );
  }

  Future<void> _salvarEquipa() async {
    if (_nomeController.text.trim().isEmpty) {
      widget.onError('O nome da equipa é obrigatório');
      return;
    }

    try {
      final equipaDataToSave = {
        'nome': _nomeController.text.trim(),
        'hino': _hinoController.text.trim(),
        'grupo': _selectedGrupo,
        'pontuacaoTotal': _equipaData?['pontuacaoTotal'] ?? 0,
        'ranking': _equipaData?['ranking'] ?? 1,
        'membros': _equipaData?['membros'] ?? [widget.userId],
        'bandeiraUrl': _equipaData?['bandeiraUrl'] ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      String finalEquipaId;

      if (_isEdit && _equipaId != null) {
        await FirebaseFirestore.instance
            .collection('equipas')
            .doc(_equipaId)
            .update(equipaDataToSave);
        finalEquipaId = _equipaId!;
      } else {
        equipaDataToSave['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await FirebaseFirestore.instance
            .collection('equipas')
            .add(equipaDataToSave);
        finalEquipaId = docRef.id;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'equipaId': finalEquipaId});

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess(
          _isEdit
              ? 'Equipa atualizada com sucesso!'
              : 'Equipa criada com sucesso!',
        );
      }
    } catch (e) {
      widget.onError('Erro ao ${_isEdit ? 'atualizar' : 'criar'} equipa: $e');
    }
  }
}

// ============= DIÁLOGO SEPARADO PARA VEÍCULO =============
class _VeiculoDialog extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final Function(String) onSuccess;
  final Function(String) onError;

  const _VeiculoDialog({
    required this.userId,
    required this.userData,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_VeiculoDialog> createState() => _VeiculoDialogState();
}

class _VeiculoDialogState extends State<_VeiculoDialog> {
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _disticoController = TextEditingController();
  bool _isLoading = true;
  bool _isEdit = false;
  String? _veiculoId;
  Map<String, dynamic>? _veiculoData;

  @override
  void initState() {
    super.initState();
    _loadVeiculoData();
  }

  @override
  void dispose() {
    _matriculaController.dispose();
    _modeloController.dispose();
    _disticoController.dispose();
    super.dispose();
  }

  Future<void> _loadVeiculoData() async {
    final veiculoId = widget.userData['veiculoId'];
    if (veiculoId != null && veiculoId.isNotEmpty) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('veiculos')
                .doc(veiculoId)
                .get();

        if (doc.exists) {
          _veiculoData = doc.data() as Map<String, dynamic>;
          _veiculoId = veiculoId;
          _isEdit = true;

          _matriculaController.text = _veiculoData?['matricula'] ?? '';
          _modeloController.text = _veiculoData?['modelo'] ?? '';
          _disticoController.text = _veiculoData?['distico'] ?? '';
        }
      } catch (e) {
        // Erro ao carregar, mas continua como criação
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        backgroundColor: Colors.white,
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        _isEdit ? 'Editar Veículo' : 'Registar Novo Veículo',
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
              TextField(
                controller: _matriculaController,
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
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  prefixIcon: const Icon(
                    Icons.directions_car,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _modeloController,
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
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.car_repair, color: Colors.green),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _disticoController,
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
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.qr_code, color: Colors.orange),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 20),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _salvarVeiculo,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: Text(_isEdit ? 'Atualizar' : 'Registar'),
        ),
      ],
    );
  }

  Future<void> _salvarVeiculo() async {
    if (_matriculaController.text.trim().isEmpty) {
      widget.onError('A matrícula é obrigatória');
      return;
    }

    try {
      String nomeEquipa = '';
      if (widget.userData['equipaId'] != null &&
          widget.userData['equipaId'].toString().isNotEmpty) {
        final equipaDoc =
            await FirebaseFirestore.instance
                .collection('equipas')
                .doc(widget.userData['equipaId'])
                .get();
        if (equipaDoc.exists) {
          final equipaData = equipaDoc.data() as Map<String, dynamic>;
          nomeEquipa = equipaData['nome'] ?? '';
        }
      }

      final veiculoDataToSave = {
        'matricula': _matriculaController.text.trim().toUpperCase(),
        'modelo': _modeloController.text.trim(),
        'distico': _disticoController.text.trim(),
        'ownerId': widget.userId,
        'nome_equipa': nomeEquipa,
        'passageiros': _veiculoData?['passageiros'] ?? [widget.userId],
        'checkpointId': _veiculoData?['checkpointId'] ?? [],
        'pontuacao_total': _veiculoData?['pontuacao_total'] ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      String finalVeiculoId;

      if (_isEdit && _veiculoId != null) {
        await FirebaseFirestore.instance
            .collection('veiculos')
            .doc(_veiculoId)
            .update(veiculoDataToSave);
        finalVeiculoId = _veiculoId!;
      } else {
        veiculoDataToSave['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await FirebaseFirestore.instance
            .collection('veiculos')
            .add(veiculoDataToSave);
        finalVeiculoId = docRef.id;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'veiculoId': finalVeiculoId});

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess(
          _isEdit
              ? 'Veículo atualizado com sucesso!'
              : 'Veículo registado com sucesso!',
        );
      }
    } catch (e) {
      widget.onError(
        'Erro ao ${_isEdit ? 'atualizar' : 'registar'} veículo: $e',
      );
    }
  }
}
