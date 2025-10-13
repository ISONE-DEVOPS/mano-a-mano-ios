import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:typed_data';

class ManageUsersView extends StatefulWidget {
  const ManageUsersView({super.key});

  @override
  State<ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends State<ManageUsersView> {
  void _showResetPasswordDialog(BuildContext context, String? email) async {
    if (email == null || email.isEmpty) {
      _toast('Email do utilizador não encontrado.', isError: true);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Resetar Senha'),
            content: Text(
              'Enviar email de redefinição de senha para "$email"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Enviar'),
              ),
            ],
          ),
    );

    if (ok == true) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        _toast('Email de redefinição de senha enviado para $email');
      } catch (e) {
        _toast('Erro ao enviar email: $e', isError: true);
      }
    }
  }

  final _searchCtrl = TextEditingController();
  String _filter = '';
  String _roleFilter = 'all';
  String _statusFilter = 'all';
  bool _isGridView = false;

  // Bulk Selection
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  static const Map<String, String> roleLabels = {
    'user': 'Participante',
    'staff': 'Staff',
    'admin': 'Admin',
  };
  static const List<String> roleOrder = ['user', 'staff', 'admin'];
  static const Map<String, Color> roleColors = {
    'user': Color(0xFF1976D2),
    'staff': Color(0xFF00897B),
    'admin': Color(0xFFD32F2F),
  };
  static const Map<String, IconData> roleIcons = {
    'user': Icons.person_outline,
    'staff': Icons.badge_outlined,
    'admin': Icons.verified_user_outlined,
  };

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _filter = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSelectionMode) {
          _toggleSelectionMode();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar:
            _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
        body: Column(
          children: [
            // Stats Cards
            if (!_isSelectionMode) _buildStatsCards(),

            // Search Bar
            if (!_isSelectionMode) _buildSearchBar(),

            const SizedBox(height: 12),

            // Lista de Utilizadores com StreamBuilder
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .orderBy('nome')
                        .snapshots(),
                builder: (context, snapshot) {
                  // Loading
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  // Error
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }

                  // Sem dados
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState(true);
                  }

                  // Filtrar dados
                  final allDocs = snapshot.data!.docs;
                  final filtered = _filterUsers(allDocs);

                  // Sem resultados após filtros
                  if (filtered.isEmpty) {
                    return _buildEmptyState(false);
                  }

                  // Renderizar lista ou grid
                  return _isGridView
                      ? _buildGridView(filtered)
                      : _buildListView(filtered);
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _isSelectionMode ? null : _buildFAB(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🎨 APP BARS
  // ═══════════════════════════════════════════════════════════
  AppBar _buildNormalAppBar() {
    return AppBar(
      title: const Text('Gestão de Utilizadores'),
      actions: [
        IconButton(
          icon: const Icon(Icons.check_box_outlined),
          tooltip: 'Modo Seleção',
          onPressed: _toggleSelectionMode,
        ),
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          tooltip: _isGridView ? 'Vista em Lista' : 'Vista em Grelha',
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined),
          tooltip: 'Exportar CSV',
          onPressed: _exportToCSV,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _toggleSelectionMode,
      ),
      title: Text('${_selectedIds.length} selecionados'),
      actions: [
        if (_selectedIds.isNotEmpty) ...[
          PopupMenuButton<String>(
            tooltip: 'Ações em Lote',
            onSelected: (value) {
              if (value == 'delete') {
                _bulkDelete();
              } else if (value == 'activate') {
                _bulkActivate(true);
              } else if (value == 'deactivate') {
                _bulkActivate(false);
              } else if (value == 'change_role') {
                _bulkChangeRole();
              }
            },
            itemBuilder:
                (ctx) => [
                  const PopupMenuItem(
                    value: 'activate',
                    child: ListTile(
                      leading: Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      title: Text('Ativar'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: ListTile(
                      leading: Icon(Icons.block, color: Colors.orange),
                      title: Text('Desativar'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'change_role',
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz, color: Colors.blue),
                      title: Text('Alterar papel'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text('Apagar'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
          ),
        ],
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snap) {
            final total = snap.data?.docs.length ?? 0;
            return TextButton(
              onPressed: () {
                if (_selectedIds.isEmpty) {
                  _selectAll(snap.data?.docs ?? []);
                } else {
                  _deselectAll();
                }
              },
              child: Text(_selectedIds.isEmpty ? 'Todos ($total)' : 'Limpar'),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showCreateUserDialog,
      icon: const Icon(Icons.person_add),
      label: const Text('Novo Utilizador'),
      backgroundColor: Colors.orange,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 📊 STATS CARDS
  // ═══════════════════════════════════════════════════════════
  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final docs = snap.data!.docs;
          final total = docs.length;
          final ativos =
              docs.where((d) => (d.data() as Map)['ativo'] == true).length;
          final participantes =
              docs.where((d) => (d.data() as Map)['role'] == 'user').length;
          final staff =
              docs.where((d) => (d.data() as Map)['role'] == 'staff').length;

          return Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.people,
                  title: 'Total',
                  value: total.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle,
                  title: 'Ativos',
                  value: ativos.toString(),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.person_outline,
                  title: 'Participantes',
                  value: participantes.toString(),
                  color: roleColors['user']!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.badge_outlined,
                  title: 'Staff',
                  value: staff.toString(),
                  color: roleColors['staff']!,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🔍 SEARCH BAR
  // ═══════════════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.black), // ✅ FORÇAR COR
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome ou email…',
                hintStyle: TextStyle(color: Colors.grey[600]), // ✅ FORÇAR COR
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.black54,
                ), // ✅ FORÇAR COR
                suffixIcon:
                    _filter.isNotEmpty
                        ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.black54,
                          ), // ✅ FORÇAR COR
                          onPressed: () => _searchCtrl.clear(),
                        )
                        : null,
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Badge(
            isLabelVisible: _roleFilter != 'all' || _statusFilter != 'all',
            child: OutlinedButton.icon(
              onPressed: _showFilterBottomSheet,
              icon: const Icon(
                Icons.filter_list,
                color: Colors.black87,
              ), // ✅ FORÇAR COR
              label: const Text(
                'Filtros',
                style: TextStyle(color: Colors.black87),
              ), // ✅ FORÇAR COR
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Colors.black26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 📋 LIST VIEW
  // ═══════════════════════════════════════════════════════════
  Widget _buildListView(List<QueryDocumentSnapshot> users) {
    return Container(
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final doc = users[index];
          final data = doc.data() as Map<String, dynamic>;
          final isSelected = _selectedIds.contains(doc.id);

          return _UserCard(
            doc: doc,
            data: data,
            isSelectionMode: _isSelectionMode,
            isSelected: isSelected,
            onTap: _isSelectionMode ? () => _toggleSelection(doc.id) : null,
            onLongPress: () {
              if (!_isSelectionMode) {
                _toggleSelectionMode();
                _toggleSelection(doc.id);
              }
            },
            onEdit: () => _showEditUserDialog(doc, data),
            onDelete: () => _confirmDelete(context, doc),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🎨 GRID VIEW
  // ═══════════════════════════════════════════════════════════
  Widget _buildGridView(List<QueryDocumentSnapshot> users) {
    return Container(
      color: Colors.white,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 350,
          childAspectRatio: 1.4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final doc = users[index];
          final data = doc.data() as Map<String, dynamic>;
          final isSelected = _selectedIds.contains(doc.id);

          return _UserGridCard(
            doc: doc,
            data: data,
            isSelectionMode: _isSelectionMode,
            isSelected: isSelected,
            onTap:
                _isSelectionMode
                    ? () => _toggleSelection(doc.id)
                    : () => _showEditUserDialog(doc, data),
            onLongPress: () {
              if (!_isSelectionMode) {
                _toggleSelectionMode();
                _toggleSelection(doc.id);
              }
            },
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🎭 ESTADOS ESPECIAIS
  // ═══════════════════════════════════════════════════════════
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'A carregar utilizadores...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isNoData) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNoData ? Icons.people_outline : Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isNoData
                  ? 'Nenhum utilizador cadastrado'
                  : 'Nenhum resultado encontrado',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isNoData
                  ? 'Clique no botão abaixo para criar o primeiro utilizador'
                  : 'Tente ajustar os filtros de pesquisa',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (!isNoData) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {
                    _roleFilter = 'all';
                    _statusFilter = 'all';
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Limpar Filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar dados',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🔧 FUNÇÕES AUXILIARES
  // ═══════════════════════════════════════════════════════════
  List<QueryDocumentSnapshot> _filterUsers(List<QueryDocumentSnapshot> docs) {
    return docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      final nome = (data['nome'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final role = (data['role'] ?? 'user').toString();
      final ativo = (data['ativo'] ?? true) == true;

      final matchesText =
          _filter.isEmpty || nome.contains(_filter) || email.contains(_filter);
      final matchesRole = _roleFilter == 'all' || role == _roleFilter;
      final matchesStatus =
          _statusFilter == 'all' ||
          (_statusFilter == 'active' && ativo) ||
          (_statusFilter == 'inactive' && !ativo);

      return matchesText && matchesRole && matchesStatus;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ BULK ACTIONS
  // ═══════════════════════════════════════════════════════════
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<QueryDocumentSnapshot> docs) {
    setState(() {
      final filtered = _filterUsers(docs);
      for (final doc in filtered) {
        _selectedIds.add(doc.id);
      }
    });
  }

  void _deselectAll() => setState(() => _selectedIds.clear());

  Future<void> _bulkDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Apagar em Lote'),
            content: Text(
              'Confirmar remoção de ${_selectedIds.length} utilizadores?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Apagar'),
              ),
            ],
          ),
    );

    if (ok != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedIds) {
        batch.delete(FirebaseFirestore.instance.collection('users').doc(id));
      }
      await batch.commit();
      _toast('${_selectedIds.length} utilizadores apagados.');
      _toggleSelectionMode();
    } catch (e) {
      _toast('Erro: $e', isError: true);
    }
  }

  Future<void> _bulkActivate(bool active) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedIds) {
        batch.update(FirebaseFirestore.instance.collection('users').doc(id), {
          'ativo': active,
        });
      }
      await batch.commit();
      _toast(
        '${_selectedIds.length} utilizadores ${active ? 'ativados' : 'desativados'}.',
      );
      _toggleSelectionMode();
    } catch (e) {
      _toast('Erro: $e', isError: true);
    }
  }

  Future<void> _bulkChangeRole() async {
    final newRole = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Alterar Papel em Lote'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  roleOrder.map((role) {
                    return ListTile(
                      title: Text(roleLabels[role]!),
                      leading: Icon(roleIcons[role], color: roleColors[role]),
                      onTap: () => Navigator.pop(ctx, role),
                    );
                  }).toList(),
            ),
          ),
    );

    if (newRole == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedIds) {
        batch.update(FirebaseFirestore.instance.collection('users').doc(id), {
          'role': newRole,
        });
      }
      await batch.commit();
      _toast('Papel alterado para "${roleLabels[newRole]}".');
      _toggleSelectionMode();
    } catch (e) {
      _toast('Erro: $e', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📥 EXPORTAR CSV
  // ═══════════════════════════════════════════════════════════
  Future<void> _exportToCSV() async {
    final choice = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Exportar para CSV'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.select_all),
                  title: const Text('Todos os utilizadores'),
                  onTap: () => Navigator.pop(ctx, 'all'),
                ),
                if (_selectedIds.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.check_box),
                    title: Text('Selecionados (${_selectedIds.length})'),
                    onTap: () => Navigator.pop(ctx, 'selected'),
                  ),
              ],
            ),
          ),
    );

    if (choice == null) return;

    try {
      QuerySnapshot snapshot;

      if (choice == 'all') {
        snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .orderBy('nome')
                .get();
      } else {
        // Buscar apenas selecionados
        snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: _selectedIds.toList())
                .get();
      }

      final List<List<dynamic>> rows = [
        ['ID', 'Nome', 'Email', 'Papel', 'Ativo', 'Data Criação'],
      ];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        rows.add([
          doc.id,
          data['nome'] ?? '',
          data['email'] ?? '',
          roleLabels[data['role']] ?? 'Participante',
          data['ativo'] == true ? 'Sim' : 'Não',
          data['createAt']?.toDate().toString() ?? '',
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);
      final bytes = Uint8List.fromList(utf8.encode(csv));
      // Create a Blob from a Uint8Array; wrap in a Dart List and convert to JSArray.
      final blob = web.Blob([bytes.toJS].toJS);
      final url = web.URL.createObjectURL(blob);
      final anchor =
          web.HTMLAnchorElement()
            ..href = url
            ..download =
                'utilizadores_${DateTime.now().millisecondsSinceEpoch}.csv';
      anchor.click();
      web.URL.revokeObjectURL(url);

      _toast('CSV exportado! (${snapshot.docs.length} registos)');
    } catch (e) {
      _toast('Erro ao exportar: $e', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 💬 DIALOGS
  // ═══════════════════════════════════════════════════════════
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => _FilterBottomSheet(
            roleFilter: _roleFilter,
            statusFilter: _statusFilter,
            onApply: (role, status) {
              setState(() {
                _roleFilter = role;
                _statusFilter = status;
              });
            },
          ),
    );
  }

  Future<void> _showCreateUserDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Criar Novo Utilizador'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Criar'),
              ),
            ],
          ),
    );

    if (ok == true) {
      try {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailCtrl.text.trim(),
          password: passwordCtrl.text,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
              'nome': nameCtrl.text.trim(),
              'email': emailCtrl.text.trim(),
              'role': 'user',
              'ativo': true,
              'createAt': FieldValue.serverTimestamp(),
            });

        _toast('Utilizador criado!');
      } catch (e) {
        _toast('Erro: $e', isError: true);
      }
    }
  }

  Future<void> _showEditUserDialog(DocumentSnapshot doc, Map data) async {
    final nameCtrl = TextEditingController(text: data['nome']);
    final emailCtrl = TextEditingController(text: data['email']);

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Editar Utilizador'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    if (ok == true) {
      await doc.reference.update({
        'nome': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
      });
      _toast('Utilizador atualizado!');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Apagar Utilizador'),
            content: Text('Confirmar remoção de "${data['nome']}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Apagar'),
              ),
            ],
          ),
    );

    if (ok == true) {
      await doc.reference.delete();
      _toast('Utilizador apagado.');
    }
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 🎴 COMPONENTES
// ═══════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final Map<String, dynamic> data;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.doc,
    required this.data,
    required this.isSelectionMode,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nome = data['nome'] ?? '';
    final email = data['email'] ?? '';
    final role = data['role'] ?? 'user';
    final ativo = data['ativo'] == true;

    return Card(
      color: Colors.white,
      elevation: isSelected ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (isSelectionMode)
                Checkbox(value: isSelected, onChanged: (_) => onTap?.call()),
              CircleAvatar(
                radius: 28,
                backgroundColor: _ManageUsersViewState.roleColors[role]!
                    .withValues(alpha: 0.2),
                child: Icon(
                  _ManageUsersViewState.roleIcons[role],
                  color: _ManageUsersViewState.roleColors[role],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black, // ✅ FORÇAR COR
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                      ), // ✅ FORÇAR COR
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _RoleBadge(role: role),
                        const SizedBox(width: 8),
                        _StatusChip(ativo: ativo),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isSelectionMode) ...[
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.blue,
                  ), // ✅ FORÇAR COR
                  onPressed: onEdit,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.black54),
                  onSelected: (value) async {
                    final state =
                        context
                            .findAncestorStateOfType<_ManageUsersViewState>();
                    if (value == 'reset') {
                      state?._showResetPasswordDialog(context, data['email']);
                    } else if (value == 'delete') {
                      onDelete();
                    } else if (value == 'role') {
                      final newRole = await showDialog<String>(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: const Text('Alterar Papel'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children:
                                    _ManageUsersViewState.roleOrder.map((r) {
                                      return ListTile(
                                        leading: Icon(
                                          _ManageUsersViewState.roleIcons[r],
                                          color:
                                              _ManageUsersViewState
                                                  .roleColors[r],
                                        ),
                                        title: Text(
                                          _ManageUsersViewState.roleLabels[r]!,
                                        ),
                                        onTap: () => Navigator.pop(ctx, r),
                                      );
                                    }).toList(),
                              ),
                            ),
                      );
                      if (newRole != null && newRole != data['role']) {
                        try {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(doc.id)
                              .update({'role': newRole});
                          state?._toast(
                            'Papel alterado para ${_ManageUsersViewState.roleLabels[newRole]}',
                          );
                        } catch (e) {
                          state?._toast(
                            'Erro ao alterar papel: $e',
                            isError: true,
                          );
                        }
                      }
                    }
                  },
                  itemBuilder:
                      (ctx) => [
                        const PopupMenuItem(
                          value: 'reset',
                          child: ListTile(
                            leading: Icon(Icons.lock_reset, color: Colors.blue),
                            title: Text('Resetar Senha'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'role',
                          child: ListTile(
                            leading: Icon(
                              Icons.swap_horiz,
                              color: Colors.orange,
                            ),
                            title: Text('Alterar Papel'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            title: Text('Apagar'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UserGridCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final Map<String, dynamic> data;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _UserGridCard({
    required this.doc,
    required this.data,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final nome = data['nome'] ?? '';
    final email = data['email'] ?? '';
    final role = data['role'] ?? 'user';
    final ativo = data['ativo'] == true;

    return Card(
      color: Colors.white,
      elevation: isSelected ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Checkbox(value: isSelected, onChanged: (_) => onTap()),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: _ManageUsersViewState.roleColors[role]!
                        .withValues(alpha: 0.2),
                    child: Icon(
                      _ManageUsersViewState.roleIcons[role],
                      size: 32,
                      color: _ManageUsersViewState.roleColors[role],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoleBadge(role: role),
                      const SizedBox(width: 8),
                      _StatusChip(ativo: ativo),
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
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _ManageUsersViewState.roleColors[role]!.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _ManageUsersViewState.roleLabels[role]!,
        style: TextStyle(
          color: _ManageUsersViewState.roleColors[role],
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool ativo;
  const _StatusChip({required this.ativo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            ativo
                ? Colors.green.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ativo ? Icons.check_circle : Icons.block,
            size: 12,
            color: ativo ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            ativo ? 'Ativo' : 'Inativo',
            style: TextStyle(
              color: ativo ? Colors.green : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final String roleFilter;
  final String statusFilter;
  final Function(String, String) onApply;

  const _FilterBottomSheet({
    required this.roleFilter,
    required this.statusFilter,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String _role;
  late String _status;

  @override
  void initState() {
    super.initState();
    _role = widget.roleFilter;
    _status = widget.statusFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list),
              const SizedBox(width: 12),
              const Text(
                'Filtros Avançados',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed:
                    () => setState(() {
                      _role = 'all';
                      _status = 'all';
                    }),
                child: const Text('Limpar'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Papel', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Todos'),
                selected: _role == 'all',
                onSelected: (_) => setState(() => _role = 'all'),
              ),
              FilterChip(
                label: const Text('Participante'),
                selected: _role == 'user',
                onSelected: (_) => setState(() => _role = 'user'),
              ),
              FilterChip(
                label: const Text('Staff'),
                selected: _role == 'staff',
                onSelected: (_) => setState(() => _role = 'staff'),
              ),
              FilterChip(
                label: const Text('Admin'),
                selected: _role == 'admin',
                onSelected: (_) => setState(() => _role = 'admin'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Estado', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Todos'),
                selected: _status == 'all',
                onSelected: (_) => setState(() => _status = 'all'),
              ),
              FilterChip(
                label: const Text('Ativos'),
                selected: _status == 'active',
                onSelected: (_) => setState(() => _status = 'active'),
              ),
              FilterChip(
                label: const Text('Inativos'),
                selected: _status == 'inactive',
                onSelected: (_) => setState(() => _status = 'inactive'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(_role, _status);
                Navigator.pop(context);
              },
              child: const Text('Aplicar Filtros'),
            ),
          ),
        ],
      ),
    );
  }
}
