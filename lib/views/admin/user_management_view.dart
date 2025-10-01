import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mano_mano_dashboard/services/user_service.dart';

class UserManagementView extends StatefulWidget {
  final String? userId; // Se fornecido, está em modo de edição
  final String tipoInicial;
  
  const UserManagementView({
    super.key, 
    this.userId,
    this.tipoInicial = 'staff',
  });

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController emergenciaController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
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
  bool isSearching = false;

  // Estados para veículos e equipas
  List<QueryDocumentSnapshot<Map<String, dynamic>>> veiculosDisponiveis = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> equipasDisponiveis = [];
  String? veiculoSelecionado;
  String? equipaSelecionada;

  @override
  void initState() {
    super.initState();
    tipoSelecionado = widget.tipoInicial;
    isEditMode = widget.userId != null;
    showPasswordFields = !isEditMode;
    if (isEditMode) {
      _loadUserData();
    }
    _carregarVeiculosEEspquipas();
  }
  Future<void> _carregarVeiculosEEspquipas() async {
    final veiculosSnap = await FirebaseFirestore.instance.collection('veiculos').get();
    final equipasSnap = await FirebaseFirestore.instance.collection('equipas').get();
    setState(() {
      veiculosDisponiveis = veiculosSnap.docs;
      equipasDisponiveis = equipasSnap.docs;
    });
  }

