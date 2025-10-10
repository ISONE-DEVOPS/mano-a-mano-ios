import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/services/user_service.dart';

// Cores da Shell
class ShellColors {
  static const red = Color(0xFFED1C24);
  static const yellow = Color(0xFFFFCC00);
  static const lightRed = Color(0xFFFFE5E6);
  static const lightYellow = Color(0xFFFFF8DC);
  static const darkGray = Color(0xFF333333);
  static const lightGray = Color(0xFFF5F5F5);
}

class UserManagementView extends StatefulWidget {
  final String? userId;
  final String tipoInicial;

  const UserManagementView({
    super.key,
    this.userId,
    this.tipoInicial = 'staff',
  });

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Controllers
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController emergenciaController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // Estado
  late String tipoSelecionado;
  String tshirtSelecionado = 'M';
  bool isLoading = false;
  bool isEditMode = false;
  bool showPasswordFields = true;
  bool ativo = true;
  DocumentSnapshot<Map<String, dynamic>>? currentUser;
  List<DocumentSnapshot<Map<String, dynamic>>> searchResults = [];
  List<DocumentSnapshot<Map<String, dynamic>>> allUsers = [];
  bool isSearching = false;
  String filtroRole = 'todos';

  // Estados para veículos e equipas
  List<QueryDocumentSnapshot<Map<String, dynamic>>> veiculosDisponiveis = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> equipasDisponiveis = [];
  String? veiculoSelecionado;
  String? equipaSelecionada;

  // Estatísticas
  Map<String, int> stats = {
    'total': 0,
    'admin': 0,
    'staff': 0,
    'user': 0,
    'ativos': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    tipoSelecionado = widget.tipoInicial;
    isEditMode = widget.userId != null;
    showPasswordFields = !isEditMode;
    if (isEditMode) {
      _loadUserData();
      _tabController.index = 0;
    }
    _carregarVeiculosEEquipas();
    _carregarTodosUsuarios();
    _carregarEstatisticas();
  }

  Future<void> _carregarVeiculosEEquipas() async {
    final veiculosSnap =
        await FirebaseFirestore.instance.collection('veiculos').get();
    final equipasSnap =
        await FirebaseFirestore.instance.collection('equipas').get();
    setState(() {
      veiculosDisponiveis = veiculosSnap.docs;
      equipasDisponiveis = equipasSnap.docs;
    });
  }

