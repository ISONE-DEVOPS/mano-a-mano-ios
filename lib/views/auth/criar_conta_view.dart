import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';

class CriarContaView extends StatefulWidget {
  const CriarContaView({super.key});

  @override
  State<CriarContaView> createState() => _CriarContaViewState();
}

class _CriarContaViewState extends State<CriarContaView> {
  final _formKey = GlobalKey<FormState>();
  String nome = '',
      email = '',
      telefone = '',
      password = '',
      confirmarPassword = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nome Completo'),
                validator: (val) => val!.isEmpty ? 'Campo obrigatório' : null,
                onChanged: (val) => nome = val,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                validator:
                    (val) => !val!.contains('@') ? 'Email inválido' : null,
                onChanged: (val) => email = val,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Telefone (opcional)',
                ),
                onChanged: (val) => telefone = val,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Palavra-passe'),
                obscureText: true,
                validator:
                    (val) => val!.length < 6 ? 'Mínimo 6 caracteres' : null,
                onChanged: (val) => password = val,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Confirmar Palavra-passe',
                ),
                obscureText: true,
                validator:
                    (val) =>
                        val != password ? 'Palavra-passe não coincide' : null,
                onChanged: (val) => confirmarPassword = val,
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() => isLoading = true);
                        final success = await AuthService().registerWithEmail(
                          nome,
                          email,
                          password,
                        );
                        setState(() => isLoading = false);
                        if (success) {
                          Get.snackbar(
                            'Conta Criada',
                            'Bem-vindo(a) ao Shell ao KM',
                          );
                          Get.offAllNamed('/home');
                        } else {
                          Get.snackbar('Erro', 'Falha ao criar conta');
                        }
                      }
                    },
                    child: const Text('Criar Conta'),
                  ),
              TextButton(
                onPressed: () => Get.offNamed('/login'),
                child: const Text('Já tenho conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