  Future<void> _loadUserData() async {
    if (widget.userId == null) return;
    setState(() => isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (doc.exists) {
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
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
      _showError('Erro ao carregar dados: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _searchUsers() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => isSearching = true);
    try {
      // Buscar por nome
      QuerySnapshot<Map<String, dynamic>> nameResults =
          await FirebaseFirestore.instance
              .collection('users')
              .where('nome', isGreaterThanOrEqualTo: query)
              .where('nome', isLessThan: '${query}z')
              .limit(10)
              .get();

      // Buscar por email
      QuerySnapshot<Map<String, dynamic>> emailResults =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isGreaterThanOrEqualTo: query)
              .where('email', isLessThan: '${query}z')
              .limit(10)
              .get();

      Set<String> seen = {};
      List<DocumentSnapshot<Map<String, dynamic>>> combined = [];

      // Não use .toList() nas expressões espalhadas, pois docs já é iterável
      for (var doc in [...nameResults.docs, ...emailResults.docs]) {
        if (!seen.contains(doc.id)) {
          seen.add(doc.id);
          combined.add(doc);
        }
      }

      setState(() => searchResults = combined);
    } catch (e) {
      debugPrint('Erro na busca: $e');
      _showError('Erro na busca: $e');
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
    } catch (e) {
      debugPrint('Erro ao criar utilizador: $e');
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
      };

      // Atualizar email se mudou
      final currentEmail = currentUser!.data()!['email'];
      final newEmail = emailController.text.trim();
      if (currentEmail != newEmail) {
        updateData['email'] = newEmail;
        // Nota: Em produção, seria necessário re-autenticar o usuário para mudar email
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.id)
          .update(updateData);

      _showSuccess('Utilizador atualizado com sucesso!');
    } catch (e) {
      debugPrint('Erro ao atualizar utilizador: $e');
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
      debugPrint('Erro ao enviar email de redefinição: $e');
      _showError('Erro ao enviar email de redefinição: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _selectUser(DocumentSnapshot<Map<String, dynamic>> user) {
    setState(() {
      currentUser = user;
      isEditMode = true;
      showPasswordFields = false;
      searchResults.clear();
      searchController.clear();
    });
    _loadUserFromDoc(user);
  }

  void _loadUserFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    setState(() {
      nomeController.text = data['nome'] ?? '';
      emailController.text = data['email'] ?? '';
      telefoneController.text = data['telefone'] ?? '';
      emergenciaController.text = data['emergencia'] ?? '';
      tipoSelecionado = data['role'] ?? 'staff';
      tshirtSelecionado = data['tshirt'] ?? 'M';
      ativo = data['ativo'] ?? true;
      veiculoSelecionado = data['veiculoId'];
      equipaSelecionada = data['equipaId'];
    });
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
    });
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Editar Utilizador' : 'Criar Utilizador'),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _clearForm,
              tooltip: 'Criar novo utilizador',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Seção de Busca
            if (!isEditMode) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buscar Utilizador Existente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: _inputDecoration(
                                'Buscar por nome ou email',
                                icon: Icons.search,
                              ),
                              onSubmitted: (_) => _searchUsers(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isSearching ? null : _searchUsers,
                            child: isSearching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.search),
                          ),
                        ],
                      ),
                      if (searchResults.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const Text('Resultados:'),
                        const SizedBox(height: 8),
                        ...searchResults.map((user) {
                          final data = user.data()!;
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(data['nome']?[0]?.toUpperCase() ?? '?'),
                            ),
                            title: Text(data['nome'] ?? 'Sem nome'),
                            subtitle: Text(data['email'] ?? 'Sem email'),
                            trailing: Chip(
                              label: Text(data['role'] ?? 'user'),
                              backgroundColor: data['role'] == 'admin'
                                  ? Colors.red.shade100
                                  : data['role'] == 'staff'
                                      ? Colors.blue.shade100
                                      : Colors.grey.shade100,
                            ),
                            onTap: () => _selectUser(user),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Formulário Principal
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditMode ? 'Editar Dados' : 'Dados do Novo Utilizador',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nome
                      TextFormField(
                        controller: nomeController,
                        decoration: _inputDecoration('Nome completo', icon: Icons.person),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Nome é obrigatório' : null,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: emailController,
                        decoration: _inputDecoration('Email', icon: Icons.email),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            value == null || !value.contains('@')
                                ? 'Email inválido'
                                : null,
                      ),
                      const SizedBox(height: 16),

                      // Telefone
                      TextFormField(
                        controller: telefoneController,
                        decoration: _inputDecoration('Telefone', icon: Icons.phone),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Contacto de Emergência
                      TextFormField(
                        controller: emergenciaController,
                        decoration: _inputDecoration(
                          'Contacto de emergência',
                          icon: Icons.emergency,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Row para Tipo e T-shirt
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: tipoSelecionado,
                              decoration: _inputDecoration('Tipo'),
                              items: const [
                                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                DropdownMenuItem(value: 'staff', child: Text('Staff')),
                                DropdownMenuItem(value: 'user', child: Text('Utilizador')),
                              ],
                              onChanged: (value) =>
                                  setState(() => tipoSelecionado = value!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: tshirtSelecionado,
                              decoration: _inputDecoration('T-shirt'),
                              items: const [
                                DropdownMenuItem(value: 'XS', child: Text('XS')),
                                DropdownMenuItem(value: 'S', child: Text('S')),
                                DropdownMenuItem(value: 'M', child: Text('M')),
                                DropdownMenuItem(value: 'L', child: Text('L')),
                                DropdownMenuItem(value: 'XL', child: Text('XL')),
                                DropdownMenuItem(value: 'XXL', child: Text('XXL')),
                              ],
                              onChanged: (value) =>
                                  setState(() => tshirtSelecionado = value!),
                            ),
                          ),
                        ],
                      ),

                      // Switch para Ativo (apenas em modo de edição)
                      if (isEditMode) ...[
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Utilizador ativo'),
                          value: ativo,
                          onChanged: (value) => setState(() => ativo = value),
                        ),
                      ],

                      // Campos de senha (apenas para criação ou quando solicitado)
                      if (showPasswordFields) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const Text(
                          'Senha',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: _inputDecoration('Senha', icon: Icons.lock),
                          validator: (value) =>
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
                          validator: (value) =>
                              value != passwordController.text
                                  ? 'Senhas não coincidem'
                                  : null,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Botões de ação
                      if (isEditMode)
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isLoading ? null : _updateUser,
                                    icon: const Icon(Icons.save),
                                    label: Text(
                                      isLoading ? 'Atualizando...' : 'Atualizar',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: isLoading ? null : _resetPassword,
                                    icon: const Icon(Icons.email),
                                    label: const Text('Reset Senha'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (!showPasswordFields)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    setState(() => showPasswordFields = true),
                                icon: const Icon(Icons.password),
                                label: const Text('Definir Nova Senha'),
                              ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.how_to_reg),
                              label: const Text('Converter em Participante'),
                              onPressed: isLoading || currentUser == null
                                  ? null
                                  : () async {
                                      setState(() => isLoading = true);
                                      try {
                                        await UserService.converterParaParticipante(currentUser!.id);
                                        _showSuccess('Convertido com sucesso!');
                                      } catch (e) {
                                        _showError('Erro na conversão: $e');
                                      } finally {
                                        setState(() => isLoading = false);
                                      }
                                    },
                            ),
                            // Campos extras para user (após conversão)
                            if (tipoSelecionado == 'user') ...[
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                initialValue: veiculoSelecionado,
                                decoration: _inputDecoration('Selecionar Veículo', icon: Icons.directions_car),
                                items: veiculosDisponiveis.map((doc) {
                                  final data = doc.data();
                                  final nome = '${data['modelo']} - ${data['matricula']} (${data['nome_equip']})';
                                  return DropdownMenuItem(
                                    value: doc.id,
                                    child: Text(nome),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => veiculoSelecionado = value);
                                  FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUser!.id)
                                    .update({'veiculoId': value});
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                initialValue: equipaSelecionada,
                                decoration: _inputDecoration('Selecionar Equipa', icon: Icons.group),
                                items: equipasDisponiveis.map((doc) {
                                  final data = doc.data();
                                  return DropdownMenuItem(
                                    value: doc.id,
                                    child: Text(data['nome'] ?? 'Equipa sem nome'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => equipaSelecionada = value);
                                  FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUser!.id)
                                    .update({'equipaId': value});
                                },
                              ),
                            ],
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _createUser,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.person_add),
                          label: Text(
                            isLoading ? 'Criando...' : 'Criar Utilizador',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
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