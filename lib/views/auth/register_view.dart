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

class _RegisterViewState extends State<RegisterView> {
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

  final PageController _pageController = PageController();
  int _currentStep = 0;

  String? _selectedEventId;
  Map<String, dynamic>? _activeEventData;
  String? _activeEventName;

  void _register() async {
    debugPrint('▶️ Método _register() iniciado');

    // Verificação de limite de equipas simplificada: limita pelo número total de equipas
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

    // Validação dos campos dos passageiros
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

      // Garante autenticação do currentUser no FirebaseAuth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Aguarda propagação do currentUser no FirebaseAuth
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final confirmedUser = FirebaseAuth.instance.currentUser;
      debugPrint('✅ UID após delay: ${confirmedUser?.uid}');

      debugPrint('UID autenticado no momento do registo: $uid');

      // Verificação UID antes de salvar dados
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

      // Após salvar carro, verifica valor do evento
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

      // Gerar novos IDs para veiculo e equipa
      final veiculoId =
          FirebaseFirestore.instance.collection('veiculos').doc().id;
      final equipaId =
          FirebaseFirestore.instance.collection('equipas').doc().id;

      // Dados do carro a serem gravados (agora com veiculoId)
      final carData = {
        'ownerId': uid,
        'matricula': _licensePlateController.text.trim(),
        'modelo': _carModelController.text.trim(),
        'nome_equipa': _teamNameController.text.trim(),
        'passageiros': passageiros,
        'pontuacao_total': 0,
        'checkpoints': {},
      };
      debugPrint('Dados do carro que serão gravados: $carData');

      // Salvar carro em veiculos/veiculoId
      try {
        await FirebaseFirestore.instance
            .collection('veiculos')
            .doc(veiculoId)
            .set(carData);
        debugPrint('✅ Documento do carro criado em /veiculos/$veiculoId');
      } catch (e) {
        debugPrint('❌ Falha ao salvar carro: $e');
        if (!mounted) return;
        setState(
          () => _error = 'Erro ao salvar dados do veículo: ${e.toString()}',
        );
        return;
      }

      // Criar documento da equipa em equipas/equipaId
      try {
        final equipaData = {
          'nome': _teamNameController.text.trim(),
          'hino': '',
          'bandeiraUrl': '',
          'pontuacaoTotal': 0,
          'ranking': 0,
          'membros': [uid, ...passageiros.map((p) => p['telefone'])],
        };

        if (!mounted) return;

        await FirebaseFirestore.instance
            .collection('equipas')
            .doc(equipaId)
            .set(equipaData);
        debugPrint('✅ Documento da equipa criado em /equipas/$equipaId');
      } catch (e) {
        debugPrint('❌ Falha ao criar equipa: $e');
        if (!mounted) return;
        setState(() => _error = 'Erro ao criar equipa: ${e.toString()}');
        return;
      }

      // Salva dados pessoais do utilizador na coleção 'users', agora com veiculoId, equipaId, checkpointsVisitados
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
        // 'ultimoLogin' removido do set() inicial
      });
      if (!mounted) return;
      debugPrint('✅ Documento do utilizador criado em /users/$uid');

      // Registo do evento atual na subcoleção 'eventos' do utilizador
      debugPrint(
        '🔁 Criando subcoleção events para $uid e evento $_selectedEventId',
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('events')
          .doc(_selectedEventId)
          .set({'eventoId': _selectedEventId, 'checkpointsVisitados': []});
      if (!mounted) return;
      debugPrint('✅ Subcoleção events criada com sucesso');

      // Atualiza o campo ultimoLogin após o cadastro (após garantir que o doc existe)
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'ultimoLogin': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        debugPrint('✅ ultimoLogin atualizado com sucesso');
      } catch (e) {
        debugPrint('❌ Falha ao atualizar ultimoLogin: $e');
      }

      // Salvar consentimento nos termos
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('acceptedTerms', true);

      if (!mounted) return;
      if (price > 0) {
        // Navega para pagamento
        if (!mounted) return;
        Get.to(() => PaymentView(eventId: _selectedEventId!, amount: price));
      } else {
        // Sem valor, já termina registro
        if (!mounted) return;
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
      // Tratar erro de e-mail já cadastrado
      if (!mounted) return;
      if (authError.code == 'email-already-in-use') {
        setState(
          () => _error = 'Este e-mail já está registado. Por favor faça login.',
        );
      } else {
        setState(() => _error = authError.message ?? 'Erro de autenticação.');
      }
    } catch (e, stackTrace) {
      final mensagemErro =
          e.toString().isEmpty ? 'Erro desconhecido' : e.toString();
      debugPrint('❌ Erro capturado no register: $mensagemErro');
      debugPrint('🪵 Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() => _error = 'Erro ao criar conta: $mensagemErro');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
      // Removido o animateToPage para evitar loop ao retornar à etapa com erro
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
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isError ? Colors.red : Colors.grey.shade300),
        color: Colors.white,
      ),
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.fromLTRB(4, 12, 8, 4),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          icon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          labelText: isRequired ? '$label *' : label,
          hintText: hintText,
          hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
          labelStyle: Theme.of(context).textTheme.labelLarge,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          constraints: const BoxConstraints(minHeight: 56),
        ),
      ),
    );
  }

  Widget _buildStepCondutor() {
    bool nameError = _error != null && _nameController.text.trim().isEmpty;
    bool phoneError = _error != null && _phoneController.text.trim().isEmpty;
    bool emergencyError =
        _error != null && _emergencyContactController.text.trim().isEmpty;
    bool emailError = _error != null && _emailController.text.trim().isEmpty;
    bool passError = _error != null && _passwordController.text.trim().isEmpty;
    bool confirmPassError =
        _error != null && _confirmPasswordController.text.trim().isEmpty;
    bool shirtError = _error != null && _selectedShirtSize == null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputCard(
            icon: Icons.person,
            label: 'Nome do condutor',
            controller: _nameController,
            hintText: 'Ex: João Silva',
            isRequired: true,
            isError: nameError,
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.phone,
            label: 'Telefone',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            hintText: 'Ex: 912345678',
            isRequired: true,
            isError: phoneError,
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.phone_in_talk,
            label: 'Contato de emergência',
            controller: _emergencyContactController,
            keyboardType: TextInputType.phone,
            hintText: 'Ex: 9911111',
            isRequired: true,
            isError: emergencyError,
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.email,
            label: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            hintText: 'exemplo@email.com',
            isRequired: true,
            isError: emailError,
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.lock,
            label: 'Senha',
            controller: _passwordController,
            obscureText: true,
            hintText: 'Mínimo 6 caracteres',
            isRequired: true,
            isError: passError,
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.lock_outline,
            label: 'Confirmar Senha',
            controller: _confirmPasswordController,
            obscureText: true,
            hintText: 'Repita a senha',
            isRequired: true,
            isError: confirmPassError,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: shirtError ? Colors.red : Colors.grey.shade300,
              ),
              color: Colors.white,
            ),
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedShirtSize,
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
                icon: Icon(
                  Icons.checkroom,
                  color: Theme.of(context).colorScheme.primary,
                ),
                labelText: 'Tamanho da t-shirt *',
                labelStyle: Theme.of(context).textTheme.labelLarge,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                constraints: const BoxConstraints(minHeight: 56),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: Border.all(color: Colors.amber.shade700, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Por favor preencha todos os campos obrigatórios antes de avançar.',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      _loading
                          ? null
                          : () {
                            if (_nameController.text.trim().isEmpty ||
                                _phoneController.text.trim().isEmpty ||
                                _emergencyContactController.text
                                    .trim()
                                    .isEmpty ||
                                _emailController.text.trim().isEmpty ||
                                _passwordController.text.trim().isEmpty ||
                                _confirmPasswordController.text
                                    .trim()
                                    .isEmpty ||
                                _selectedShirtSize == null) {
                              setState(() {
                                _error =
                                    'Por favor preencha todos os campos obrigatórios.';
                              });
                              return;
                            }
                            setState(() {
                              _error = null;
                              _currentStep = 1;
                            });
                            FocusScope.of(context).unfocus();
                            _pageController.jumpToPage(_currentStep);
                          },
                  child: const Text(
                    'Próximo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
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
    bool licensePlateError =
        _error != null && _licensePlateController.text.trim().isEmpty;
    bool modelError = _error != null && _carModelController.text.trim().isEmpty;
    bool teamNameError =
        _error != null && _teamNameController.text.trim().isEmpty;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputCard(
            icon: Icons.directions_car,
            label: 'Matrícula',
            controller: _licensePlateController,
            hintText: 'Ex: AB-12-CD',
            isRequired: true,
            isError: licensePlateError,
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
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.drive_eta,
            label: 'Modelo',
            controller: _carModelController,
            hintText: 'Ex: Corolla',
            isRequired: true,
            isError: modelError,
          ),
          const SizedBox(height: 16),
          _inputCard(
            icon: Icons.group,
            label: 'Nome da Equipa',
            controller: _teamNameController,
            hintText: 'Ex: Os Rápidos',
            isRequired: true,
            isError: teamNameError,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed:
                    _loading
                        ? null
                        : () {
                          setState(() {
                            _error = null;
                            _currentStep -= 1;
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          });
                        },
                child: const Text('Voltar'),
              ),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      _loading
                          ? null
                          : () {
                            setState(() {
                              _error = null;
                              _currentStep = 2;
                            });
                            FocusScope.of(context).unfocus();
                            _pageController.jumpToPage(2);
                          },
                  child: const Text(
                    'Próximo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
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
    // Verificação para garantir que haja pelo menos um passageiro antes de avançar
    // (a lógica do botão "Próximo" já será reforçada abaixo)
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
                            border: Border.all(
                              color:
                                  (_error != null &&
                                          passageirosControllers[i]['nome']!
                                              .text
                                              .trim()
                                              .isEmpty)
                                      ? Colors.red
                                      : Colors.grey.shade300,
                            ),
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: TextField(
                            controller: passageirosControllers[i]['nome'],
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.person),
                              labelText: 'Nome *',
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
                            border: Border.all(
                              color:
                                  (_error != null &&
                                          passageirosControllers[i]['telefone']!
                                              .text
                                              .trim()
                                              .isEmpty)
                                      ? Colors.red
                                      : Colors.grey.shade300,
                            ),
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: TextField(
                            controller: passageirosControllers[i]['telefone'],
                            style: Theme.of(context).textTheme.bodyMedium,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.phone),
                              labelText: 'Telefone *',
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
                            border: Border.all(
                              color:
                                  (_error != null &&
                                          passageirosControllers[i]['tshirt']!
                                              .text
                                              .trim()
                                              .isEmpty)
                                      ? Colors.red
                                      : Colors.grey.shade300,
                            ),
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButtonFormField<String>(
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
                              labelText: 'Tamanho da t-shirt *',
                              labelStyle:
                                  Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed:
                                _loading
                                    ? null
                                    : () {
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
                  onPressed:
                      _loading
                          ? null
                          : () {
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
                onPressed:
                    _loading
                        ? null
                        : () {
                          setState(() {
                            _error = null;
                            _currentStep -= 1;
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          });
                        },
                child: const Text('Voltar'),
              ),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      _loading
                          ? null
                          : () {
                            if (passageirosControllers.isEmpty) {
                              setState(() {
                                _error = 'Adicione pelo menos 1 passageiro.';
                              });
                              return;
                            }
                            for (final passageiro in passageirosControllers) {
                              if (passageiro['nome']!.text.trim().isEmpty ||
                                  passageiro['telefone']!.text.trim().isEmpty ||
                                  passageiro['tshirt']!.text.trim().isEmpty) {
                                setState(() {
                                  _error =
                                      'Preencha todos os dados dos passageiros.';
                                });
                                return;
                              }
                            }
                            setState(() {
                              _error = null;
                              _currentStep = 3;
                            });
                            FocusScope.of(context).unfocus();
                            _pageController.jumpToPage(3);
                          },
                  child: const Text(
                    'Próximo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepEvento() {
    bool eventError = _error != null && _selectedEventId == null;
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
            return DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedEventId,
              hint: Text(
                'Selecione um evento',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              items: items,
              onChanged:
                  _loading
                      ? null
                      : (val) => setState(() => _selectedEventId = val),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: eventError ? Colors.red : Colors.grey.shade300,
                  ),
                ),
                labelText: 'Evento *',
                labelStyle: Theme.of(context).textTheme.labelLarge,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        // CheckboxListTile for terms and privacy
        CheckboxListTile(
          value: _acceptedTerms,
          onChanged:
              _loading
                  ? null
                  : (value) => setState(() => _acceptedTerms = value ?? false),
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
              onPressed:
                  _loading
                      ? null
                      : () {
                        setState(() {
                          _error = null;
                          _currentStep -= 1;
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        });
                      },
              child: const Text('Voltar'),
            ),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  debugPrint('🟢 Clique no botão REGISTRAR');
                  if (_loading) {
                    debugPrint('⚠️ Está em loading, botão desativado.');
                    return;
                  }
                  if (_selectedEventId == null) {
                    debugPrint('⚠️ Nenhum evento selecionado.');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selecione um evento.')),
                    );
                    return;
                  }
                  if (!_acceptedTerms) {
                    debugPrint('⚠️ Termos não foram aceites.');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Aceite os termos para continuar.'),
                      ),
                    );
                    return;
                  }

                  _register();
                },
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
                        : const Text(
                          'Registrar',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
              ),
            ),
          ],
        ),
        // Error display for _register
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
    _loadActiveEvent();
  }

  Future<void> _loadAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('acceptedTerms') ?? false;
    setState(() => _acceptedTerms = accepted);
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
        setState(() {
          _selectedEventId = d.id;
          _activeEventData = d.data() as Map<String, dynamic>?;
          _activeEventName =
              (_activeEventData?['name'] ?? _activeEventData?['nome'] ?? '')
                  .toString();
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : 600,
                  ),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.95,
                    child: _buildRegisterBody(context),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterBody(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.jpeg', width: 40, height: 40),
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Text(
              //       'Já tem uma conta?',
              //       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              //         color: Theme.of(
              //           context,
              //         ).colorScheme.primary.withAlpha(179),
              //       ),
              //     ),
              //     TextButton(
              //       onPressed: () => Get.toNamed('/login'),
              //       child: Text(
              //         'Entrar',
              //         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              //           color: Theme.of(context).colorScheme.primary,
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
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
                ).colorScheme.onSurface.withValues(alpha: 0.12),
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
