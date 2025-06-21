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
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late String tipoSelecionado;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    tipoSelecionado = widget.tipoInicial;
  }

  Future<void> _criarUser() async {
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
            'tipo': tipoSelecionado,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Utilizador criado com sucesso!',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
          ),
        );
        if (tipoSelecionado == 'admin') {
          Navigator.of(context).pushReplacementNamed('/admin');
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro: $e',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black),
      hintText: label,
      hintStyle: const TextStyle(color: Colors.black),
      floatingLabelStyle: const TextStyle(color: Colors.black),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.primary.withAlpha((0.5 * 255).round()),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonStyle = Theme.of(context).elevatedButtonTheme.style;

    return Scaffold(
      appBar: AppBar(title: const Text('Criar Utilizador')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: _inputDecoration('Nome', context),
                  style: const TextStyle(color: Colors.black),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Preencha o nome'
                              : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: _inputDecoration('Email', context),
                  style: const TextStyle(color: Colors.black),
                  validator:
                      (value) =>
                          value == null || !value.contains('@')
                              ? 'Email inválido'
                              : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: _inputDecoration('Palavra-passe', context),
                  style: const TextStyle(color: Colors.black),
                  validator:
                      (value) =>
                          value != null && value.length >= 6
                              ? null
                              : 'Min. 6 caracteres',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: tipoSelecionado,
                  style: const TextStyle(color: Colors.white),
                  items: [
                    DropdownMenuItem(
                      value: 'admin',
                      child: const Text(
                        'Admin',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'staff',
                      child: const Text(
                        'Staff',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                  onChanged:
                      (value) => setState(() => tipoSelecionado = value!),
                  decoration: _inputDecoration('Tipo de utilizador', context),
                  dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _criarUser,
                  style: buttonStyle,
                  child:
                      isLoading
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text('Criar Utilizador'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.person_add, color: colorScheme.onPrimary),
        label: Text(
          'Tipo de Utilizador',
          style: TextStyle(color: colorScheme.onPrimary),
        ),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.admin_panel_settings,
                        color: colorScheme.primary,
                      ),
                      title: const Text('Criar Admin'),
                      onTap: () {
                        setState(() => tipoSelecionado = 'admin');
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.person, color: colorScheme.primary),
                      title: const Text('Criar Staff'),
                      onTap: () {
                        setState(() => tipoSelecionado = 'staff');
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
