import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateUserView extends StatefulWidget {
  final String tipoInicial;
  const CreateUserView({super.key, this.tipoInicial = 'staff'});

  @override
  State<CreateUserView> createState() => _CreateUserViewState();
}

class _CreateUserViewState extends State<CreateUserView> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emergenciaController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late String _tipoSelecionado;
  String _tshirtSize = 'M';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _autoValidate = false;

  final List<String> _tshirtSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  @override
  void initState() {
    super.initState();
    _tipoSelecionado = widget.tipoInicial;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _emergenciaController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validação de força de senha
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo obrigatório';
    }
    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Deve conter letra maiúscula';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Deve conter número';
    }
    return null;
  }

  Future<void> _criarUser() async {
    // Ativar validação em tempo real após primeira tentativa
    setState(() => _autoValidate = true);

    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Por favor, corrija os erros no formulário');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Nota: Não verificamos a existência do email para evitar enumeração (ver recomendação do Firebase).
      // Criar usuário no Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final uid = userCredential.user!.uid;

      // Criar documento no Firestore com todos os campos
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'nome': _nomeController.text.trim(),
        'email': _emailController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'emergencia': _emergenciaController.text.trim(),
        'tshirt': _tshirtSize,
        'role': _tipoSelecionado,
        'createAt': FieldValue.serverTimestamp(),
        'ativo': true,
        'ultimoLogin': null,
        'equipaId': '',
        'veiculoId': '',
      });

      // Enviar email de verificação
      await userCredential.user!.sendEmailVerification();

      if (mounted) {
        final navigator = Navigator.of(context);
        _showSuccessSnackBar(
          '✅ Utilizador criado! Email de verificação enviado.',
        );

        // Aguardar um pouco para o usuário ver a mensagem
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;

        if (_tipoSelecionado == 'admin') {
          navigator.pushReplacementNamed('/admin');
        } else {
          navigator.pop(true);
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Erro ao criar utilizador';

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Este email já está em uso';
          break;
        case 'invalid-email':
          errorMessage = 'Email inválido';
          break;
        case 'weak-password':
          errorMessage = 'Palavra-passe muito fraca';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Operação não permitida';
          break;
        default:
          errorMessage = 'Erro: ${e.message}';
      }

      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('Erro inesperado: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
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

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _limparFormulario() {
    _formKey.currentState?.reset();
    _nomeController.clear();
    _emailController.clear();
    _telefoneController.clear();
    _emergenciaController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _tshirtSize = 'M';
      _autoValidate = false;
    });
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[700]),
      prefixIcon: Icon(icon, color: colorScheme.primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Novo Utilizador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _limparFormulario,
            tooltip: 'Limpar formulário',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode:
              _autoValidate
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card com informação do tipo de utilizador
              Card(
                color: colorScheme.primaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        _tipoSelecionado == 'admin'
                            ? Icons.admin_panel_settings
                            : Icons.person,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tipo de Utilizador',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              _tipoSelecionado == 'admin' ? 'Admin' : 'Staff',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _tipoSelecionado =
                                _tipoSelecionado == 'admin' ? 'staff' : 'admin';
                          });
                        },
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Alterar'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Dados Pessoais
              Text(
                'Dados Pessoais',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Nome
              TextFormField(
                controller: _nomeController,
                decoration: _inputDecoration('Nome Completo', Icons.person),
                textCapitalization: TextCapitalization.words,
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Nome é obrigatório'
                            : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('Email', Icons.email),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email é obrigatório';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Telefone
              TextFormField(
                controller: _telefoneController,
                decoration: _inputDecoration('Telefone', Icons.phone),
                keyboardType: TextInputType.phone,
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Telefone é obrigatório'
                            : null,
              ),
              const SizedBox(height: 16),

              // Contacto de Emergência
              TextFormField(
                controller: _emergenciaController,
                decoration: _inputDecoration(
                  'Contacto de Emergência',
                  Icons.emergency,
                ),
                keyboardType: TextInputType.phone,
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Contacto de emergência é obrigatório'
                            : null,
              ),
              const SizedBox(height: 16),

              // Tamanho T-shirt
              DropdownButtonFormField<String>(
                initialValue: _tshirtSize,
                decoration: _inputDecoration(
                  'Tamanho T-Shirt',
                  Icons.checkroom,
                ),
                items:
                    _tshirtSizes.map((size) {
                      return DropdownMenuItem(value: size, child: Text(size));
                    }).toList(),
                onChanged: (value) => setState(() => _tshirtSize = value!),
              ),

              const SizedBox(height: 24),

              // Segurança
              Text(
                'Segurança',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Palavra-passe
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration(
                  'Palavra-passe',
                  Icons.lock,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 8),

              // Indicadores de força de senha
              if (_passwordController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPasswordStrengthIndicator(),
                      const SizedBox(height: 8),
                      _buildPasswordRequirements(),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Confirmar Palavra-passe
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: _inputDecoration(
                  'Confirmar Palavra-passe',
                  Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirme a palavra-passe';
                  }
                  if (value != _passwordController.text) {
                    return 'As palavras-passe não coincidem';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Botão Criar
              ElevatedButton(
                onPressed: _isLoading ? null : _criarUser,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text(
                          'Criar Utilizador',
                          style: TextStyle(fontSize: 16),
                        ),
              ),

              const SizedBox(height: 16),

              // Botão Cancelar
              OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    int strength = 0;

    if (password.length >= 6) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    Color strengthColor = Colors.red;
    String strengthText = 'Fraca';

    if (strength >= 3) {
      strengthColor = Colors.orange;
      strengthText = 'Média';
    }
    if (strength >= 4) {
      strengthColor = Colors.green;
      strengthText = 'Forte';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Força: $strengthText',
          style: TextStyle(
            fontSize: 12,
            color: strengthColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: strength / 4,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirement('Mínimo 6 caracteres', password.length >= 6),
        _buildRequirement(
          'Uma letra maiúscula',
          password.contains(RegExp(r'[A-Z]')),
        ),
        _buildRequirement('Um número', password.contains(RegExp(r'[0-9]'))),
      ],
    );
  }

  Widget _buildRequirement(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: met ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: met ? Colors.green : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
