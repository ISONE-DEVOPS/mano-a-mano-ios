import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();
  final _firebaseService = FirebaseService();
  bool _loading = false;
  String? _message;

  void _resetPassword() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    final email = _emailController.text.trim();
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() {
        _loading = false;
        _message = 'Por favor, insira um email válido.';
      });
      return;
    }

    final exists = await _firebaseService.emailExists(email);

    if (!exists) {
      setState(() {
        _loading = false;
        _message = 'Este email não está registado. Por favor, crie uma conta.';
      });
      return;
    }

    final success = await _firebaseService.sendPasswordResetEmail(email);
    setState(() {
      _loading = false;
      _message =
          success
              ? 'Instruções enviadas para $email.'
              : 'Erro ao enviar email de recuperação.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Recuperar Senha',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Informe seu email e enviaremos instruções para redefinir sua senha.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => !_loading ? _resetPassword() : null,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _resetPassword,
                child:
                    _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Enviar link de redefinição'),
              ),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _message!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
