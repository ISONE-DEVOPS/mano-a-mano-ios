import 'package:flutter/material.dart';
import 'edit_participantes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      backgroundColor: const Color(0xFFF8F9FA), // Fundo mais neutro
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
            color: Colors.grey.withAlpha((0.15 * 255).round()),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
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
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A), // Preto mais suave
                ),
              ),
              const SizedBox(width: 16),

              // Pesquisa compacta
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                        _currentPage = 0;
                      });
                    },
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Pesquisar participantes...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFF3B82F6),
                          width: 2,
                        ),
                      ),
                      fillColor: const Color(0xFFF9FAFB),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Botão de filtros
              Container(
                decoration: BoxDecoration(
                  color:
                      _isFilterExpanded
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        _isFilterExpanded
                            ? const Color(0xFF3B82F6)
                            : Colors.grey.shade300,
                  ),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _isFilterExpanded = !_isFilterExpanded;
                    });
                  },
                  icon: Icon(
                    _isFilterExpanded
                        ? Icons.filter_list_off
                        : Icons.filter_list,
                    color:
                        _isFilterExpanded
                            ? Colors.white
                            : const Color(0xFF374151),
                    size: 20,
                  ),
                  tooltip: 'Filtros',
                ),
              ),

              // Botões principais compactos
              const SizedBox(width: 12),
              _buildCompactButton(
                Icons.person_add,
                'Novo',
                const Color(0xFF10B981),
                Colors.white,
                () => Navigator.of(context).pushNamed('/register-participant'),
              ),
              const SizedBox(width: 8),
              _buildCompactButton(
                Icons.download,
                'CSV',
                const Color(0xFF3B82F6),
                Colors.white,
                () => _showMessage(
                  'Exportação em desenvolvimento...',
                  const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8),
              _buildCompactButton(
                Icons.more_horiz,
                'Mais',
                const Color(0xFF8B5CF6),
                Colors.white,
                _showBulkActions,
              ),
            ],
          ),

          // Filtros expansíveis
          if (_isFilterExpanded) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                        _currentPage = 0;
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCompactDropdown(
                      'T-Shirt',
                      _filterTshirt,
                      ['Todos', 'XS', 'S', 'M', 'L', 'XL', 'XXL'],
                      (value) => setState(() {
                        _filterTshirt = value!;
                        _currentPage = 0;
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCompactDropdown(
                      'Grupo',
                      _filterGrupo,
                      ['Todos', 'A', 'B'],
                      (value) => setState(() {
                        _filterGrupo = value!;
                        _currentPage = 0;
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
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: textColor),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(0, 40),
        elevation: 2,
        shadowColor: Colors.black.withAlpha((0.1 * 255).round()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      height: 40,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
          isDense: true,
          fillColor: Colors.white,
          filled: true,
        ),
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
        dropdownColor: Colors.white,
        items:
            items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  displayMap?[item] ?? item,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              );
            }).toList(),
        onChanged: onChanged,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
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
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Color(0xFF9CA3AF)),
                SizedBox(height: 16),
                Text(
                  'Nenhum participante encontrado',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Adicione o primeiro participante para começar',
                  style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF3B82F6)),
                        ),
                        child: Text(
                          '${filteredUsers.length} participante(s)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                      if (filteredUsers.isNotEmpty && totalPages > 1) ...[
                        const SizedBox(width: 12),
                        Text(
                          'Página ${_currentPage + 1} de $totalPages',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (filteredUsers.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed:
                            () => _showMessage(
                              'Lista completa em desenvolvimento...',
                              const Color(0xFFF59E0B),
                            ),
                        icon: const Icon(
                          Icons.groups,
                          size: 20,
                          color: Color(0xFF374151),
                        ),
                        tooltip: 'Lista Completa',
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Lista otimizada
            Expanded(
              child:
                  filteredUsers.isEmpty
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Color(0xFF9CA3AF),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum participante corresponde aos filtros',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tente ajustar os filtros de pesquisa',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Primeira página
                    _buildPaginationButton(
                      Icons.first_page,
                      'Primeira página',
                      _currentPage > 0,
                      () => setState(() => _currentPage = 0),
                    ),

                    const SizedBox(width: 8),

                    // Página anterior
                    _buildPaginationButton(
                      Icons.chevron_left,
                      'Página anterior',
                      _currentPage > 0,
                      () => setState(() => _currentPage--),
                    ),

                    const SizedBox(width: 16),

                    // Indicador de página atual
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF3B82F6,
                            ).withAlpha((0.3 * 255).round()),
                            spreadRadius: 0,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${_currentPage + 1} / $totalPages',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Próxima página
                    _buildPaginationButton(
                      Icons.chevron_right,
                      'Próxima página',
                      _currentPage < totalPages - 1,
                      () => setState(() => _currentPage++),
                    ),

                    const SizedBox(width: 8),

                    // Última página
                    _buildPaginationButton(
                      Icons.last_page,
                      'Última página',
                      _currentPage < totalPages - 1,
                      () => setState(() => _currentPage = totalPages - 1),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPaginationButton(
    IconData icon,
    String tooltip,
    bool enabled,
    VoidCallback? onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF3F4F6) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? const Color(0xFFD1D5DB) : const Color(0xFFE5E7EB),
        ),
      ),
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(
          icon,
          color: enabled ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
          size: 20,
        ),
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }

  Widget _buildOptimizedParticipanteCard(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar compacto
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF3B82F6),
              child: Text(
                (data['nome'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),

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
                            color: Color(0xFF1A1A1A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildCompactRoleBadge(data['role'] ?? 'user'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['email'] ?? 'Email não informado',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
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
                      const Icon(
                        Icons.phone,
                        size: 14,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          data['telefone'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_offer,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'T-Shirt: ${data['tshirt'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF374151),
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
                        const SizedBox(height: 6),
                        _buildCompactVeiculoChip(data),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Menu de ações compacto
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: PopupMenuButton<String>(
                      onSelected: (value) => _handleAction(value, doc, data),
                      icon: const Icon(
                        Icons.more_vert,
                        size: 20,
                        color: Color(0xFF374151),
                      ),
                      iconSize: 20,
                      color: Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder:
                          (context) => [
                            _buildCompactMenuItem(
                              Icons.edit,
                              'Editar',
                              'editar',
                              const Color(0xFFF59E0B),
                            ),
                            _buildCompactMenuItem(
                              Icons.directions_car,
                              'Veículo',
                              'veiculo',
                              const Color(0xFF10B981),
                            ),
                            _buildCompactMenuItem(
                              Icons.group,
                              'Acompanhantes',
                              'acompanhantes',
                              const Color(0xFF3B82F6),
                            ),
                            _buildCompactMenuItem(
                              Icons.groups,
                              'Equipa',
                              'equipa',
                              const Color(0xFF8B5CF6),
                            ),
                            _buildCompactMenuItem(
                              Icons.info,
                              'Detalhes',
                              'detalhes',
                              const Color(0xFF6366F1),
                            ),
                            _buildCompactMenuItem(
                              Icons.qr_code,
                              'QR Code',
                              'qr',
                              const Color(0xFF0891B2),
                            ),
                            const PopupMenuDivider(),
                            _buildCompactMenuItem(
                              Icons.delete,
                              'Eliminar',
                              'eliminar',
                              const Color(0xFFEF4444),
                            ),
                          ],
                    ),
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
      height: 44,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w500,
            ),
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
        backgroundColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFDC2626);
        label = 'Admin';
        break;
      case 'staff':
        backgroundColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFEA580C);
        label = 'Staff';
        break;
      default:
        backgroundColor = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF2563EB);
        label = 'User';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withAlpha((0.3 * 255).round()),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF10B981), width: 1),
            ),
            child: Text(
              '${equipa['nome'] ?? 'Equipa'} (${equipa['grupo'] ?? '?'})',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF059669),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFEF4444), width: 1),
          ),
          child: const Text(
            'Sem equipa',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFFDC2626),
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
          final passageiros = veiculo['passageiros'] as List? ?? [];
          final passageiroCount = passageiros.length;

          return GestureDetector(
            onTap: () => _showPassageirosDialog(veiculo),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF3B82F6), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      veiculo['matricula'] ?? 'Veículo',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (passageiroCount > 1) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.people,
                      size: 12,
                      color: Color(0xFF1D4ED8),
                    ),
                    Text(
                      '$passageiroCount',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF1D4ED8),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFEF4444), width: 1),
          ),
          child: const Text(
            'Sem veículo',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFFDC2626),
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
        _showMessage(
          'Funcionalidade em desenvolvimento...',
          const Color(0xFFF59E0B),
        );
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
                _showMessage(message, const Color(0xFF10B981));
              }
            },
            onError: (message) {
              if (mounted) {
                _showMessage(message, const Color(0xFFEF4444));
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
                _showMessage(message, const Color(0xFF10B981));
              }
            },
            onError: (message) {
              if (mounted) {
                _showMessage(message, const Color(0xFFEF4444));
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
                _showMessage(message, const Color(0xFF10B981));
              }
            },
            onError: (message) {
              if (mounted) {
                _showMessage(message, const Color(0xFFEF4444));
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Ações em Lote',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBulkActionTile(
                  Icons.groups,
                  'Criar Equipas Automáticas',
                  'Organizar participantes em equipas',
                  const Color(0xFF8B5CF6),
                  () {
                    Navigator.pop(dialogContext);
                    _showMessage(
                      'Funcionalidade em desenvolvimento...',
                      const Color(0xFFF59E0B),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildBulkActionTile(
                  Icons.qr_code,
                  'Gerar QR Codes',
                  'Para todos os participantes',
                  const Color(0xFF3B82F6),
                  () {
                    Navigator.pop(dialogContext);
                    _showMessage(
                      'Funcionalidade em desenvolvimento...',
                      const Color(0xFFF59E0B),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildBulkActionTile(
                  Icons.email,
                  'Enviar Convites',
                  'Para participantes sem equipas',
                  const Color(0xFF10B981),
                  () {
                    Navigator.pop(dialogContext);
                    _showMessage(
                      'Funcionalidade em desenvolvimento...',
                      const Color(0xFFF59E0B),
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
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildBulkActionTile(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha((0.05 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((0.2 * 255).round())),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _verDetalhes(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Detalhes do Participante',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.bold,
                fontSize: 20,
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
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
            ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Confirmar Eliminação',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: Text(
              'Tem certeza que deseja eliminar o participante "${data['nome']}"?\n\nEsta ação não pode ser desfeita.',
              style: const TextStyle(color: Color(0xFF374151), fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
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
                        const Color(0xFF10B981),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      _showMessage(
                        'Erro ao eliminar participante: $e',
                        const Color(0xFFEF4444),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  void _showMessage(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
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
      final ownerId = _veiculoData!['ownerId']; // ID do condutor/proprietário

      // Carregar dados do condutor primeiro
      Map<String, dynamic>? condutorData;
      if (ownerId != null) {
        try {
          final condutorDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(ownerId)
                  .get();

          if (condutorDoc.exists) {
            condutorData = condutorDoc.data() as Map<String, dynamic>;
          }
        } catch (e) {
          // Se não conseguir carregar o condutor, continua
        }
      }

      // Processar array de passageiros (pode conter IDs e objetos)
      final passageirosData = _veiculoData!['passageiros'] as List? ?? [];
      _passageiros = [];

      // Sempre adicionar o condutor primeiro (se existir)
      if (condutorData != null) {
        _passageiros.add({
          'id': ownerId,
          'nome': condutorData['nome'] ?? 'Nome não informado',
          'telefone': condutorData['telefone'] ?? '',
          'tshirt': condutorData['tshirt'] ?? 'M',
          'isCondutor': true,
          'isOriginal': true,
          'isAcompanhanteOnly': false,
        });
      }

      // Processar lista de passageiros
      for (var passageiroData in passageirosData) {
        if (passageiroData is String) {
          // Passageiro é um ID de usuário - pular se for o condutor (já adicionado)
          if (passageiroData == ownerId) continue;

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
                'isCondutor': false,
                'isOriginal': true, // Utilizador real existente
                'isAcompanhanteOnly': false,
              });
            }
          } catch (e) {
            // Se não conseguir carregar um passageiro específico, continua
          }
        } else if (passageiroData is Map<String, dynamic>) {
          // Passageiro é um objeto direto (acompanhante)
          // Verificar se é o condutor comparando dados
          final isCondutorObject =
              condutorData != null &&
              passageiroData['nome'] == condutorData['nome'] &&
              passageiroData['telefone'] == condutorData['telefone'];

          // Se é o condutor, pular porque já foi adicionado
          if (isCondutorObject) continue;

          _passageiros.add({
            'id': null, // Não tem ID porque é acompanhante
            'nome': passageiroData['nome'] ?? 'Nome não informado',
            'telefone': passageiroData['telefone'] ?? '',
            'tshirt': passageiroData['tshirt'] ?? 'M',
            'isCondutor': false,
            'isOriginal': true, // Acompanhante já existente
            'isAcompanhanteOnly': false,
            'isDirectObject': true, // Marca como acompanhante direto
            'isAcompanhante': passageiroData['isAcompanhante'] ?? true,
          });
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
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.directions_car,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gerir Passageiros do Veículo',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  _veiculoData?['matricula'] ?? 'Veículo',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 700,
        child: Column(
          children: [
            // Formulário para adicionar passageiro
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withAlpha((0.2 * 255).round()),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adicionar Novo Passageiro',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nomeController,
                    style: const TextStyle(color: Color(0xFF1A1A1A)),
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      labelStyle: TextStyle(color: Color(0xFF374151)),
                      prefixIcon: Icon(Icons.person, color: Color(0xFF3B82F6)),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _telefoneController,
                          style: const TextStyle(color: Color(0xFF1A1A1A)),
                          decoration: const InputDecoration(
                            labelText: 'Telefone',
                            labelStyle: TextStyle(color: Color(0xFF374151)),
                            prefixIcon: Icon(
                              Icons.phone,
                              color: Color(0xFF10B981),
                            ),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedTshirt,
                          style: const TextStyle(color: Color(0xFF1A1A1A)),
                          decoration: const InputDecoration(
                            labelText: 'T-Shirt',
                            labelStyle: TextStyle(color: Color(0xFF374151)),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _adicionarPassageiro,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Adicionar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lista de passageiros
            Expanded(
              child:
                  _passageiros.isEmpty
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Color(0xFF9CA3AF),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum passageiro no veículo',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: _passageiros.length,
                        itemBuilder: (context, index) {
                          final passageiro = _passageiros[index];
                          final isCondutor = passageiro['isCondutor'] == true;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color:
                                  isCondutor
                                      ? const Color(0xFFF0FDF4)
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isCondutor
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isCondutor
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF3B82F6),
                                child: Text(
                                  (passageiro['nome'] ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
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
                                        color: Color(0xFF1A1A1A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (isCondutor)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Condutor',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                '${passageiro['telefone'] ?? 'Sem telefone'} • T-Shirt: ${passageiro['tshirt'] ?? 'N/A'}',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              trailing:
                                  isCondutor
                                      ? null
                                      : IconButton(
                                        onPressed:
                                            () => _removerPassageiro(index),
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: Color(0xFFEF4444),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withAlpha((0.3 * 255).round()),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Color(0xFFEA580C), size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'O condutor não pode ser removido. Novos passageiros serão registados como utilizadores temporários.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFEA580C)),
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
          child: const Text(
            'Fechar',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _salvarPassageiros,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Salvar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
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

      // Separar passageiros por tipo
      List<String> passageiroIds = [];
      List<Map<String, dynamic>> passageirosAcompanhantes = [];

      // Processar cada passageiro
      for (var passageiro in _passageiros) {
        if (passageiro['isOriginal'] == true && passageiro['id'] != null) {
          // Passageiro já existente (utilizador real), manter ID
          passageiroIds.add(passageiro['id']);
        } else if (passageiro['isCondutor'] == true) {
          // Condutor sempre vai como ID na lista
          passageiroIds.add(passageiro['id']);
        } else {
          // Novo acompanhante - adicionar como objeto direto no array
          passageirosAcompanhantes.add({
            'nome': passageiro['nome'],
            'telefone': passageiro['telefone'],
            'tshirt': passageiro['tshirt'],
            'isAcompanhante': true, // Marca como acompanhante
          });
        }
      }

      // Combinar IDs de utilizadores reais com objetos de acompanhantes
      List<dynamic> passageirosFinal = [];

      // Adicionar utilizadores reais (IDs)
      passageirosFinal.addAll(passageiroIds);

      // Adicionar acompanhantes (objetos)
      passageirosFinal.addAll(passageirosAcompanhantes);

      // Atualizar lista de passageiros no veículo
      await FirebaseFirestore.instance
          .collection('veiculos')
          .doc(veiculoId)
          .update({
            'passageiros': passageirosFinal,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess(
          'Passageiros atualizados com sucesso! Total: ${passageirosFinal.length} (${passageiroIds.length} utilizadores + ${passageirosAcompanhantes.length} acompanhantes)',
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.directions_car,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  veiculoData['matricula'] ?? 'Veículo',
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  veiculoData['modelo'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withAlpha((0.3 * 255).round()),
                ),
              ),
              child: Text(
                'Passageiros e Acompanhantes (${passageiros.length}):',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E40AF),
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  passageiros.isEmpty
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Color(0xFF9CA3AF),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum passageiro registado',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: passageiros.length,
                        itemBuilder: (context, index) {
                          final passageiroData = passageiros[index];

                          // Se é um ID (string), buscar dados do utilizador
                          if (passageiroData is String) {
                            return FutureBuilder<DocumentSnapshot>(
                              future:
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(passageiroData)
                                      .get(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const ListTile(
                                      leading: CircularProgressIndicator(),
                                      title: Text('Carregando...'),
                                    ),
                                  );
                                }

                                if (!snapshot.data!.exists) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFEF4444,
                                        ).withAlpha((0.3 * 255).round()),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.error,
                                        color: Color(0xFFEF4444),
                                      ),
                                      title: const Text(
                                        'Utilizador não encontrado',
                                        style: TextStyle(
                                          color: Color(0xFF1A1A1A),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'ID: $passageiroData',
                                        style: const TextStyle(
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final userData =
                                    snapshot.data!.data()
                                        as Map<String, dynamic>;
                                final isCondutor =
                                    index == 0; // Primeiro sempre é condutor

                                return _buildPassageiroCard(
                                  userData,
                                  isCondutor,
                                  'Utilizador',
                                );
                              },
                            );
                          }
                          // Se é um objeto (Map), é um acompanhante direto
                          else if (passageiroData is Map<String, dynamic>) {
                            return _buildPassageiroCard(
                              passageiroData,
                              false,
                              'Acompanhante',
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Fechar',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPassageiroCard(
    Map<String, dynamic> userData,
    bool isCondutor,
    String tipo,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            isCondutor
                ? const Color(0xFFF0FDF4)
                : tipo == 'Acompanhante'
                ? const Color(0xFFFFF7ED)
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isCondutor
                  ? const Color(0xFF10B981)
                  : tipo == 'Acompanhante'
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFE5E7EB),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isCondutor
                  ? const Color(0xFF10B981)
                  : tipo == 'Acompanhante'
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF3B82F6),
          child: Text(
            (userData['nome'] ?? '?')[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                userData['nome'] ?? 'Nome não informado',
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isCondutor)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Condutor',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (tipo == 'Acompanhante')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Acompanhante',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${userData['telefone'] ?? 'Sem telefone'} • T-Shirt: ${userData['tshirt'] ?? 'N/A'}',
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
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
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _isEdit ? 'Editar Equipa' : 'Criar Nova Equipa',
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomeController,
                style: const TextStyle(color: Color(0xFF1A1A1A)),
                decoration: InputDecoration(
                  labelText: 'Nome da Equipa',
                  labelStyle: const TextStyle(color: Color(0xFF374151)),
                  hintText: 'Digite o nome da equipa',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(
                    Icons.groups,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _hinoController,
                style: const TextStyle(color: Color(0xFF1A1A1A)),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Hino/Grito de Guerra',
                  labelStyle: const TextStyle(color: Color(0xFF374151)),
                  hintText: 'Digite o grito de guerra da equipa',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(
                    Icons.campaign,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGrupo,
                style: const TextStyle(color: Color(0xFF1A1A1A)),
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'Grupo',
                  labelStyle: const TextStyle(color: Color(0xFF374151)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.flag, color: Color(0xFF10B981)),
                ),
                items:
                    ['A', 'B'].map((grupo) {
                      return DropdownMenuItem(
                        value: grupo,
                        child: Text(
                          'Grupo $grupo',
                          style: const TextStyle(color: Color(0xFF1A1A1A)),
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
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _salvarEquipa,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            _isEdit ? 'Atualizar' : 'Criar',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
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
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _isEdit ? 'Editar Veículo' : 'Registar Novo Veículo',
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _matriculaController,
                style: const TextStyle(color: Color(0xFF1A1A1A)),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Matrícula',
                  labelStyle: const TextStyle(color: Color(0xFF374151)),
                  hintText: 'Ex: AA-123-BB',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(
                    Icons.directions_car,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _modeloController,
                style: const TextStyle(color: Color(0xFF1A1A1A)),
                decoration: InputDecoration(
                  labelText: 'Modelo do Veículo',
                  labelStyle: const TextStyle(color: Color(0xFF374151)),
                  hintText: 'Ex: Toyota Corolla',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(
                    Icons.car_repair,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _disticoController,
                style: const TextStyle(color: Color(0xFF1A1A1A)),
                decoration: InputDecoration(
                  labelText: 'Dístico (Código)',
                  labelStyle: const TextStyle(color: Color(0xFF374151)),
                  hintText: 'Código único do veículo',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(
                    Icons.qr_code,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(
                      0xFF3B82F6,
                    ).withAlpha((0.3 * 255).round()),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Color(0xFF1E40AF), size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'O condutor atual será definido como proprietário do veículo.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E40AF),
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
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _salvarVeiculo,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            _isEdit ? 'Atualizar' : 'Registar',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
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
