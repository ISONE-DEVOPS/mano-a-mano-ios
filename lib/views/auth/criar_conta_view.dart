import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';

class CriarContaView extends StatefulWidget {
  const CriarContaView({super.key});

  @override
  State<CriarContaView> createState() => _CriarContaViewState();
}

class _CriarContaViewState extends State<CriarContaView>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String nome = '',
      email = '',
      telefone = '',
      password = '',
      confirmarPassword = '';
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _aceitarTermos = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Cores do tema Shell
  static const Color shellRed = Color(0xFFED1C24);
  static const Color shellYellow = Color(0xFFFFD200);
  static const Color darkBlue = Color(0xFF003876);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          // Logo Shell
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [shellRed, shellYellow],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: shellRed.withAlpha((0.3 * 255).toInt()),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_gas_station,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Criar Conta',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Junte-se ao Mano a Mano!',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        onChanged: onChanged,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: shellRed),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: shellRed, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey[700]),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required Function(String) onChanged,
    required String? Function(String?) validator,
    required bool obscureText,
    required VoidCallback toggleVisibility,
  }) {
    return _buildTextField(
      label: label,
      hint: hint,
      icon: Icons.lock_outline,
      onChanged: onChanged,
      validator: validator,
      obscureText: obscureText,
      suffixIcon: IconButton(
        icon: Icon(
          obscureText ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey[600],
        ),
        onPressed: toggleVisibility,
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _aceitarTermos,
            onChanged: (value) {
              setState(() {
                _aceitarTermos = value ?? false;
              });
            },
            activeColor: shellRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ao criar uma conta, você aceita nossos',
                  style: TextStyle(fontSize: 14),
                ),
                GestureDetector(
                  onTap: () {
                    // Abrir termos e condições
                  },
                  child: const Text(
                    'Termos e Condições',
                    style: TextStyle(
                      fontSize: 14,
                      color: shellRed,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: _aceitarTermos && !isLoading ? _handleCreateAccount : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: shellRed,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: shellRed.withAlpha((0.3 * 255).toInt()),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          disabledBackgroundColor: Colors.grey[300],
        ),
        child:
            isLoading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Text(
                  'Criar Conta',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Já tem uma conta? ',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          GestureDetector(
            onTap: () => Get.offNamed('/login'),
            child: const Text(
              'Entrar',
              style: TextStyle(
                fontSize: 16,
                color: shellRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreateAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        final success = await AuthService().registerWithEmail(
          nome,
          email,
          password,
        );

        if (success) {
          Get.snackbar(
            'Sucesso',
            'Conta criada com sucesso! Bem-vindo(a) ao Mano a Mano Off Road.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            icon: const Icon(Icons.check_circle, color: Colors.white),
            duration: const Duration(seconds: 3),
          );
          Get.offAllNamed('/home');
        } else {
          Get.snackbar(
            'Erro',
            'Falha ao criar conta. Tente novamente.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            icon: const Icon(Icons.error, color: Colors.white),
          );
        }
      } catch (e) {
        Get.snackbar(
          'Erro',
          'Ocorreu um erro inesperado. Tente novamente.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildHeader(),

                  _buildTextField(
                    label: 'Nome Completo',
                    hint: 'Digite seu nome completo',
                    icon: Icons.person_outline,
                    onChanged: (val) => nome = val,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Nome é obrigatório';
                      }
                      if (val.length < 2) {
                        return 'Nome deve ter pelo menos 2 caracteres';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.name,
                  ),

                  _buildTextField(
                    label: 'Email',
                    hint: 'Digite seu email',
                    icon: Icons.email_outlined,
                    onChanged: (val) => email = val,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Email é obrigatório';
                      }
                      if (!GetUtils.isEmail(val)) {
                        return 'Digite um email válido';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                  ),

                  _buildTextField(
                    label: 'Telefone',
                    hint: 'Digite seu telefone (opcional)',
                    icon: Icons.phone_outlined,
                    onChanged: (val) => telefone = val,
                    validator: (val) {
                      if (val != null && val.isNotEmpty && val.length < 7) {
                        return 'Telefone deve ter pelo menos 7 dígitos';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.phone,
                  ),

                  _buildPasswordField(
                    label: 'Palavra-passe',
                    hint: 'Digite sua palavra-passe',
                    onChanged: (val) => password = val,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Palavra-passe é obrigatória';
                      }
                      if (val.length < 6) {
                        return 'Palavra-passe deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                    obscureText: _obscurePassword,
                    toggleVisibility: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),

                  _buildPasswordField(
                    label: 'Confirmar Palavra-passe',
                    hint: 'Confirme sua palavra-passe',
                    onChanged: (val) => confirmarPassword = val,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Confirmação é obrigatória';
                      }
                      if (val != password) {
                        return 'Palavras-passe não coincidem';
                      }
                      return null;
                    },
                    obscureText: _obscureConfirmPassword,
                    toggleVisibility: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),

                  _buildTermsCheckbox(),
                  _buildCreateAccountButton(),
                  _buildLoginLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
