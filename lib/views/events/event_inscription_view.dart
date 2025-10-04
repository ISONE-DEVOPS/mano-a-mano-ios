import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EventInscriptionView extends StatefulWidget {
  const EventInscriptionView({super.key});

  @override
  State<EventInscriptionView> createState() => _EventInscriptionViewState();
}

class _EventInscriptionViewState extends State<EventInscriptionView>
    with TickerProviderStateMixin {
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emergenciaController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _carModelController = TextEditingController();
  final _teamNameController = TextEditingController();

  final List<String> _shirtSizes = ['S', 'M', 'L', 'XL', 'XXL'];
  String? _selectedShirtSize;

  String? _selectedLocation;
  final List<String> _locations = ['Santiago', 'São Vicente'];

  List<Map<String, TextEditingController>> passageirosControllers = [];

  bool _loading = false;
  bool _isLoadingData = true;
  String? _error;
  bool _acceptedTerms = false;

  final PageController _pageController = PageController();
  int _currentStep = 0;
  late AnimationController _animationController;

  String _paymentMethod = 'pagali';

  Map<String, dynamic>? _evento;
  String? _eventoPath;
  double _eventPrice = 0.0;

  static const Color shellYellow = Color(0xFFFFCB05);
  static const Color shellRed = Color(0xFFDD1D21);
  static const Color shellOrange = Color(0xFFFF6F00);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEventAndUserData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _nomeController.dispose();
    _telefoneController.dispose();
    _emergenciaController.dispose();
    _licensePlateController.dispose();
    _carModelController.dispose();
    _teamNameController.dispose();
    for (var p in passageirosControllers) {
      p['nome']?.dispose();
      p['telefone']?.dispose();
      p['tshirt']?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadEventAndUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.offAllNamed('/login');
        return;
      }

      // Carregar evento do argumento
      final evento =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (evento == null) {
        setState(() {
          _error = 'Evento não encontrado';
          _isLoadingData = false;
        });
        return;
      }

      setState(() => _evento = evento);

      // Construir path do evento
      final editionId = evento['editionId'];
      final eventId = evento['id'];
      _eventoPath = 'editions/$editionId/events/$eventId';

      // Buscar dados do evento para preços e limites
      final eventDoc = await FirebaseFirestore.instance.doc(_eventoPath!).get();
      if (eventDoc.exists) {
        final eventData = eventDoc.data()!;
        _eventPrice = double.tryParse('${eventData['price'] ?? 0}') ?? 0;

        // Verificar se tem pricesByLocation
        if (eventData.containsKey('pricesByLocation')) {
          // Será calculado quando selecionar localização
        }
      }

      // Carregar dados do usuário
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _nomeController.text = data['nome'] ?? '';
          _telefoneController.text = data['telefone'] ?? '';
          _emergenciaController.text = data['emergencia'] ?? '';
          _selectedShirtSize = data['tshirt'];
          _selectedLocation = data['localizacao'];

          // Se já tem veículo, carregar dados
          if (data.containsKey('veiculoId') && data['veiculoId'] != null) {
            _loadVehicleData(data['veiculoId']);
          }
        });
      }

      setState(() => _isLoadingData = false);
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
      setState(() {
        _error = 'Erro ao carregar dados';
        _isLoadingData = false;
      });
    }
  }

  Future<void> _loadVehicleData(String veiculoId) async {
    try {
      final veiculoDoc =
          await FirebaseFirestore.instance
              .collection('veiculos')
              .doc(veiculoId)
              .get();

      if (veiculoDoc.exists) {
        final data = veiculoDoc.data()!;
        setState(() {
          _licensePlateController.text = data['matricula'] ?? '';
          _carModelController.text = data['modelo'] ?? '';
          _teamNameController.text = data['nome_equipa'] ?? '';

          // Carregar passageiros se existirem
          if (data.containsKey('passageiros')) {
            final passageiros = List<Map<String, dynamic>>.from(
              data['passageiros'] ?? [],
            );
            for (var p in passageiros) {
              passageirosControllers.add({
                'nome': TextEditingController(text: p['nome'] ?? ''),
                'telefone': TextEditingController(text: p['telefone'] ?? ''),
                'tshirt': TextEditingController(text: p['tshirt'] ?? ''),
              });
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados do veículo: $e');
    }
  }

  Future<Map<String, dynamic>> _getLocationPriceInfo(String location) async {
    try {
      if (_eventoPath == null) {
        return {'price': 0.0, 'maxVehicles': -1, 'currentVehicles': 0};
      }

      final eventDoc = await FirebaseFirestore.instance.doc(_eventoPath!).get();

      if (!eventDoc.exists) {
        return {'price': 0.0, 'maxVehicles': -1, 'currentVehicles': 0};
      }

      final eventData = eventDoc.data()!;
      double price = _eventPrice;
      int maxVehicles = -1;

      if (eventData.containsKey('pricesByLocation')) {
        final raw = eventData['pricesByLocation'];
        Map<String, dynamic>? pricesByLocation;
        if (raw is Map) {
          pricesByLocation = Map<String, dynamic>.from(raw);
        }

        if (pricesByLocation != null &&
            pricesByLocation.containsKey(location)) {
          final val = pricesByLocation[location];
          if (val is num) {
            price = val.toDouble();
          } else if (val is String) {
            price = double.tryParse(val) ?? 0;
          } else if (val is Map) {
            final m = Map<String, dynamic>.from(val);
            final p = m['price'];
            final mv = m['maxVehicles'];
            if (p is num) {
              price = p.toDouble();
            } else {
              price = double.tryParse('${p ?? 0}') ?? 0;
            }
            if (mv is num) {
              maxVehicles = mv.toInt();
            } else {
              maxVehicles = int.tryParse('${mv ?? -1}') ?? -1;
            }
          }
        }
      }

      final veiculosQuery =
          await FirebaseFirestore.instance
              .collection('veiculos')
              .where('eventoId', isEqualTo: _eventoPath)
              .where('localizacao', isEqualTo: location)
              .get();

      return {
        'price': price,
        'maxVehicles': maxVehicles,
        'currentVehicles': veiculosQuery.size,
      };
    } catch (e) {
      debugPrint('Erro ao buscar info de preço: $e');
      return {'price': 0.0, 'maxVehicles': -1, 'currentVehicles': 0};
    }
  }

  Future<void> _submitInscricao() async {
    if (_licensePlateController.text.trim().isEmpty ||
        _carModelController.text.trim().isEmpty ||
        _selectedLocation == null ||
        _teamNameController.text.trim().isEmpty) {
      setState(() => _error = 'Preencha todos os campos obrigatórios.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Verificar limites de vagas
      final locationInfo = await _getLocationPriceInfo(_selectedLocation!);
      final maxVehicles = locationInfo['maxVehicles'] as int;
      final currentVehicles = locationInfo['currentVehicles'] as int;
      final price = locationInfo['price'] as double;

      if (maxVehicles > 0 && currentVehicles >= maxVehicles) {
        setState(() {
          _error =
              'Vagas esgotadas em $_selectedLocation. Limite de $maxVehicles veículos atingido.';
        });
        Get.snackbar(
          'Vagas esgotadas',
          'Não é possível registrar mais veículos em $_selectedLocation para este evento.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Preparar dados dos passageiros
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

      // Criar ou atualizar veículo
      final veiculoId =
          FirebaseFirestore.instance.collection('veiculos').doc().id;
      final equipaId =
          FirebaseFirestore.instance.collection('equipas').doc().id;

      final carData = {
        'ownerId': user.uid,
        'matricula': _licensePlateController.text.trim(),
        'modelo': _carModelController.text.trim(),
        'nome_equipa': _teamNameController.text.trim(),
        'localizacao': _selectedLocation ?? '',
        'passageiros': passageiros,
        'pontuacao_total': 0,
        'checkpoints': {},
        'eventoId': _eventoPath,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('veiculos')
          .doc(veiculoId)
          .set(carData);

      // Criar equipa
      final equipaData = {
        'nome': _teamNameController.text.trim(),
        'hino': '',
        'bandeiraUrl': '',
        'pontuacaoTotal': 0,
        'ranking': 0,
        'membros': [user.uid, ...passageiros.map((p) => p['telefone'])],
        'localizacao': _selectedLocation ?? '',
      };

      await FirebaseFirestore.instance
          .collection('equipas')
          .doc(equipaId)
          .set(equipaData);

      // Atualizar dados do usuário
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'nome': _nomeController.text.trim(),
            'telefone': _telefoneController.text.trim(),
            'emergencia': _emergenciaController.text.trim(),
            'tshirt': _selectedShirtSize ?? '',
            'localizacao': _selectedLocation ?? '',
            'veiculoId': veiculoId,
            'equipaId': equipaId,
            'ultimoLogin': FieldValue.serverTimestamp(),
          });

      // Criar inscrição no evento
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('events')
          .doc(_evento!['id'])
          .set({
            'eventoId': _evento!['id'],
            'checkpointsVisitados': [],
            'localizacao': _selectedLocation ?? '',
            'preco': price,
            'dataInscricao': FieldValue.serverTimestamp(),
            'paymentStatus': 'pending',
            'paymentMethod': _paymentMethod,
            'ativo': true,
          });

      setState(() => _loading = false);

      // Mostrar sucesso e voltar
      Get.back();
      Get.snackbar(
        'Inscrição confirmada',
        'Sua inscrição foi realizada com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('Erro ao submeter inscrição: $e');
      setState(() {
        _error = 'Erro ao realizar inscrição: ${e.toString()}';
        _loading = false;
      });
    }
  }

  double _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 16.0;
    if (width < 600) return 20.0;
    if (width < 900) return 32.0;
    return 48.0;
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSize * 0.85;
    if (width < 600) return baseSize;
    return baseSize * 1.1;
  }

  double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSpacing * 0.75;
    if (width < 600) return baseSpacing;
    return baseSpacing * 1.2;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_evento == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: shellRed),
              const SizedBox(height: 16),
              const Text('Evento não encontrado'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    final pages = <Widget>[
      _buildStepDadosPessoais(),
      _buildStepCarro(),
      _buildStepPassageiros(),
      _buildStepConfirmacao(),
      _buildStepPagamento(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          _buildStepIndicator(context),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: pages,
            ),
          ),
        ],
      ),
    );
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Inscrição no Evento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getResponsiveFontSize(context, 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_evento != null)
                      Text(
                        _evento!['nome'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: _getResponsiveFontSize(context, 14),
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 48), // Para balancear o botão de voltar
            ],
          ),
          SizedBox(height: spacing),
          Row(
            children: List.generate(5, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
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
        return 'Confirmação';
      case 4:
        return 'Pagamento';
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

  Widget _buildStepDadosPessoais() {
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
                  controller: _nomeController,
                  hintText: 'Ex: João Silva',
                  isRequired: true,
                  isError:
                      _error != null && _nomeController.text.trim().isEmpty,
                ),
                _inputCard(
                  context: context,
                  icon: Icons.phone_outlined,
                  label: 'Telefone',
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                  hintText: 'Ex: 912345678',
                  isRequired: true,
                  isError:
                      _error != null && _telefoneController.text.trim().isEmpty,
                ),
                _inputCard(
                  context: context,
                  icon: Icons.emergency_outlined,
                  label: 'Contato de Emergência',
                  controller: _emergenciaController,
                  keyboardType: TextInputType.phone,
                  hintText: 'Ex: 991234567',
                  isRequired: true,
                  isError:
                      _error != null &&
                      _emergenciaController.text.trim().isEmpty,
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
                    if (_nomeController.text.trim().isEmpty ||
                        _telefoneController.text.trim().isEmpty ||
                        _emergenciaController.text.trim().isEmpty ||
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
                  _buildErrorCard(context),
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
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      _getResponsiveSpacing(context, 16),
                    ),
                    color: Colors.white,
                    border: Border.all(
                      color:
                          (_error != null && _selectedLocation == null)
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
                  margin: EdgeInsets.only(
                    bottom: _getResponsiveSpacing(context, 16),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveSpacing(context, 16),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedLocation,
                    items:
                        _locations.map((location) {
                          return DropdownMenuItem(
                            value: location,
                            child: Text(
                              location,
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(context, 15),
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (val) => setState(() => _selectedLocation = val),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: shellOrange,
                        size: _getResponsiveSpacing(context, 22),
                      ),
                      labelText: 'Localização *',
                      hintText: 'Selecione a ilha',
                      labelStyle: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 14),
                        color:
                            (_error != null && _selectedLocation == null)
                                ? shellRed
                                : Colors.grey.shade700,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_selectedLocation != null)
                  FutureBuilder<Map<String, dynamic>>(
                    future: _getLocationPriceInfo(_selectedLocation!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();

                      final info = snapshot.data!;
                      final price = info['price'] as double;
                      final maxVehicles = info['maxVehicles'] as int;
                      final currentVehicles = info['currentVehicles'] as int;

                      return Container(
                        margin: EdgeInsets.only(
                          bottom: _getResponsiveSpacing(context, 16),
                        ),
                        padding: EdgeInsets.all(
                          _getResponsiveSpacing(context, 16),
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              shellYellow.withValues(alpha: 0.2),
                              shellOrange.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            _getResponsiveSpacing(context, 12),
                          ),
                          border: Border.all(
                            color: shellOrange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: shellOrange,
                                  size: _getResponsiveSpacing(context, 20),
                                ),
                                SizedBox(
                                  width: _getResponsiveSpacing(context, 8),
                                ),
                                Text(
                                  'Informações da Inscrição',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: _getResponsiveFontSize(
                                      context,
                                      16,
                                    ),
                                    color: shellOrange,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: _getResponsiveSpacing(context, 12),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Valor:',
                                  style: TextStyle(
                                    fontSize: _getResponsiveFontSize(
                                      context,
                                      14,
                                    ),
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  '${price.toStringAsFixed(0)} CVE',
                                  style: TextStyle(
                                    fontSize: _getResponsiveFontSize(
                                      context,
                                      16,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    color: shellRed,
                                  ),
                                ),
                              ],
                            ),
                            if (maxVehicles > 0) ...[
                              SizedBox(
                                height: _getResponsiveSpacing(context, 8),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Vagas disponíveis:',
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(
                                        context,
                                        14,
                                      ),
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    '${maxVehicles - currentVehicles} de $maxVehicles',
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(
                                        context,
                                        14,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      color:
                                          (maxVehicles - currentVehicles) <= 2
                                              ? shellRed
                                              : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
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
                        _selectedLocation == null ||
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
                if (_error != null) ...[
                  SizedBox(height: _getResponsiveSpacing(context, 16)),
                  _buildErrorCard(context),
                ],
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
                if (_error != null) ...[
                  SizedBox(height: _getResponsiveSpacing(context, 16)),
                  _buildErrorCard(context),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepConfirmacao() {
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
                  'Confirme sua inscrição',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 22),
                    fontWeight: FontWeight.bold,
                    color: shellRed,
                  ),
                ),
                SizedBox(height: spacing),

                // Resumo do evento
                Container(
                  padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        shellYellow.withValues(alpha: 0.2),
                        shellOrange.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      _getResponsiveSpacing(context, 12),
                    ),
                    border: Border.all(
                      color: shellOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            color: shellOrange,
                            size: _getResponsiveSpacing(context, 24),
                          ),
                          SizedBox(width: _getResponsiveSpacing(context, 12)),
                          Expanded(
                            child: Text(
                              _evento!['nome'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: _getResponsiveFontSize(context, 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_evento!['data'] != null) ...[
                        SizedBox(height: _getResponsiveSpacing(context, 8)),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.grey.shade600,
                              size: _getResponsiveSpacing(context, 18),
                            ),
                            SizedBox(width: _getResponsiveSpacing(context, 8)),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(
                                (_evento!['data'] as Timestamp).toDate(),
                              ),
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(context, 14),
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: spacing),

                // Termos e condições
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      _getResponsiveSpacing(context, 16),
                    ),
                    color: shellYellow.withValues(alpha: 0.1),
                    border: Border.all(
                      color:
                          (_error != null && !_acceptedTerms)
                              ? shellRed
                              : shellYellow.withValues(alpha: 0.5),
                      width: (_error != null && !_acceptedTerms) ? 2 : 1,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: _acceptedTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptedTerms = value ?? false;
                        if (value == true) _error = null;
                      });
                    },
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
                    if (!_acceptedTerms) {
                      setState(() {
                        _error = 'Você deve aceitar os termos para continuar';
                      });
                      return;
                    }

                    setState(() {
                      _error = null;
                      _currentStep = 4;
                    });
                    _pageController.jumpToPage(4);
                  },
                ),

                if (_error != null) ...[
                  SizedBox(height: _getResponsiveSpacing(context, 16)),
                  _buildErrorCard(context),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepPagamento() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = _getResponsivePadding(context);
        final spacing = _getResponsiveSpacing(context, 20);

        return FutureBuilder<Map<String, dynamic>>(
          future:
              _selectedLocation != null
                  ? _getLocationPriceInfo(_selectedLocation!)
                  : Future.value({
                    'price': 0.0,
                    'maxVehicles': -1,
                    'currentVehicles': 0,
                  }),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final paymentInfo = snapshot.data!;
            final price = (paymentInfo['price'] as num?)?.toDouble() ?? 0.0;

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pagamento',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 22),
                        fontWeight: FontWeight.bold,
                        color: shellRed,
                      ),
                    ),
                    SizedBox(height: spacing),

                    // Resumo do valor
                    Container(
                      padding: EdgeInsets.all(
                        _getResponsiveSpacing(context, 16),
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            shellYellow.withValues(alpha: 0.2),
                            shellOrange.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          _getResponsiveSpacing(context, 12),
                        ),
                        border: Border.all(
                          color: shellOrange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Valor da inscrição:',
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(context, 14),
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '${price.toStringAsFixed(0)} CVE',
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(context, 18),
                              fontWeight: FontWeight.bold,
                              color: shellRed,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: spacing),

                    // Método de pagamento
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: _getResponsiveSpacing(context, 4),
                      ),
                      child: SegmentedButton<String>(
                        segments: const <ButtonSegment<String>>[
                          ButtonSegment<String>(
                            value: 'pagali',
                            label: Text('Pagali'),
                            icon: Icon(Icons.account_balance_wallet_outlined),
                          ),
                          ButtonSegment<String>(
                            value: 'transfer',
                            label: Text('Transferência'),
                            icon: Icon(Icons.account_balance_outlined),
                          ),
                        ],
                        selected: <String>{_paymentMethod},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _paymentMethod = newSelection.first;
                          });
                        },
                        showSelectedIcon: false,
                      ),
                    ),

                    SizedBox(height: spacing),

                    // Instruções
                    if (_paymentMethod == 'pagali')
                      Container(
                        padding: EdgeInsets.all(
                          _getResponsiveSpacing(context, 16),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            _getResponsiveSpacing(context, 12),
                          ),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Após finalizar, receberá instruções para pagar via Pagali. '
                          'A participação só será validada após confirmação do pagamento.',
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(context, 14),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.all(
                          _getResponsiveSpacing(context, 16),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            _getResponsiveSpacing(context, 12),
                          ),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transferência bancária',
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(context, 16),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: _getResponsiveSpacing(context, 8)),
                            Text(
                              'Efetue a transferência para:\nNIB: 0005000000831804210197 (Banco Interatlântico)\n\nEnvie o comprovativo para: manoamanooffroad@gmail.com',
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(context, 14),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: spacing),

                    _buildNavigationButtons(
                      context: context,
                      showBack: true,
                      onBack: () {
                        setState(() {
                          _error = null;
                          _currentStep = 3;
                        });
                        _pageController.jumpToPage(3);
                      },
                      onNext: _submitInscricao,
                      isLastStep: true,
                    ),

                    if (_error != null) ...[
                      SizedBox(height: _getResponsiveSpacing(context, 16)),
                      _buildErrorCard(context),
                    ],
                  ],
                ),
              ),
            );
          },
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
                        isLastStep ? 'Finalizar Inscrição' : 'Continuar',
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

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
      decoration: BoxDecoration(
        color: shellRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_getResponsiveSpacing(context, 12)),
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
    );
  }
}
