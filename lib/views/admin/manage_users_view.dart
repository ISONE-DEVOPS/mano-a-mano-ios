import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageUsersView extends StatefulWidget {
  const ManageUsersView({super.key});

  @override
  State<ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends State<ManageUsersView> {
  final _searchCtrl = TextEditingController();
  String _filter = '';
  String _roleFilter = 'all'; // all, user, staff, admin
  String _statusFilter = 'all'; // all, active, inactive

  // Firestore usa: user (participante), staff, admin
  static const Map<String, String> roleLabels = {
    'user': 'Participante',
    'staff': 'Staff',
    'admin': 'Admin',
  };
  static const List<String> roleOrder = ['user', 'staff', 'admin'];
  static const Map<String, Color> roleColors = {
    'user': Color(0xFF1976D2), // blue
    'staff': Color(0xFF00897B), // teal
    'admin': Color(0xFFD32F2F), // red
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Utilizadores')),
      body: Theme(
        // Força legibilidade em dark mode
        data: theme.copyWith(
          dataTableTheme: const DataTableThemeData(
            headingTextStyle: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            dataTextStyle: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            headingRowColor: WidgetStatePropertyAll(Color(0xFFEDEDED)),
            dataRowColor: WidgetStatePropertyAll(Colors.white),
            dividerThickness: 0.6,
          ),
          popupMenuTheme: const PopupMenuThemeData(
            textStyle: TextStyle(color: Colors.black),
            surfaceTintColor: Colors.white,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildToolbar(),
              const SizedBox(height: 8),
              _buildFilters(),
              const SizedBox(height: 12),
              _buildLegendAndCount(),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('users')
                            .orderBy('nome')
                            .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('Erro: ${snap.error}'),
                          ),
                        );
                      }

                      final docs = snap.data?.docs ?? [];
                      final filtered =
                          docs.where((d) {
                            final data =
                                d.data() as Map<String, dynamic>? ?? {};
                            final nome =
                                (data['nome'] ?? '').toString().toLowerCase();
                            final email =
                                (data['email'] ?? '').toString().toLowerCase();
                            final role = (data['role'] ?? 'user').toString();
                            final ativo = (data['ativo'] ?? true) == true;

                            final matchesText =
                                _filter.isEmpty ||
                                nome.contains(_filter) ||
                                email.contains(_filter);

                            final matchesRole =
                                _roleFilter == 'all' || role == _roleFilter;

                            final matchesStatus =
                                _statusFilter == 'all' ||
                                (_statusFilter == 'active' && ativo) ||
                                (_statusFilter == 'inactive' && !ativo);

                            return matchesText && matchesRole && matchesStatus;
                          }).toList();

                      if (filtered.isEmpty) {
                        return const Center(child: Text('Sem resultados'));
                      }

                      return _buildTable(filtered);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Barra de pesquisa + limpar
  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Pesquisar por nome ou email…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: () => _searchCtrl.clear(),
          icon: const Icon(Icons.clear_all),
          label: const Text('Limpar'),
        ),
      ],
    );
  }

  // Filtros de papel e estado
  Widget _buildFilters() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Papel
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text(
                  'Papel:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ChoiceChip(
                label: const Text('Todos'),
                selected: _roleFilter == 'all',
                onSelected: (_) => setState(() => _roleFilter = 'all'),
              ),
              ChoiceChip(
                label: const Text('Participante'),
                selected: _roleFilter == 'user',
                onSelected: (_) => setState(() => _roleFilter = 'user'),
              ),
              ChoiceChip(
                label: const Text('Staff'),
                selected: _roleFilter == 'staff',
                onSelected: (_) => setState(() => _roleFilter = 'staff'),
              ),
              ChoiceChip(
                label: const Text('Admin'),
                selected: _roleFilter == 'admin',
                onSelected: (_) => setState(() => _roleFilter = 'admin'),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Estado
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text(
                  'Estado:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ChoiceChip(
                label: const Text('Todos'),
                selected: _statusFilter == 'all',
                onSelected: (_) => setState(() => _statusFilter = 'all'),
              ),
              ChoiceChip(
                label: const Text('Ativos'),
                selected: _statusFilter == 'active',
                onSelected: (_) => setState(() => _statusFilter = 'active'),
              ),
              ChoiceChip(
                label: const Text('Inativos'),
                selected: _statusFilter == 'inactive',
                onSelected: (_) => setState(() => _statusFilter = 'inactive'),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TextButton.icon(
          onPressed:
              () => setState(() {
                _roleFilter = 'all';
                _statusFilter = 'all';
              }),
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Limpar filtros'),
        ),
      ],
    );
  }

  // Legenda de papéis + contagem total
  Widget _buildLegendAndCount() {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: const [
              _LegendChip(color: Color(0xFF1976D2), label: 'Participante'),
              _LegendChip(color: Color(0xFF00897B), label: 'Staff'),
              _LegendChip(color: Color(0xFFD32F2F), label: 'Admin'),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Builder(
          builder: (context) {
            return StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snap) {
                final total = snap.data?.docs.length ?? 0;
                return Text(
                  'Total: $total',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // Ordenação local (nome/email)
  void _sortBy(List<QueryDocumentSnapshot> list, String field, bool ascending) {
    setState(() {
      list.sort((a, b) {
        final ma = (a.data() as Map<String, dynamic>? ?? {});
        final mb = (b.data() as Map<String, dynamic>? ?? {});
        final va = (ma[field] ?? '').toString().toLowerCase();
        final vb = (mb[field] ?? '').toString().toLowerCase();
        return ascending ? va.compareTo(vb) : vb.compareTo(va);
      });
    });
  }

  Widget _buildTable(List<QueryDocumentSnapshot> users) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columnSpacing: 28,
            columns: [
              DataColumn(
                label: const Text('Nome'),
                onSort: (i, asc) => _sortBy(users, 'nome', asc),
              ),
              DataColumn(
                label: const Text('Email'),
                onSort: (i, asc) => _sortBy(users, 'email', asc),
              ),
              const DataColumn(label: Text('Papel')),
              const DataColumn(label: Text('Ativo')),
              const DataColumn(label: Text('Ações')),
            ],
            rows:
                users.map((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final nome = (data['nome'] ?? '').toString();
                  final email = (data['email'] ?? '').toString();
                  final role = (data['role'] ?? 'user').toString();
                  final ativo = (data['ativo'] ?? true) == true;

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          nome,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          email,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      DataCell(
                        Tooltip(
                          message: 'Alterar papel',
                          child: _buildRoleCell(doc, role),
                        ),
                      ),
                      DataCell(
                        Switch(
                          value: ativo,
                          onChanged: (v) async {
                            final old =
                                (doc.data() as Map<String, dynamic>? ??
                                    {})['ativo'] ==
                                true;
                            await doc.reference.update({'ativo': v});
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Utilizador ${v ? 'ativado' : 'inativado'}',
                                ),
                                action: SnackBarAction(
                                  label: 'Desfazer',
                                  onPressed: () async {
                                    await doc.reference.update({'ativo': old});
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Editar utilizador',
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                final data =
                                    doc.data() as Map<String, dynamic>? ?? {};
                                _showEditUserDialog(doc, data);
                              },
                            ),
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              tooltip: 'Mais ações',
                              onSelected: (value) {
                                if (value == 'reset') {
                                  _confirmResetPassword(context, email);
                                } else if (value == 'copy') {
                                  Clipboard.setData(ClipboardData(text: email));
                                  _toast('Email copiado');
                                } else if (value == 'delete') {
                                  _confirmDelete(context, doc);
                                }
                              },
                              itemBuilder:
                                  (context) => [
                                    const PopupMenuItem(
                                      value: 'reset',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.password_outlined,
                                          color: Colors.black,
                                        ),
                                        title: Text(
                                          'Resetar senha',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'copy',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.copy_all_outlined,
                                          color: Colors.black,
                                        ),
                                        title: Text(
                                          'Copiar email',
                                          style: TextStyle(color: Colors.black),
                                        ),
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
                                        title: Text(
                                          'Apagar',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                              child: const Icon(
                                Icons.more_horiz,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  // Papel: badge + dropdown editable
  Widget _buildRoleCell(QueryDocumentSnapshot doc, String role) {
    final current = roleOrder.contains(role) ? role : 'user';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: roleColors[current]!.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: roleColors[current]!.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(roleIcons[current], size: 14, color: roleColors[current]),
              const SizedBox(width: 6),
              Text(
                roleLabels[current]!,
                style: TextStyle(
                  color: roleColors[current],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: current,
            items:
                roleOrder.map((r) {
                  return DropdownMenuItem(
                    value: r,
                    child: Text(roleLabels[r]!),
                  );
                }).toList(),
            onChanged: (value) async {
              if (value == null) return;
              await doc.reference.update({'role': value});
              _toast('Papel atualizado para ${roleLabels[value]}');
              setState(() {}); // atualiza selo
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showEditUserDialog(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) async {
    final nameCtrl = TextEditingController(
      text: (data['nome'] ?? '').toString(),
    );
    final emailCtrl = TextEditingController(
      text: (data['email'] ?? '').toString(),
    );
    String role = (data['role'] ?? 'user').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Editar Utilizador'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      'Papel:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: roleOrder.contains(role) ? role : 'user',
                      items:
                          roleOrder.map((r) {
                            return DropdownMenuItem(
                              value: r,
                              child: Text(roleLabels[r]!),
                            );
                          }).toList(),
                      onChanged: (v) => role = v ?? role,
                    ),
                  ],
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
        );
      },
    );

    if (ok == true) {
      try {
        await doc.reference.update({
          'nome': nameCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'role': role,
        });
        _toast('Utilizador atualizado.');
      } catch (e) {
        _toast('Erro ao atualizar: $e', isError: true);
      }
    }
  }

  Future<void> _confirmResetPassword(BuildContext context, String email) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Resetar senha'),
            content: Text('Enviar email de redefinição para:\n$email'),
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
    if (ok != true) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _toast('Email de redefinição enviado.');
    } catch (e) {
      _toast('Falha ao enviar email: $e', isError: true);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    QueryDocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final nome = (data['nome'] ?? '').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Apagar Utilizador'),
            content: Text(
              'Tem certeza que deseja apagar "$nome"? Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Apagar'),
              ),
            ],
          ),
    );

    if (ok == true) {
      try {
        await doc.reference.delete();
        _toast('Utilizador apagado.');
      } catch (e) {
        _toast('Erro ao apagar utilizador: $e', isError: true);
      }
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

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
