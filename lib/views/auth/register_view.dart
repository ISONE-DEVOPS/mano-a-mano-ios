import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../payment/payment_view.dart';
import 'user_summary_view.dart';
import 'dart:developer' as developer;

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _carModelController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _teamNameController = TextEditingController();
  final _firebaseService = FirebaseService();

  final List<String> _shirtSizes = ['S', 'M', 'L', 'XL', 'XXL'];
  String? _selectedShirtSize;

  List<Map<String, TextEditingController>> passageirosControllers = [];

  bool _loading = false;
  String? _error;
  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final PageController _pageController = PageController();
  int _currentStep = 0;
  late AnimationController _animationController;

  String? _selectedEventId;
  String? _selectedEventPath; // ex.: editions/{editionId}/events/{eventId}
  String? _activeEventName;

  static const Color shellYellow = Color(0xFFFFCB05);
  static const Color shellRed = Color(0xFFDD1D21);
  static const Color shellOrange = Color(0xFFFF6F00);

  @override
  void initState() {
    super.initState();
    _loadAcceptedTerms();
    _loadActiveEvent();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _licensePlateController.dispose();
    _carModelController.dispose();
    _emergencyContactController.dispose();
    _teamNameController.dispose();
    for (var p in passageirosControllers) {
      p['nome']?.dispose();
      p['telefone']?.dispose();
      p['tshirt']?.dispose();
    }
    super.dispose();
  }

  // Método para obter padding responsivo
  double _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 16.0;
    if (width < 600) return 20.0;
    if (width < 900) return 32.0;
    return 48.0;
  }

  // Método para obter tamanho de fonte responsivo
  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSize * 0.85;
    if (width < 600) return baseSize;
    return baseSize * 1.1;
  }

  // Método para obter espaçamento responsivo
  double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSpacing * 0.75;
    if (width < 600) return baseSpacing;
    return baseSpacing * 1.2;
  }

  Future<void> _loadAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('acceptedTerms') ?? false;
    if (mounted) {
      setState(() => _acceptedTerms = accepted);
    }
  }

  Future<void> _loadActiveEvent() async {
    try {
      final q =
          await FirebaseFirestore.instance
              .collectionGroup('events')
              .where('status', isEqualTo: true)
              .limit(1)
              .get();
      if (q.docs.isNotEmpty) {
        final d = q.docs.first;
        final path = d.reference.path; // editions/{editionId}/events/{eventId}
        final data = d.data() as Map<String, dynamic>?;
        final parentEditionRef = d.reference.parent.parent;
        String? editionName;
        if (parentEditionRef != null) {
          final editionSnap = await parentEditionRef.get();
          if (editionSnap.exists) {
            final editionData = editionSnap.data() as Map<String, dynamic>?;
            editionName = (editionData?['name'] ?? editionData?['nome'])?.toString();
          }
        }
        final nome = (data?['name'] ?? data?['nome'] ?? editionName ?? '').toString();
        if (mounted) {
          setState(() {
            _selectedEventPath = path;
            _selectedEventId = d.id;
            _activeEventName = nome;
          });
        }
        developer.log(
          'Evento ativo carregado: $_activeEventName ($_selectedEventId) em $_selectedEventPath',
        );
      } else {
        developer.log(
          'Nenhum evento ativo encontrado (status==true em collectionGroup).',
        );
      }
    } catch (e) {
      developer.log('Falha ao carregar evento ativo: $e');
    }
  }

  void _register() async {
    debugPrint('▶️ Método _register() iniciado');

    final equipasSnapshot =
        await FirebaseFirestore.instance.collection('equipas').get();
    final totalEquipas = equipasSnapshot.size;

    if (totalEquipas >= 42) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/closed');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      if (!mounted) return;
      setState(() => _error = 'As senhas não coincidem');
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _emergencyContactController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty ||
        _licensePlateController.text.trim().isEmpty ||
        _carModelController.text.trim().isEmpty ||
        _teamNameController.text.trim().isEmpty ||
        _selectedShirtSize == null ||
        _selectedEventId == null) {
      if (!mounted) return;
      setState(
        () => _error = 'Por favor preencha todos os campos obrigatórios.',
      );
      return;
    }

    for (final passageiro in passageirosControllers) {
      if (passageiro['nome']!.text.trim().isEmpty ||
          passageiro['telefone']!.text.trim().isEmpty ||
          passageiro['tshirt']!.text.trim().isEmpty) {
        if (!mounted) return;
        setState(() => _error = 'Preencha todos os dados dos passageiros.');
        return;
      }
    }

    debugPrint('✔️ Validações concluídas, iniciando criação de conta');

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String uid;
      try {
        uid = await _firebaseService.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        debugPrint('✅ signUp retornou UID: $uid');
      } catch (e) {
        debugPrint('❌ Erro durante signUp: $e');
        if (!mounted) return;
        setState(() => _error = 'Erro ao criar utilizador: ${e.toString()}');
        return;
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final confirmedUser = FirebaseAuth.instance.currentUser;
      debugPrint('✅ UID após delay: ${confirmedUser?.uid}');

      if (uid.isEmpty) {
        if (!mounted) return;
        setState(
          () => _error = 'Erro: UID inválido. Utilizador não autenticado.',
        );
        return;
      }

      final passageiros =
          passageirosControllers
              .map(
                (p) => {
                  'nome': p['nome']!.text,
                  'telefone': p['telefone']!.text,
                  'tshirt': p['tshirt']!.text,
                },
              )
              .toList();

      final eventDoc =
          await FirebaseFirestore.instance.doc(_selectedEventPath!).get();
      if (!mounted) return;
      if (!eventDoc.exists) {
        setState(() => _error = 'Evento selecionado inválido.');
        return;
      }
      final Map<String, dynamic> data = eventDoc.data()!;
      String? editionName;
      final parentEditionRef = eventDoc.reference.parent.parent;
      if (parentEditionRef != null) {
        final editionSnap = await parentEditionRef.get();
        if (editionSnap.exists) {
          final editionData = editionSnap.data() as Map<String, dynamic>?;
          editionName = (editionData?['name'] ?? editionData?['nome'])?.toString();
        }
      }
      final nomeEvento =
          (data['nome'] ?? data['name'] ?? editionName ?? 'Sem nome').toString();
      final price = double.tryParse('${data['price'] ?? '0'}') ?? 0;

      final veiculoId =
          FirebaseFirestore.instance.collection('veiculos').doc().id;
      final equipaId =
          FirebaseFirestore.instance.collection('equipas').doc().id;

      final carData = {
        'ownerId': uid,
        'matricula': _licensePlateController.text.trim(),
        'modelo': _carModelController.text.trim(),
        'nome_equipa': _teamNameController.text.trim(),
        'passageiros': passageiros,
        'pontuacao_total': 0,
        'checkpoints': {},
      };

      await FirebaseFirestore.instance
          .collection('veiculos')
          .doc(veiculoId)
          .set(carData);
      debugPrint('✅ Documento do carro criado em /veiculos/$veiculoId');

      final equipaData = {
        'nome': _teamNameController.text.trim(),
        'hino': '',
        'bandeiraUrl': '',
        'pontuacaoTotal': 0,
        'ranking': 0,
        'membros': [uid, ...passageiros.map((p) => p['telefone'])],
      };

      await FirebaseFirestore.instance
          .collection('equipas')
          .doc(equipaId)
          .set(equipaData);
      debugPrint('✅ Documento da equipa criado em /equipas/$equipaId');

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'nome': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'telefone': _phoneController.text.trim(),
        'emergencia': _emergencyContactController.text.trim(),
        'tshirt': _selectedShirtSize ?? '',
        'role': 'user',
        'eventoId': _selectedEventPath,
        'eventoNome': nomeEvento,
        'ativo': true,
        'veiculoId': veiculoId,
        'equipaId': equipaId,
        'checkpointsVisitados': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Documento do utilizador criado em /users/$uid');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('events')
          .doc(_selectedEventId)
          .set({'eventoId': _selectedEventId, 'checkpointsVisitados': []});
      debugPrint('✅ Subcoleção events criada com sucesso');

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'ultimoLogin': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('acceptedTerms', true);

      if (!mounted) return;
      if (price > 0) {
        Get.to(() => PaymentView(eventId: _selectedEventId!, amount: price));
      } else {
        Get.offAll(
          () => UserSummaryView(
            nome: _nameController.text.trim(),
            email: _emailController.text.trim(),
            telefone: _phoneController.text.trim(),
            emergencia: _emergencyContactController.text.trim(),
            equipa: _teamNameController.text.trim(),
            tShirt: _selectedShirtSize ?? '',
            eventoNome: nomeEvento,
          ),
        );
      }
    } on FirebaseAuthException catch (authError) {
      if (!mounted) return;
      if (authError.code == 'email-already-in-use') {
        setState(
          () => _error = 'Este e-mail já está registado. Por favor faça login.',
        );
      } else {
        setState(() => _error = authError.message ?? 'Erro de autenticação.');
      }
    } catch (e) {
      debugPrint('❌ Erro capturado no register: $e');
      if (!mounted) return;
      setState(() => _error = 'Erro ao criar conta: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildStepIndicator(BuildContext context) {
    final padding = _getResponsivePadding(context);
    final spacing = _getResponsiveSpacing(context, 20);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [shellRed, shellOrange, shellYellow],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(spacing * 1.6),
          bottomRight: Radius.circular(spacing * 1.6),
        ),
        boxShadow: [
          BoxShadow(
            color: shellRed.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.jpeg',
                width: _getResponsiveSpacing(context, 50),
                height: _getResponsiveSpacing(context, 50),
              ),
              SizedBox(width: _getResponsiveSpacing(context, 12)),
              Text(
                'Criar Conta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _getResponsiveFontSize(context, 24),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          Row(
            children: List.generate(4, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                  decoration: BoxDecoration(
                    color:
                        isCompleted || isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: _getResponsiveSpacing(context, 12)),
          Text(
            _getStepTitle(_currentStep),
            style: TextStyle(
              color: Colors.white,
              fontSize: _getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Dados Pessoais';
      case 1:
        return 'Dados do Veículo';
      case 2:
        return 'Passageiros';
      case 3:
        return 'Evento e Confirmação';
      default:
        return '';
    }
  }

  Widget _inputCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? hintText,
    bool isRequired = false,
    bool isError = false,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
  }) {
    final spacing = _getResponsiveSpacing(context, 16);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing),
        color: Colors.white,
        border: Border.all(
          color: isError ? shellRed : Colors.grey.shade200,
          width: isError ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isError
                    ? shellRed.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.only(bottom: spacing),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(fontSize: _getResponsiveFontSize(context, 15)),
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: isError ? shellRed : shellOrange,
            size: _getResponsiveSpacing(context, 22),
          ),
          suffixIcon: suffixIcon,
          labelText: isRequired ? '$label *' : label,
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: _getResponsiveFontSize(context, 14),
          ),
          labelStyle: TextStyle(
            color: isError ? shellRed : Colors.grey.shade700,
            fontSize: _getResponsiveFontSize(context, 14),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacing,
            vertical: spacing,
          ),
        ),
      ),
    );
  }

  Widget _buildStepCondutor() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = _getResponsivePadding(context);
        final spacing = _getResponsiveSpacing(context, 24);

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _inputCard(
                  context: context,
                  icon: Icons.person_outline,
                  label: 'Nome Completo',
                  controller: _nameController,
                  hintText: 'Ex: João Silva',
                  isRequired: true,
                  isError:
                      _error != null && _nameController.text.trim().isEmpty,
                ),
                _inputCard(
                  context: context,
                  icon: Icons.phone_outlined,
                  label: 'Telefone',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  hintText: 'Ex: 912345678',
                  isRequired: true,
                  isError:
                      _error != null && _phoneController.text.trim().isEmpty,
                ),
                _inputCard(
                  context: context,
                  icon: Icons.emergency_outlined,
                  label: 'Contato de Emergência',
                  controller: _emergencyContactController,
                  keyboardType: TextInputType.phone,
                  hintText: 'Ex: 991234567',
                  isRequired: true,
                  isError:
                      _error != null &&
                      _emergencyContactController.text.trim().isEmpty,
                ),
                _inputCard(
                  context: context,
                  icon: Icons.email_outlined,
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  hintText: 'exemplo@email.com',
                  isRequired: true,
                  isError:
                      _error != null && _emailController.text.trim().isEmpty,
                ),
                _inputCard(
                  context: context,
                  icon: Icons.lock_outline,
                  label: 'Senha',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  hintText: 'Mínimo 6 caracteres',
                  isRequired: true,
                  isError:
                      _error != null && _passwordController.text.trim().isEmpty,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey.shade600,
                      size: _getResponsiveSpacing(context, 20),
                    ),
                    onPressed:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  ),
                ),
                _inputCard(
                  context: context,
                  icon: Icons.lock_outline,
                  label: 'Confirmar Senha',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  hintText: 'Repita a senha',
                  isRequired: true,
                  isError:
                      _error != null &&
                      _confirmPasswordController.text.trim().isEmpty,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey.shade600,
                      size: _getResponsiveSpacing(context, 20),
                    ),
                    onPressed:
                        () => setState(
                          () =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                        ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      _getResponsiveSpacing(context, 16),
                    ),
                    color: Colors.white,
                    border: Border.all(
                      color:
                          (_error != null && _selectedShirtSize == null)
                              ? shellRed
                              : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveSpacing(context, 16),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedShirtSize,
                    items:
                        _shirtSizes.map((size) {
                          return DropdownMenuItem(
                            value: size,
                            child: Text(size),
                          );
                        }).toList(),
                    onChanged:
                        (val) => setState(() => _selectedShirtSize = val),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.checkroom_outlined,
                        color: shellOrange,
                        size: _getResponsiveSpacing(context, 22),
                      ),
                      labelText: 'Tamanho da T-shirt *',
                      labelStyle: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 14),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(height: spacing),
                _buildNavigationButtons(
                  context: context,
                  showBack: false,
                  onNext: () {
                    if (_nameController.text.trim().isEmpty ||
                        _phoneController.text.trim().isEmpty ||
                        _emergencyContactController.text.trim().isEmpty ||
                        _emailController.text.trim().isEmpty ||
                        _passwordController.text.trim().isEmpty ||
                        _confirmPasswordController.text.trim().isEmpty ||
                        _selectedShirtSize == null) {
                      setState(
                        () => _error = 'Preencha todos os campos obrigatórios.',
                      );
                      return;
                    }
                    setState(() {
                      _error = null;
                      _currentStep = 1;
                    });
                    _pageController.jumpToPage(1);
                  },
                ),
                if (_error != null) ...[
                  SizedBox(height: _getResponsiveSpacing(context, 16)),
                  Container(
                    padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
                    decoration: BoxDecoration(
                      color: shellRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        _getResponsiveSpacing(context, 12),
                      ),
                      border: Border.all(color: shellRed),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: shellRed,
                          size: _getResponsiveSpacing(context, 24),
                        ),
                        SizedBox(width: _getResponsiveSpacing(context, 12)),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: shellRed,
                              fontWeight: FontWeight.w500,
                              fontSize: _getResponsiveFontSize(context, 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepCarro() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = _getResponsivePadding(context);
        final spacing = _getResponsiveSpacing(context, 24);

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                _inputCard(
                  context: context,
                  icon: Icons.directions_car_outlined,
                  label: 'Matrícula',
                  controller: _licensePlateController,
                  hintText: 'Ex: AB-12-CD',
                  isRequired: true,
                  isError:
                      _error != null &&
                      _licensePlateController.text.trim().isEmpty,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(8),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final digitsOnly =
                          newValue.text
                              .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
                              .toUpperCase();
                      final buffer = StringBuffer();
                      for (int i = 0; i < digitsOnly.length; i++) {
                        buffer.write(digitsOnly[i]);
                        if ((i + 1) % 2 == 0 && i < 5) buffer.write('-');
                      }
                      final newText = buffer.toString();
                      return TextEditingValue(
                        text: newText,
                        selection: TextSelection.collapsed(
                          offset: newText.length,
                        ),
                      );
                    }),
                  ],
                ),
                _inputCard(
                  context: context,
                  icon: Icons.drive_eta_outlined,
                  label: 'Modelo do Veículo',
                  controller: _carModelController,
                  hintText: 'Ex: Toyota Corolla',
                  isRequired: true,
                  isError:
                      _error != null && _carModelController.text.trim().isEmpty,
                ),
                _inputCard(
                  context: context,
                  icon: Icons.group_outlined,
                  label: 'Nome da Equipa',
                  controller: _teamNameController,
                  hintText: 'Ex: Os Velozes',
                  isRequired: true,
                  isError:
                      _error != null && _teamNameController.text.trim().isEmpty,
                ),
                SizedBox(height: spacing),
                _buildNavigationButtons(
                  context: context,
                  showBack: true,
                  onBack: () {
                    setState(() {
                      _error = null;
                      _currentStep = 0;
                    });
                    _pageController.jumpToPage(0);
                  },
                  onNext: () {
                    if (_licensePlateController.text.trim().isEmpty ||
                        _carModelController.text.trim().isEmpty ||
                        _teamNameController.text.trim().isEmpty) {
                      setState(
                        () => _error = 'Preencha todos os campos obrigatórios.',
                      );
                      return;
                    }
                    setState(() {
                      _error = null;
                      _currentStep = 2;
                    });
                    _pageController.jumpToPage(2);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepPassageiros() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = _getResponsivePadding(context);
        final spacing = _getResponsiveSpacing(context, 20);

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adicione os passageiros',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 22),
                    fontWeight: FontWeight.bold,
                    color: shellRed,
                  ),
                ),
                Text(
                  'Máximo de 4 passageiros',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: _getResponsiveFontSize(context, 14),
                  ),
                ),
                SizedBox(height: spacing),
                ...List.generate(passageirosControllers.length, (i) {
                  return Container(
                    margin: EdgeInsets.only(
                      bottom: _getResponsiveSpacing(context, 16),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(spacing),
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(
                            _getResponsiveSpacing(context, 16),
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                shellYellow.withValues(alpha: 0.3),
                                shellOrange.withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(spacing),
                              topRight: Radius.circular(spacing),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                      _getResponsiveSpacing(context, 8),
                                    ),
                                    decoration: BoxDecoration(
                                      color: shellOrange,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: _getResponsiveSpacing(context, 20),
                                    ),
                                  ),
                                  SizedBox(
                                    width: _getResponsiveSpacing(context, 12),
                                  ),
                                  Text(
                                    'Passageiro ${i + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: _getResponsiveFontSize(
                                        context,
                                        16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: shellRed,
                                  size: _getResponsiveSpacing(context, 24),
                                ),
                                onPressed:
                                    () => setState(
                                      () => passageirosControllers.removeAt(i),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(
                            _getResponsiveSpacing(context, 16),
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: passageirosControllers[i]['nome'],
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 15),
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    size: _getResponsiveSpacing(context, 20),
                                  ),
                                  labelText: 'Nome *',
                                  hintText: 'Ex: Maria Silva',
                                  labelStyle: TextStyle(
                                    fontSize: _getResponsiveFontSize(
                                      context,
                                      14,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      _getResponsiveSpacing(context, 12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: _getResponsiveSpacing(context, 12),
                              ),
                              TextField(
                                controller:
                                    passageirosControllers[i]['telefone'],
                                keyboardType: TextInputType.phone,
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 15),
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.phone_outlined,
                                    size: _getResponsiveSpacing(context, 20),
                                  ),
                                  labelText: 'Telefone *',
                                  hintText: 'Ex: 912345678',
                                  labelStyle: TextStyle(
                                    fontSize: _getResponsiveFontSize(
                                      context,
                                      14,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      _getResponsiveSpacing(context, 12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: _getResponsiveSpacing(context, 12),
                              ),
                              DropdownButtonFormField<String>(
                                initialValue:
                                    passageirosControllers[i]['tshirt']!
                                            .text
                                            .isNotEmpty
                                        ? passageirosControllers[i]['tshirt']!
                                            .text
                                        : null,
                                items:
                                    _shirtSizes.map((size) {
                                      return DropdownMenuItem(
                                        value: size,
                                        child: Text(
                                          size,
                                          style: TextStyle(
                                            fontSize: _getResponsiveFontSize(
                                              context,
                                              15,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  setState(
                                    () =>
                                        passageirosControllers[i]['tshirt']!
                                            .text = val ?? '',
                                  );
                                },
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.checkroom_outlined,
                                    size: _getResponsiveSpacing(context, 20),
                                  ),
                                  labelText: 'T-shirt *',
                                  labelStyle: TextStyle(
                                    fontSize: _getResponsiveFontSize(
                                      context,
                                      14,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      _getResponsiveSpacing(context, 12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (passageirosControllers.length < 4)
                  Container(
                    width: double.infinity,
                    height: _getResponsiveSpacing(context, 56),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        _getResponsiveSpacing(context, 16),
                      ),
                      border: Border.all(color: shellOrange, width: 2),
                      color: shellYellow.withValues(alpha: 0.1),
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          passageirosControllers.add({
                            'nome': TextEditingController(),
                            'telefone': TextEditingController(),
                            'tshirt': TextEditingController(),
                          });
                        });
                      },
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: shellOrange,
                        size: _getResponsiveSpacing(context, 24),
                      ),
                      label: Text(
                        'Adicionar Passageiro',
                        style: TextStyle(
                          color: shellOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: _getResponsiveFontSize(context, 16),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: _getResponsiveSpacing(context, 24)),
                _buildNavigationButtons(
                  context: context,
                  showBack: true,
                  onBack: () {
                    setState(() {
                      _error = null;
                      _currentStep = 1;
                    });
                    _pageController.jumpToPage(1);
                  },
                  onNext: () {
                    if (passageirosControllers.isEmpty) {
                      setState(
                        () => _error = 'Adicione pelo menos 1 passageiro.',
                      );
                      return;
                    }
                    for (final passageiro in passageirosControllers) {
                      if (passageiro['nome']!.text.trim().isEmpty ||
                          passageiro['telefone']!.text.trim().isEmpty ||
                          passageiro['tshirt']!.text.trim().isEmpty) {
                        setState(
                          () =>
                              _error =
                                  'Preencha todos os dados dos passageiros.',
                        );
                        return;
                      }
                    }
                    setState(() {
                      _error = null;
                      _currentStep = 3;
                    });
                    _pageController.jumpToPage(3);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper to fetch active events with edition names and labels.
  Future<List<Map<String, String>>> _fetchActiveEventOptions() async {
    final qs = await FirebaseFirestore.instance
        .collectionGroup('events')
        .where('status', isEqualTo: true)
        .get();

    final List<Map<String, String>> results = [];
    for (final d in qs.docs) {
      final eventPath = d.reference.path; // editions/{editionId}/events/{eventId}
      final data = d.data() as Map<String, dynamic>;
      final eventName = (data['name'] ?? data['nome'] ?? 'Evento sem nome').toString();

      String editionName = '';
      final parentEditionRef = d.reference.parent.parent;
      if (parentEditionRef != null) {
        final editionSnap = await parentEditionRef.get();
        if (editionSnap.exists) {
          final ed = editionSnap.data() as Map<String, dynamic>?;
          editionName = (ed?['name'] ?? ed?['nome'] ?? '').toString();
        }
      }

      final label = (editionName.isNotEmpty)
          ? '$editionName – $eventName'
          : eventName;

      results.add({
        'path': eventPath,
        'label': label,
        'eventId': d.id,
      });
    }
    // Optional: sort by label for consistency
    results.sort((a, b) => a['label']!.compareTo(b['label']!));
    return results;
  }

  Widget _buildStepEvento() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = _getResponsivePadding(context);
        final spacing = _getResponsiveSpacing(context, 20);

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecione o Evento',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 22),
                    fontWeight: FontWeight.bold,
                    color: shellRed,
                  ),
                ),
                SizedBox(height: spacing),
                FutureBuilder<List<Map<String, String>>>(
                  future: _fetchActiveEventOptions(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final options = snapshot.data!;
                    if (options.isEmpty) {
                      return Container(
                        padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(_getResponsiveSpacing(context, 16)),
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          'Nenhum evento ativo no momento.',
                          style: TextStyle(fontSize: _getResponsiveFontSize(context, 14)),
                        ),
                      );
                    }

                    final items = options.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt['path'],
                        child: Text(
                          opt['label'] ?? '',
                          style: TextStyle(fontSize: _getResponsiveFontSize(context, 15)),
                        ),
                      );
                    }).toList();

                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_getResponsiveSpacing(context, 16)),
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: _getResponsiveSpacing(context, 16),
                      ),
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('event_${_selectedEventPath ?? 'null'}_${items.length}'),
                        isExpanded: true,
                        initialValue: _selectedEventPath,
                        hint: Text(
                          'Escolha um evento',
                          style: TextStyle(fontSize: _getResponsiveFontSize(context, 14)),
                        ),
                        items: items,
                        onChanged: (val) => setState(() {
                          _selectedEventPath = val;
                          _selectedEventId = val?.split('/').last;
                        }),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.event_outlined,
                            size: _getResponsiveSpacing(context, 22),
                          ),
                          border: InputBorder.none,
                          labelText: 'Evento *',
                          labelStyle: TextStyle(fontSize: _getResponsiveFontSize(context, 14)),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: _getResponsiveSpacing(context, 24)),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      _getResponsiveSpacing(context, 16),
                    ),
                    color: shellYellow.withValues(alpha: 0.1),
                    border: Border.all(
                      color: shellYellow.withValues(alpha: 0.5),
                    ),
                  ),
                  child: CheckboxListTile(
                    value: _acceptedTerms,
                    onChanged:
                        (value) =>
                            setState(() => _acceptedTerms = value ?? false),
                    activeColor: shellOrange,
                    title: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: _getResponsiveFontSize(context, 14),
                        ),
                        children: [
                          const TextSpan(text: 'Li e aceito os '),
                          TextSpan(
                            text: 'Termos e Condições',
                            style: TextStyle(
                              color: shellOrange,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer:
                                TapGestureRecognizer()
                                  ..onTap = () => Get.toNamed('/terms'),
                          ),
                          const TextSpan(text: ' e a '),
                          TextSpan(
                            text: 'Política de Privacidade',
                            style: TextStyle(
                              color: shellOrange,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer:
                                TapGestureRecognizer()
                                  ..onTap = () => Get.toNamed('/privacy'),
                          ),
                        ],
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                SizedBox(height: _getResponsiveSpacing(context, 24)),
                _buildNavigationButtons(
                  context: context,
                  showBack: true,
                  onBack: () {
                    setState(() {
                      _error = null;
                      _currentStep = 2;
                    });
                    _pageController.jumpToPage(2);
                  },
                  onNext: () {
                    if (_selectedEventPath == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecione um evento.')),
                      );
                      return;
                    }
                    if (!_acceptedTerms) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Aceite os termos para continuar.'),
                        ),
                      );
                      return;
                    }
                    _register();
                  },
                  isLastStep: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationButtons({
    required BuildContext context,
    bool showBack = true,
    VoidCallback? onBack,
    VoidCallback? onNext,
    bool isLastStep = false,
  }) {
    final spacing = _getResponsiveSpacing(context, 16);
    final buttonHeight = _getResponsiveSpacing(context, 56);

    return Row(
      children: [
        if (showBack)
          Expanded(
            child: Container(
              height: buttonHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(spacing),
                border: Border.all(color: shellOrange, width: 2),
              ),
              child: TextButton(
                onPressed: _loading ? null : onBack,
                child: Text(
                  'Voltar',
                  style: TextStyle(
                    color: shellOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: _getResponsiveFontSize(context, 16),
                  ),
                ),
              ),
            ),
          ),
        if (showBack) SizedBox(width: spacing),
        Expanded(
          flex: showBack ? 1 : 2,
          child: Container(
            height: buttonHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [shellRed, shellOrange]),
              borderRadius: BorderRadius.circular(spacing),
              boxShadow: [
                BoxShadow(
                  color: shellOrange.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _loading ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing),
                ),
              ),
              child:
                  _loading
                      ? SizedBox(
                        width: _getResponsiveSpacing(context, 24),
                        height: _getResponsiveSpacing(context, 24),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Text(
                        isLastStep ? 'Finalizar' : 'Continuar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: _getResponsiveFontSize(context, 16),
                        ),
                      ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(context),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStepCondutor(),
                  _buildStepCarro(),
                  _buildStepPassageiros(),
                  _buildStepEvento(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
