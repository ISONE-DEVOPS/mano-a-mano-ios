import 'package:flutter/material.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../services/firebase_service.dart';
import '../dashboard/home_view.dart';
import '../../screens/permission_screen.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firebaseService = FirebaseService();
  bool _loading = false;
  String? _error;
  bool _showPassword = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
    });
  }

  Future<void> _saveRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', value);
  }

  void _goToPermissions(String role) {
    Get.to(
      () => PermissionScreen(
        onContinue: () {
          if (role == 'admin') {
            Get.offAllNamed('/admin');
          } else if (role == 'staff') {
            Get.offAllNamed('/staff');
            return;
          } else {
            Get.offAll(() => const HomeView());
          }
        },
      ),
    );
  }

  void _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final user = await _firebaseService.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() => _loading = false);
    if (user != null) {
      // Buscar perfil do usuário para verificar o role
      final userData = await _firebaseService.getUserData(user.uid);
      await _firebaseService.updateUltimoLogin(user.uid);
      final role = userData?['role'] ?? 'user';
      if (role == 'admin') {
        Get.offAllNamed('/admin');
      } else if (role == 'staff') {
        Get.offAllNamed('/staff');
      } else {
        _goToPermissions(role);
      }
    } else {
      setState(() => _error = 'Credenciais inválidas');
    }
  }

  Widget _buildLoginForm(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Column(
        children: [
          // Logo e Bem-vindo
          const SizedBox(height: 40),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/images/Logo_Shell_KM.png',
              width: 90,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bem-vindo(a)!',
            style: textTheme.titleLarge?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Entre com sua conta ou registre-se para participar dos eventos Shell ao KM.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Formulário
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Digite seu email',
                    hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: colorScheme.onSurface,
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    hintText: 'Digite sua senha',
                    hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: colorScheme.onSurface,
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                        color: colorScheme.onSurface,
                      ),
                      onPressed:
                          () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  style: textTheme.bodyLarge,
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (v) {
                        final newValue = v ?? false;
                        setState(() => _rememberMe = newValue);
                        _saveRememberMe(newValue);
                      },
                      activeColor: colorScheme.primary,
                    ),
                    Text('Lembrar-me', style: textTheme.bodyMedium),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Get.toNamed('/forgot-password');
                      },
                      child: Text(
                        'Esqueceu a senha?',
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: textTheme.bodyMedium?.copyWith(fontSize: 13),
                          children: [
                            const TextSpan(text: 'Aceito os '),
                            TextSpan(
                              text: 'Termos e Condições',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: colorScheme.secondary,
                              ),
                              recognizer:
                                  TapGestureRecognizer()
                                    ..onTap = () {
                                      Get.toNamed('/terms');
                                    },
                            ),
                            const TextSpan(text: ' e a '),
                            TextSpan(
                              text: 'Política de Privacidade',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: colorScheme.secondary,
                              ),
                              recognizer:
                                  TapGestureRecognizer()
                                    ..onTap = () {
                                      Get.toNamed('/privacy');
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child:
                        _loading
                            ? const CircularProgressIndicator(
                              color: Colors.black,
                            )
                            : Text('Entrar', style: textTheme.bodyLarge),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Get.toNamed('/criar-conta');
                  },
                  child: Text(
                    'Não tem uma conta? Criar uma conta',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SizedBox(
            width: 420,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _buildLoginForm(context),
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _buildLoginForm(context)),
    );
  }
}
