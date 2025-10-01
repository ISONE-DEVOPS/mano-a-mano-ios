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
  Map<String, dynamic>? _activeEventData;
  String? _activeEventName;

  // Cores Shell
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
              .collection('events')
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();
      if (q.docs.isNotEmpty) {
        final d = q.docs.first;
        if (mounted) {
          setState(() {
            _selectedEventId = d.id;
            _activeEventData = d.data() as Map<String, dynamic>?;
            _activeEventName =
                (_activeEventData?['name'] ?? _activeEventData?['nome'] ?? '')
                    .toString();
          });
        }
        developer.log(
          'Evento ativo carregado: $_activeEventName ($_selectedEventId)',
        );
      } else {
        developer.log('Nenhum evento ativo encontrado.');
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
          await FirebaseFirestore.instance
              .collection('events')
              .doc(_selectedEventId)
              .get();
      if (!mounted) return;
      if (!eventDoc.exists) {
        setState(() => _error = 'Evento selecionado inválido.');
        return;
      }
      final Map<String, dynamic> data = eventDoc.data()!;
      final nomeEvento =
          (data['nome'] ?? data['name'] ?? 'Sem nome').toString();
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
        'eventoId': 'events/$_selectedEventId',
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

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [shellRed, shellOrange, shellYellow],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
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
              Image.asset('assets/images/logo.jpeg', width: 50, height: 50),
              const SizedBox(width: 12),
              const Text(
                'Criar Conta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 12),
          Text(
            _getStepTitle(_currentStep),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 15),
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: isError ? shellRed : shellOrange,
            size: 22,
          ),
          suffixIcon: suffixIcon,
          labelText: isRequired ? '$label *' : label,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          labelStyle: TextStyle(
            color: isError ? shellRed : Colors.grey.shade700,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStepCondutor() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _inputCard(
              icon: Icons.person_outline,
              label: 'Nome Completo',
              controller: _nameController,
              hintText: 'Ex: João Silva',
              isRequired: true,
              isError: _error != null && _nameController.text.trim().isEmpty,
            ),
            _inputCard(
              icon: Icons.phone_outlined,
              label: 'Telefone',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              hintText: 'Ex: 912345678',
              isRequired: true,
              isError: _error != null && _phoneController.text.trim().isEmpty,
            ),
            _inputCard(
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
              icon: Icons.email_outlined,
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              hintText: 'exemplo@email.com',
              isRequired: true,
              isError: _error != null && _emailController.text.trim().isEmpty,
            ),
            _inputCard(
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
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                onPressed:
                    () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            _inputCard(
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
                  size: 20,
                ),
                onPressed:
                    () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedShirtSize,
                items:
                    _shirtSizes.map((size) {
                      return DropdownMenuItem(value: size, child: Text(size));
                    }).toList(),
                onChanged: (val) => setState(() => _selectedShirtSize = val),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.checkroom_outlined,
                    color: shellOrange,
                  ),
                  labelText: 'Tamanho da T-shirt *',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildNavigationButtons(
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: shellRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: shellRed),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: shellRed),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: shellRed,
                          fontWeight: FontWeight.w500,
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
  }

  Widget _buildStepCarro() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _inputCard(
              icon: Icons.directions_car_outlined,
              label: 'Matrícula',
              controller: _licensePlateController,
              hintText: 'Ex: AB-12-CD',
              isRequired: true,
              isError:
                  _error != null && _licensePlateController.text.trim().isEmpty,
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
                    selection: TextSelection.collapsed(offset: newText.length),
                  );
                }),
              ],
            ),
            _inputCard(
              icon: Icons.drive_eta_outlined,
              label: 'Modelo do Veículo',
              controller: _carModelController,
              hintText: 'Ex: Toyota Corolla',
              isRequired: true,
              isError:
                  _error != null && _carModelController.text.trim().isEmpty,
            ),
            _inputCard(
              icon: Icons.group_outlined,
              label: 'Nome da Equipa',
              controller: _teamNameController,
              hintText: 'Ex: Os Velozes',
              isRequired: true,
              isError:
                  _error != null && _teamNameController.text.trim().isEmpty,
            ),
            const SizedBox(height: 24),
            _buildNavigationButtons(
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
  }

  Widget _buildStepPassageiros() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adicione os passageiros',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: shellRed,
              ),
            ),
            Text(
              'Máximo de 4 passageiros',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ...List.generate(passageirosControllers.length, (i) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            shellYellow.withValues(alpha: 0.3),
                            shellOrange.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: shellOrange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Passageiro ${i + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: shellRed),
                            onPressed:
                                () => setState(
                                  () => passageirosControllers.removeAt(i),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: passageirosControllers[i]['nome'],
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                size: 20,
                              ),
                              labelText: 'Nome *',
                              hintText: 'Ex: Maria Silva',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: passageirosControllers[i]['telefone'],
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                size: 20,
                              ),
                              labelText: 'Telefone *',
                              hintText: 'Ex: 912345678',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue:
                                passageirosControllers[i]['tshirt']!
                                        .text
                                        .isNotEmpty
                                    ? passageirosControllers[i]['tshirt']!.text
                                    : null,
                            items:
                                _shirtSizes.map((size) {
                                  return DropdownMenuItem(
                                    value: size,
                                    child: Text(size),
                                  );
                                }).toList(),
                            onChanged: (val) {
                              setState(
                                () =>
                                    passageirosControllers[i]['tshirt']!.text =
                                        val ?? '',
                              );
                            },
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.checkroom_outlined,
                                size: 20,
                              ),
                              labelText: 'T-shirt *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
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
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
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
                  icon: Icon(Icons.add_circle_outline, color: shellOrange),
                  label: Text(
                    'Adicionar Passageiro',
                    style: TextStyle(
                      color: shellOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            _buildNavigationButtons(
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
                  setState(() => _error = 'Adicione pelo menos 1 passageiro.');
                  return;
                }
                for (final passageiro in passageirosControllers) {
                  if (passageiro['nome']!.text.trim().isEmpty ||
                      passageiro['telefone']!.text.trim().isEmpty ||
                      passageiro['tshirt']!.text.trim().isEmpty) {
                    setState(
                      () => _error = 'Preencha todos os dados dos passageiros.',
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
  }

  Widget _buildStepEvento() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecione o Evento',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: shellRed,
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('events').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items =
                    snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nome =
                          (data['name'] ?? data['nome'] ?? 'Evento sem nome')
                              .toString();
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(nome),
                      );
                    }).toList();
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedEventId,
                    hint: const Text('Escolha um evento'),
                    items: items,
                    onChanged: (val) => setState(() => _selectedEventId = val),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.event_outlined),
                      border: InputBorder.none,
                      labelText: 'Evento *',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: shellYellow.withValues(alpha: 0.1),
                border: Border.all(color: shellYellow.withValues(alpha: 0.5)),
              ),
              child: CheckboxListTile(
                value: _acceptedTerms,
                onChanged:
                    (value) => setState(() => _acceptedTerms = value ?? false),
                activeColor: shellOrange,
                title: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
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
            const SizedBox(height: 24),
            _buildNavigationButtons(
              showBack: true,
              onBack: () {
                setState(() {
                  _error = null;
                  _currentStep = 2;
                });
                _pageController.jumpToPage(2);
              },
              onNext: () {
                if (_selectedEventId == null) {
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
  }

  Widget _buildNavigationButtons({
    bool showBack = true,
    VoidCallback? onBack,
    VoidCallback? onNext,
    bool isLastStep = false,
  }) {
    return Row(
      children: [
        if (showBack)
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: shellOrange, width: 2),
              ),
              child: TextButton(
                onPressed: _loading ? null : onBack,
                child: Text(
                  'Voltar',
                  style: TextStyle(
                    color: shellOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        if (showBack) const SizedBox(width: 16),
        Expanded(
          flex: showBack ? 1 : 2,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [shellRed, shellOrange]),
              borderRadius: BorderRadius.circular(16),
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
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child:
                  _loading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Text(
                        isLastStep ? 'Finalizar' : 'Continuar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
            _buildStepIndicator(),
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
