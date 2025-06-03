import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../profile/profile_view.dart';
import '../payment/payment_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _carBrandController = TextEditingController();
  final _carModelController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _teamNameController = TextEditingController();
  final _firebaseService = FirebaseService();

  final List<String> _shirtSizes = ['P', 'M', 'G', 'GG', 'XG'];
  String? _selectedShirtSize;

  List<Map<String, TextEditingController>> passageirosControllers = [];

  bool _loading = false;
  String? _error;
  bool _acceptedTerms = false;

  final PageController _pageController = PageController();
  int _currentStep = 0;

  String? _selectedEventId;

  void _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'As senhas não coincidem');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uid = await _firebaseService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

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

      // Salva dados pessoais do utilizador na coleção 'users'
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'nome': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'telefone': _phoneController.text.trim(),
        'emergencia': _emergencyContactController.text.trim(),
        'tshirt': _selectedShirtSize ?? '',
        'role': 'user',
        'eventoId': _selectedEventId,
      });

      // Salva somente os dados do carro na coleção 'cars'
      await _firebaseService.saveCarData(uid!, {
        'ownerId': uid,
        'matricula': _licensePlateController.text.trim(),
        'marca': _carBrandController.text.trim(),
        'modelo': _carModelController.text.trim(),
        'nome_equipa': _teamNameController.text.trim(),
        'passageiros': passageiros,
        'pontuacao_total': 0,
        'checkpoints': {},
      });

      // Salvar consentimento nos termos
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('acceptedTerms', true);

      // Após salvar carro, verifica valor do evento
      final eventDoc =
          await FirebaseFirestore.instance
              .collection('events')
              .doc(_selectedEventId)
              .get();
      final Map<String, dynamic> data = eventDoc.data() ?? {};
      final price = double.tryParse('${data['price']}') ?? 0;
      if (price > 0) {
        // Navega para pagamento
        Get.to(() => PaymentView(eventId: _selectedEventId!, amount: price));
      } else {
        // Sem valor, já termina registro
        Get.offAll(() => const ProfileView());
      }
    } on FirebaseAuthException catch (authError) {
      // Tratar erro de e-mail já cadastrado
      if (authError.code == 'email-already-in-use') {
        setState(
          () =>
              _error = 'Este e-mail já está cadastrado. Por favor faça login.',
        );
      } else {
        setState(() => _error = authError.message ?? 'Erro de autenticação.');
      }
    } catch (e) {
      setState(() => _error = 'Erro ao criar conta: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _inputCard({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          icon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          labelText: label,
          hintText: hintText,
          hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
          labelStyle: Theme.of(context).textTheme.labelLarge,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          constraints: const BoxConstraints(maxHeight: 48),
        ),
      ),
    );
  }

  Widget _buildStepCondutor() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputCard(
            icon: Icons.person,
            label: 'Nome do condutor',
            controller: _nameController,
            hintText: 'Ex: João Silva',
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.phone,
            label: 'Telefone',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            hintText: 'Ex: 912345678',
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.phone_in_talk,
            label: 'Contato de emergência',
            controller: _emergencyContactController,
            keyboardType: TextInputType.phone,
            hintText: 'Ex: 9911111',
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.email,
            label: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            hintText: 'exemplo@email.com',
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.lock,
            label: 'Senha',
            controller: _passwordController,
            obscureText: true,
            hintText: 'Mínimo 6 caracteres',
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.lock_outline,
            label: 'Confirmar Senha',
            controller: _confirmPasswordController,
            obscureText: true,
            hintText: 'Repita a senha',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedShirtSize,
            items:
                _shirtSizes.map((size) {
                  return DropdownMenuItem(
                    value: size,
                    child: Text(
                      size,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }).toList(),
            onChanged: (val) => setState(() => _selectedShirtSize = val),
            decoration: InputDecoration(
              border: InputBorder.none,
              icon: Icon(
                Icons.checkroom,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              labelText: 'Tamanho da t-shirt',
              labelStyle: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _currentStep = 1;
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                },
                child: const Text('Próximo'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCarro() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputCard(
            icon: Icons.directions_car,
            label: 'Matrícula',
            controller: _licensePlateController,
            hintText: 'Ex: AB-12-CD',
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.directions_car_filled,
            label: 'Marca',
            controller: _carBrandController,
            hintText: 'Ex: Toyota',
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.drive_eta,
            label: 'Modelo',
            controller: _carModelController,
            hintText: 'Ex: Corolla',
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.group,
            label: 'Nome da Equipa',
            controller: _teamNameController,
            hintText: 'Ex: Os Rápidos',
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _currentStep = 0;
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                },
                child: const Text('Voltar'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _currentStep = 2;
                  });
                  _pageController.jumpToPage(2);
                },
                child: const Text('Próximo'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepPassageiros() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passageiros (máximo 4)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              for (int i = 0; i < passageirosControllers.length; i++)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Passageiro ${i + 1}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: TextField(
                            controller: passageirosControllers[i]['nome'],
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.person),
                              labelText: 'Nome',
                              hintText: 'Ex: Maria Oliveira',
                              hintStyle:
                                  Theme.of(
                                    context,
                                  ).inputDecorationTheme.hintStyle,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: TextField(
                            controller: passageirosControllers[i]['telefone'],
                            style: Theme.of(context).textTheme.bodyMedium,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.phone),
                              labelText: 'Telefone',
                              hintText: 'Ex: 912345678',
                              hintStyle:
                                  Theme.of(
                                    context,
                                  ).inputDecorationTheme.hintStyle,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButtonFormField<String>(
                            value:
                                passageirosControllers[i]['tshirt']!
                                        .text
                                        .isNotEmpty
                                    ? passageirosControllers[i]['tshirt']!.text
                                    : null,
                            items:
                                _shirtSizes.map((size) {
                                  return DropdownMenuItem(
                                    value: size,
                                    child: Text(
                                      size,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    ),
                                  );
                                }).toList(),
                            onChanged: (val) {
                              setState(() {
                                passageirosControllers[i]['tshirt']!.text =
                                    val ?? '';
                              });
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              icon: Icon(
                                Icons.checkroom,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              labelText: 'Tamanho da t-shirt',
                              labelStyle:
                                  Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                passageirosControllers.removeAt(i);
                              });
                            },
                            child: const Text('Remover passageiro'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (passageirosControllers.length < 4)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      passageirosControllers.add({
                        'nome': TextEditingController(),
                        'telefone': TextEditingController(),
                        'tshirt': TextEditingController(),
                      });
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Passageiro'),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _currentStep = 1;
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                },
                child: const Text('Voltar'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _currentStep = 3;
                  });
                  _pageController.jumpToPage(3);
                },
                child: const Text('Próximo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepEvento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escolha o evento',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('events')
                  .where('status', isEqualTo: true)
                  .orderBy('data_event')
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(child: Text('Nenhum evento ativo'));
            }
            return DropdownButtonFormField<String>(
              isExpanded: true,
              hint: Text(
                'Selecione um evento',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              value: _selectedEventId,
              items:
                  docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(
                        data['nome'] ?? data['Nome'] ?? 'Sem nome',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }).toList(),
              onChanged: (val) => setState(() => _selectedEventId = val),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Evento',
                labelStyle: Theme.of(context).textTheme.labelLarge,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        // CheckboxListTile for terms and privacy
        CheckboxListTile(
          value: _acceptedTerms,
          onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
          activeColor: Theme.of(context).colorScheme.primary,
          title: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              children: [
                const TextSpan(text: 'Li e aceito os '),
                TextSpan(
                  text: 'Termos e Condições',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
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
          controlAffinity: ListTileControlAffinity.leading,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _currentStep = 2;
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                });
              },
              child: const Text('Voltar'),
            ),
            ElevatedButton(
              onPressed:
                  (_loading || _selectedEventId == null || !_acceptedTerms)
                      ? null
                      : _register,
              child:
                  _loading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('Registrar'),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAcceptedTerms();
  }

  Future<void> _loadAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('acceptedTerms') ?? false;
    setState(() => _acceptedTerms = accepted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: kIsWeb
            ? Center(
                child: SizedBox(
                  width: 500,
                  child: _buildRegisterBody(context),
                ),
              )
            : _buildRegisterBody(context),
      ),
    );
  }

  Widget _buildRegisterBody(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              Image.asset(
                'assets/images/Logo_Shell_KM.png',
                width: 40,
                height: 40,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Criar uma conta',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Já tem uma conta?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(179),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed('/login'),
                    child: Text(
                      'Entrar',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Etapa ${_currentStep + 1} de 4',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (_currentStep + 1) / 4,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.onPrimary.withAlpha(61),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                minHeight: 6,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
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
        ),
      ],
    );
  }
}
