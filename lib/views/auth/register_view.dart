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
  final _firebaseService = FirebaseService();

  final List<String> _shirtSizes = ['P', 'M', 'G', 'GG', 'XG'];
  String? _selectedShirtSize;

  List<Map<String, TextEditingController>> passageirosControllers = [];

  bool _loading = false;
  String? _error;

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
        'passageiros': passageiros,
        'pontuacao_total': 0,
        'checkpoints': {},
      });

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
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            border: InputBorder.none,
            icon: Icon(icon, color: const Color(0xFF0E0E2C)),
            labelText: label,
          ),
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
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.phone,
            label: 'Telefone',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.phone_in_talk,
            label: 'Contato de emergência',
            controller: _emergencyContactController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.email,
            label: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.lock,
            label: 'Senha',
            controller: _passwordController,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.lock_outline,
            label: 'Confirmar Senha',
            controller: _confirmPasswordController,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedShirtSize,
            items:
                _shirtSizes.map((size) {
                  return DropdownMenuItem(value: size, child: Text(size));
                }).toList(),
            onChanged: (val) => setState(() => _selectedShirtSize = val),
            decoration: InputDecoration(
              border: InputBorder.none,
              icon: Icon(Icons.checkroom, color: const Color(0xFF0E0E2C)),
              labelText: 'Tamanho da t-shirt',
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
            Text(_error!, style: const TextStyle(color: Colors.red)),
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
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.directions_car_filled,
            label: 'Marca',
            controller: _carBrandController,
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.drive_eta,
            label: 'Modelo',
            controller: _carModelController,
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
            Text(_error!, style: const TextStyle(color: Colors.red)),
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
          const Text(
            'Passageiros (máximo 4)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passageirosControllers[i]['nome'],
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person),
                            labelText: 'Nome',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passageirosControllers[i]['telefone'],
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phone),
                            labelText: 'Telefone',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passageirosControllers[i]['tshirt'],
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.checkroom),
                            labelText: 'Tamanho da t-shirt',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
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
            Text(_error!, style: const TextStyle(color: Colors.red)),
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
        const Text(
          'Escolha o evento',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              hint: const Text('Selecione um evento'),
              value: _selectedEventId,
              items:
                  docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['nome'] ?? data['Nome'] ?? 'Sem nome'),
                    );
                  }).toList(),
              onChanged: (val) => setState(() => _selectedEventId = val),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Evento',
              ),
            );
          },
        ),
        const SizedBox(height: 24),
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
                  (_loading || _selectedEventId == null) ? null : _register,
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
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E2C),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                  const Center(
                    child: Text(
                      'Criar uma conta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
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
                      const Text(
                        'Já tem uma conta?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () => Get.toNamed('/login'),
                        child: const Text('Entrar'),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / 4,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blueAccent,
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
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
        ),
      ),
    );
  }
}