  Future<void> _carregarTodosUsuarios() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .orderBy('nome')
            .get();
    setState(() => allUsers = snapshot.docs);
  }

  Future<void> _carregarEstatisticas() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    Map<String, int> newStats = {
      'total': snapshot.docs.length,
      'admin': 0,
      'staff': 0,
      'user': 0,
      'ativos': 0,
    };

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final role = data['role'] ?? 'user';
      newStats[role] = (newStats[role] ?? 0) + 1;
      if (data['ativo'] == true) {
        newStats['ativos'] = newStats['ativos']! + 1;
      }
    }

    setState(() => stats = newStats);
  }

  Future<void> _loadUserData() async {
    if (widget.userId == null) return;
    setState(() => isLoading = true);
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .get();
      if (doc.exists) {
        _loadUserFromDoc(doc);
      }
    } catch (e) {
      _showError('Erro ao carregar dados: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _loadUserFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    setState(() {
      currentUser = doc;
      nomeController.text = data['nome'] ?? '';
      emailController.text = data['email'] ?? '';
      telefoneController.text = data['telefone'] ?? '';
      emergenciaController.text = data['emergencia'] ?? '';
      tipoSelecionado = data['role'] ?? 'staff';
      tshirtSelecionado = data['tshirt'] ?? 'M';
      ativo = data['ativo'] ?? true;
      veiculoSelecionado = data['veiculoId'];
      equipaSelecionada = data['equipaId'];
      isEditMode = true;
      showPasswordFields = false;
    });
  }

  Future<void> _searchUsers() async {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => searchResults = allUsers);
      return;
    }

    setState(() => isSearching = true);
    try {
      final filtered =
          allUsers.where((doc) {
            final data = doc.data()!;
            final nome = (data['nome'] ?? '').toLowerCase();
            final email = (data['email'] ?? '').toLowerCase();
            final role = (data['role'] ?? '').toLowerCase();
            return nome.contains(query) ||
                email.contains(query) ||
                role.contains(query);
          }).toList();

      setState(() => searchResults = filtered);
    } finally {
      setState(() => isSearching = false);
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'nome': nomeController.text.trim(),
            'email': emailController.text.trim(),
            'telefone': telefoneController.text.trim(),
            'emergencia': emergenciaController.text.trim(),
            'tshirt': tshirtSelecionado,
            'role': tipoSelecionado,
            'ativo': true,
            'createAt': FieldValue.serverTimestamp(),
            'ultimoLogin': null,
            'equipaId': '',
            'veiculoId': '',
          });

      _showSuccess('Utilizador criado com sucesso!');
      _clearForm();
      _carregarTodosUsuarios();
      _carregarEstatisticas();
    } catch (e) {
      _showError('Erro ao criar utilizador: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate() || currentUser == null) return;

    setState(() => isLoading = true);
    try {
      Map<String, dynamic> updateData = {
        'nome': nomeController.text.trim(),
        'telefone': telefoneController.text.trim(),
        'emergencia': emergenciaController.text.trim(),
        'tshirt': tshirtSelecionado,
        'role': tipoSelecionado,
        'ativo': ativo,
        'veiculoId': veiculoSelecionado ?? '',
        'equipaId': equipaSelecionada ?? '',
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.id)
          .update(updateData);

      _showSuccess('Utilizador atualizado com sucesso!');
      _carregarTodosUsuarios();
      _carregarEstatisticas();
    } catch (e) {
      _showError('Erro ao atualizar utilizador: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      _showError('Email é obrigatório para redefinir senha');
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      _showSuccess('Email de redefinição de senha enviado!');
    } catch (e) {
      _showError('Erro ao enviar email de redefinição: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _clearForm() {
    nomeController.clear();
    emailController.clear();
    telefoneController.clear();
    emergenciaController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    setState(() {
      isEditMode = false;
      currentUser = null;
      showPasswordFields = true;
      ativo = true;
      tipoSelecionado = widget.tipoInicial;
      tshirtSelecionado = 'M';
      veiculoSelecionado = null;
      equipaSelecionada = null;
    });
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ShellColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: ShellColors.red) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ShellColors.lightGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ShellColors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return ShellColors.red;
      case 'staff':
        return Colors.orange;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShellColors.lightGray,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ShellColors.red,
        foregroundColor: Colors.white,
        title: const Text(
          'Gestão de Utilizadores',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                _clearForm();
                _tabController.animateTo(0);
              },
              tooltip: 'Criar novo utilizador',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ShellColors.yellow,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: 'Criar/Editar'),
            Tab(icon: Icon(Icons.search), text: 'Pesquisar'),
            Tab(icon: Icon(Icons.list), text: 'Lista Geral'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFormTab(), _buildSearchTab(), _buildListTab()],
      ),
    );
  }

  // TAB 1: Formulário
  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header com estatísticas rápidas
          _buildStatsCards(),
          const SizedBox(height: 16),

          // Formulário principal
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título com ícone
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ShellColors.lightRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEditMode ? Icons.edit : Icons.person_add,
                            color: ShellColors.red,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditMode
                                    ? 'Editar Utilizador'
                                    : 'Novo Utilizador',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: ShellColors.darkGray,
                                ),
                              ),
                              if (isEditMode)
                                Text(
                                  'ID: ${currentUser?.id.substring(0, 8)}...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isEditMode)
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: ShellColors.red,
                            ),
                            onPressed: _clearForm,
                            tooltip: 'Cancelar edição',
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Informações pessoais
                    _buildSectionTitle('Informações Pessoais', Icons.person),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: nomeController,
                      decoration: _inputDecoration(
                        'Nome completo',
                        icon: Icons.person,
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Nome é obrigatório'
                                  : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: emailController,
                      decoration: _inputDecoration('Email', icon: Icons.email),
                      keyboardType: TextInputType.emailAddress,
                      validator:
                          (value) =>
                              value == null || !value.contains('@')
                                  ? 'Email inválido'
                                  : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: telefoneController,
                            decoration: _inputDecoration(
                              'Telefone',
                              icon: Icons.phone,
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: emergenciaController,
                            decoration: _inputDecoration(
                              'Emergência',
                              icon: Icons.emergency,
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Configurações
                    _buildSectionTitle('Configurações', Icons.settings),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: tipoSelecionado,
                            decoration: _inputDecoration('Tipo de Utilizador'),
                            items: const [
                              DropdownMenuItem(
                                value: 'admin',
                                child: Text('👑 Admin'),
                              ),
                              DropdownMenuItem(
                                value: 'staff',
                                child: Text('🛠️ Staff'),
                              ),
                              DropdownMenuItem(
                                value: 'user',
                                child: Text('👤 Participante'),
                              ),
                            ],
                            onChanged:
                                (value) =>
                                    setState(() => tipoSelecionado = value!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: tshirtSelecionado,
                            decoration: _inputDecoration('Tamanho T-shirt'),
                            items: const [
                              DropdownMenuItem(value: 'XS', child: Text('XS')),
                              DropdownMenuItem(value: 'S', child: Text('S')),
                              DropdownMenuItem(value: 'M', child: Text('M')),
                              DropdownMenuItem(value: 'L', child: Text('L')),
                              DropdownMenuItem(value: 'XL', child: Text('XL')),
                              DropdownMenuItem(
                                value: 'XXL',
                                child: Text('XXL'),
                              ),
                            ],
                            onChanged:
                                (value) =>
                                    setState(() => tshirtSelecionado = value!),
                          ),
                        ),
                      ],
                    ),

                    if (isEditMode) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              ativo
                                  ? ShellColors.lightYellow
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                ativo
                                    ? ShellColors.yellow
                                    : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              ativo ? Icons.check_circle : Icons.cancel,
                              color: ativo ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Conta ${ativo ? "Ativa" : "Inativa"}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Switch(
                              value: ativo,
                              onChanged:
                                  (value) => setState(() => ativo = value),
                              activeThumbColor: ShellColors.red,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Campos para participantes
                    if (tipoSelecionado == 'user') ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Atribuições', Icons.assignment),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String?>(
                        initialValue: veiculoSelecionado,
                        decoration: _inputDecoration(
                          'Veículo',
                          icon: Icons.directions_car,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Nenhum'),
                          ),
                          ...veiculosDisponiveis.map((doc) {
                            final data = doc.data();
                            final nome =
                                '${data['modelo']} - ${data['matricula']}';
                            return DropdownMenuItem<String?>(
                              value: doc.id,
                              child: Text(nome),
                            );
                          }),
                        ],
                        onChanged:
                            (value) =>
                                setState(() => veiculoSelecionado = value),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String?>(
                        initialValue: equipaSelecionada,
                        decoration: _inputDecoration(
                          'Equipa',
                          icon: Icons.group,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Nenhuma'),
                          ),
                          ...equipasDisponiveis.map((doc) {
                            final data = doc.data();
                            return DropdownMenuItem<String?>(
                              value: doc.id,
                              child: Text(data['nome'] ?? 'Sem nome'),
                            );
                          }),
                        ],
                        onChanged:
                            (value) =>
                                setState(() => equipaSelecionada = value),
                      ),
                    ],

                    // Senha
                    if (showPasswordFields) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Segurança', Icons.lock),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: _inputDecoration('Senha', icon: Icons.lock),
                        validator:
                            (value) =>
                                value != null && value.length >= 6
                                    ? null
                                    : 'Mínimo 6 caracteres',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: _inputDecoration(
                          'Confirmar senha',
                          icon: Icons.lock_outline,
                        ),
                        validator:
                            (value) =>
                                value != passwordController.text
                                    ? 'Senhas não coincidem'
                                    : null,
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Botões de ação
                    if (isEditMode)
                      _buildEditButtons()
                    else
                      _buildCreateButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: Pesquisa
  Widget _buildSearchTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Pesquisar por nome, email ou função...',
                  prefixIcon: const Icon(Icons.search, color: ShellColors.red),
                  suffixIcon:
                      searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              setState(() => searchResults.clear());
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: ShellColors.red,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: ShellColors.lightGray,
                ),
                onChanged: (value) => _searchUsers(),
              ),
              const SizedBox(height: 12),

              // Filtros rápidos
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: filtroRole == 'todos',
                    onSelected: (selected) {
                      setState(() {
                        filtroRole = 'todos';
                        _searchUsers();
                      });
                    },
                    selectedColor: ShellColors.yellow,
                  ),
                  FilterChip(
                    label: const Text('Admin'),
                    selected: filtroRole == 'admin',
                    onSelected: (selected) {
                      setState(() {
                        filtroRole = 'admin';
                        _searchUsers();
                      });
                    },
                    selectedColor: ShellColors.red.withValues(alpha: 0.3),
                  ),
                  FilterChip(
                    label: const Text('Staff'),
                    selected: filtroRole == 'staff',
                    onSelected: (selected) {
                      setState(() {
                        filtroRole = 'staff';
                        _searchUsers();
                      });
                    },
                    selectedColor: Colors.orange.withValues(alpha: 0.3),
                  ),
                  FilterChip(
                    label: const Text('Participantes'),
                    selected: filtroRole == 'user',
                    onSelected: (selected) {
                      setState(() {
                        filtroRole = 'user';
                        _searchUsers();
                      });
                    },
                    selectedColor: Colors.blue.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildUsersList(
            searchResults.isEmpty ? allUsers : searchResults,
          ),
        ),
      ],
    );
  }

  // TAB 3: Lista
  Widget _buildListTab() {
    return Column(
      children: [
        _buildStatsCards(),
        Expanded(child: _buildUsersList(allUsers)),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              stats['total'].toString(),
              Icons.people,
              ShellColors.red,
              ShellColors.lightRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Admin',
              stats['admin'].toString(),
              Icons.admin_panel_settings,
              Colors.red,
              Colors.red.shade50,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Staff',
              stats['staff'].toString(),
              Icons.work,
              Colors.orange,
              Colors.orange.shade50,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Ativos',
              stats['ativos'].toString(),
              Icons.check_circle,
              Colors.green,
              Colors.green.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: ShellColors.red, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ShellColors.darkGray,
          ),
        ),
      ],
    );
  }

  Widget _buildUsersList(List<DocumentSnapshot<Map<String, dynamic>>> users) {
    final filteredUsers =
        filtroRole == 'todos'
            ? users
            : users.where((doc) => doc.data()!['role'] == filtroRole).toList();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nenhum utilizador encontrado',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        final data = user.data()!;
        final role = data['role'] ?? 'user';
        final isActive = data['ativo'] ?? true;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _loadUserFromDoc(user);
              _tabController.animateTo(0);
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _getRoleColor(role).withValues(alpha: 0.2),
                    child: Text(
                      (data['nome']?[0] ?? '?').toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getRoleColor(role),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Informações
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data['nome'] ?? 'Sem nome',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: ShellColors.darkGray,
                                ),
                              ),
                            ),
                            if (!isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Inativo',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['email'] ?? 'Sem email',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildInfoChip(
                              role.toUpperCase(),
                              _getRoleColor(role),
                            ),
                            const SizedBox(width: 8),
                            if (data['tshirt'] != null)
                              _buildInfoChip(
                                'T-shirt: ${data['tshirt']}',
                                Colors.grey,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Ícone de navegação
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEditButtons() {
    return Column(
      children: [
        // Botão principal de atualizar
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _updateUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: ShellColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon:
                isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.save),
            label: Text(
              isLoading ? 'Atualizando...' : 'Atualizar Utilizador',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Botões secundários
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : _resetPassword,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ShellColors.red,
                  side: const BorderSide(color: ShellColors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.email, size: 20),
                label: const Text('Reset Senha'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    isLoading || tipoSelecionado == 'user'
                        ? null
                        : () async {
                          setState(() => isLoading = true);
                          try {
                            await UserService.converterParaParticipante(
                              currentUser!.id,
                            );
                            _showSuccess('Convertido com sucesso!');
                            await _loadUserData();
                          } catch (e) {
                            _showError('Erro na conversão: $e');
                          } finally {
                            setState(() => isLoading = false);
                          }
                        },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.person_add, size: 20),
                label: const Text('→ Participante'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _createUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: ShellColors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon:
            isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.person_add),
        label: Text(
          isLoading ? 'Criando...' : 'Criar Utilizador',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    emergenciaController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
