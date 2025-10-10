import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Cores pastel laranja e preto para Mano a Mano
class ManoColors {
  static const Color orangePastel = Color(0xFFFFD4B3);
  static const Color orangeLight = Color(0xFFFFE5CC);
  static const Color orangeMedium = Color(0xFFFFC299);
  static const Color orangeDark = Color(0xFFFF9966);
  static const Color blackPastel = Color(0xFF4A4A4A);
  static const Color greyPastel = Color(0xFF666666);
  static const Color background = Color(0xFFFFF8F0);
  static const Color cardBackground = Colors.white;
}

class UsersAdminView extends StatefulWidget {
  const UsersAdminView({super.key});

  @override
  State<UsersAdminView> createState() => _UsersAdminViewState();
}

class _UsersAdminViewState extends State<UsersAdminView> {
  String _searchQuery = '';
  String _selectedFilter = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ManoColors.background,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Utilizadores',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: ManoColors.orangeDark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: ManoColors.orangeDark),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final isAdmin = userData?['tipo'] == 'admin';

          final stream =
              isAdmin
                  ? FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('nome')
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('users')
                      .where(
                        FieldPath.documentId,
                        isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                      )
                      .snapshots();

          return StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: ManoColors.orangeDark,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: ManoColors.orangePastel,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum utilizador encontrado',
                        style: TextStyle(
                          color: ManoColors.blackPastel,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final allUsers = snapshot.data!.docs;

              // Filtrar utilizadores
              final filteredUsers =
                  allUsers.where((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    if (data == null) return false;

                    // Filtro por pesquisa
                    final nome = (data['nome'] ?? '').toString().toLowerCase();
                    final email =
                        (data['email'] ?? '').toString().toLowerCase();
                    final matchesSearch =
                        _searchQuery.isEmpty ||
                        nome.contains(_searchQuery.toLowerCase()) ||
                        email.contains(_searchQuery.toLowerCase());

                    // Filtro por tipo
                    final tipo = data['tipo'] ?? 'user';
                    final matchesFilter =
                        _selectedFilter == 'Todos' ||
                        (_selectedFilter == 'Admins' && tipo == 'admin') ||
                        (_selectedFilter == 'Utilizadores' && tipo != 'admin');

                    return matchesSearch && matchesFilter;
                  }).toList();

              final totalUsers = allUsers.length;
              final totalAdmins =
                  allUsers
                      .where(
                        (doc) =>
                            (doc.data() as Map<String, dynamic>?)?['tipo'] ==
                            'admin',
                      )
                      .length;

              return Column(
                children: [
                  // Estatísticas
                  if (isAdmin) _buildStats(totalUsers, totalAdmins),

                  // Barra de pesquisa e filtros
                  _buildSearchAndFilters(),

                  // Lista de utilizadores
                  Expanded(
                    child:
                        filteredUsers.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: ManoColors.orangePastel,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhum resultado encontrado',
                                    style: TextStyle(
                                      color: ManoColors.greyPastel,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final doc = filteredUsers[index];
                                final data =
                                    doc.data() as Map<String, dynamic>?;
                                if (data == null || data.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return _buildUserCard(
                                  context,
                                  doc,
                                  data,
                                  isAdmin,
                                );
                              },
                            ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStats(int total, int admins) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ManoColors.orangeDark, ManoColors.orangeMedium],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ManoColors.orangePastel.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.people,
            label: 'Total',
            value: total.toString(),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            icon: Icons.verified_user,
            label: 'Admins',
            value: admins.toString(),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            icon: Icons.person,
            label: 'Users',
            value: (total - admins).toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Barra de pesquisa
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ManoColors.orangePastel.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(color: ManoColors.blackPastel),
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome ou email...',
                hintStyle: TextStyle(color: ManoColors.greyPastel),
                prefixIcon: Icon(Icons.search, color: ManoColors.orangeDark),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear, color: ManoColors.greyPastel),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos'),
                const SizedBox(width: 8),
                _buildFilterChip('Admins'),
                const SizedBox(width: 8),
                _buildFilterChip('Utilizadores'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : ManoColors.blackPastel,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = label);
      },
      backgroundColor: ManoColors.orangeLight,
      selectedColor: ManoColors.orangeDark,
      checkmarkColor: Colors.white,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    DocumentSnapshot doc,
    Map<String, dynamic> data,
    bool isAdmin,
  ) {
    final nome = data['nome'] ?? 'Sem nome';
    final email = data['email'] ?? 'Sem email';
    final tipo = data['tipo'] ?? 'user';
    final isAdminUser = tipo == 'admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ManoColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ManoColors.orangePastel.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      isAdminUser
                          ? [ManoColors.orangeDark, ManoColors.orangeMedium]
                          : [ManoColors.orangeLight, ManoColors.orangePastel],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  nome[0].toUpperCase(),
                  style: TextStyle(
                    color: isAdminUser ? Colors.white : ManoColors.blackPastel,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          nome,
                          style: TextStyle(
                            color: ManoColors.blackPastel,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAdminUser) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ManoColors.orangeDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      color: ManoColors.greyPastel,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Ações
            if (isAdmin) ...[
              IconButton(
                icon: Icon(Icons.edit_outlined, color: ManoColors.orangeDark),
                onPressed: () => _showEditDialog(context, doc, data),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: ManoColors.blackPastel),
                onPressed: () => _showDeleteDialog(context, doc, nome),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    DocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    final nomeController = TextEditingController(text: data['nome'] ?? '');
    final emailController = TextEditingController(text: data['email'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ManoColors.orangeLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit, color: ManoColors.orangeDark),
                ),
                const SizedBox(width: 12),
                Text(
                  'Editar Utilizador',
                  style: TextStyle(
                    color: ManoColors.blackPastel,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomeController,
                    style: TextStyle(color: ManoColors.blackPastel),
                    decoration: InputDecoration(
                      labelText: 'Nome',
                      labelStyle: TextStyle(color: ManoColors.greyPastel),
                      prefixIcon: Icon(
                        Icons.person,
                        color: ManoColors.orangeDark,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ManoColors.orangeLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: ManoColors.orangeDark,
                          width: 2,
                        ),
                      ),
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Nome obrigatório'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    style: TextStyle(color: ManoColors.blackPastel),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: ManoColors.greyPastel),
                      prefixIcon: Icon(
                        Icons.email,
                        color: ManoColors.orangeDark,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ManoColors.orangeLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: ManoColors.orangeDark,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email obrigatório';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      return emailRegex.hasMatch(value)
                          ? null
                          : 'Email inválido';
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: ManoColors.greyPastel),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    await doc.reference.update({
                      'nome': nomeController.text.trim(),
                      'email': emailController.text.trim(),
                    });
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Utilizador atualizado com sucesso',
                        ),
                        backgroundColor: ManoColors.orangeDark,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ManoColors.orangeDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    DocumentSnapshot doc,
    String nome,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Text(
                  'Confirmar remoção',
                  style: TextStyle(
                    color: ManoColors.blackPastel,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'Deseja realmente apagar o utilizador "$nome"?\n\nEsta ação não pode ser desfeita.',
              style: TextStyle(color: ManoColors.blackPastel),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: ManoColors.greyPastel),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await doc.reference.delete();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Utilizador removido com sucesso'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text('Apagar'),
              ),
            ],
          ),
    );
  }
}
