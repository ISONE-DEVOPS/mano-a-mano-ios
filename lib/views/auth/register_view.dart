import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import 'user_summary_view.dart';

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

  String? _selectedLocation;
  final List<String> _locations = ['Santiago', 'São Vicente'];

  List<Map<String, TextEditingController>> passageirosControllers = [];

  bool _loading = false;
  String? _error;
  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final PageController _pageController = PageController();
  int _currentStep = 0;
  late AnimationController _animationController;

  String _paymentMethod = 'pagali'; // 'pagali' ou 'transfer'

  String? _selectedEventId;
  String? _selectedEventPath;

  List<Map<String, String>> _eventOptions = [];
  bool _loadingEvents = true;

  // Novos campos para diferenciar fluxo de registo
  bool _isExistingUser = false;
  String? _existingUserId;
  String? _existingVeiculoId;
  String? _existingEquipaId;

  static const Color shellYellow = Color(0xFFFFCB05);
  static const Color shellRed = Color(0xFFDD1D21);
  static const Color shellOrange = Color(0xFFFF6F00);

  // Helpers para obter valores com chaves alternativas e preencher a partir do Auth
  String _getFirstNonEmpty(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return '';
  }

  void _prefillFromAuthUser(User user) {
    // Preenche a partir do FirebaseAuth quando o documento no Firestore ainda não existe
    if (_emailController.text.trim().isEmpty && (user.email ?? '').isNotEmpty) {
      _emailController.text = user.email!.trim();
    }
    if (_nameController.text.trim().isEmpty &&
        (user.displayName ?? '').isNotEmpty) {
      _nameController.text = user.displayName!.trim();
    }
    // Telefone não vem do Auth por padrão; mantemos em branco se não houver no Firestore
  }

  String _mapFriendlyError(Object error) {
    // Default fallback
    const fallback =
        'Ocorreu um erro ao realizar a inscrição. Tente novamente.';
    if (error is FirebaseException) {
      // cloud_firestore plugin
      if (error.plugin == 'cloud_firestore') {
        switch (error.code) {
          case 'not-found':
            return 'Não encontramos o documento necessário (ex.: evento selecionado). Verifique o evento e tente novamente.';
          case 'permission-denied':
            return 'Sem permissão para completar a inscrição. Contacte a organização.';
          case 'unavailable':
            return 'Serviço temporariamente indisponível. Verifique a internet e tente novamente.';
          case 'deadline-exceeded':
            return 'A operação demorou demasiado. Tente novamente em instantes.';
          default:
            return error.message ?? 'Erro de base de dados (${error.code}).';
        }
      }
      // Other Firebase plugins
      switch (error.code) {
        case 'network-request-failed':
          return 'Sem ligação à internet. Verifique a conexão e tente novamente.';
        default:
          return error.message ?? fallback;
      }
    }
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
    _loadAcceptedTerms();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fetchActiveEventOptions();
  }

  Future<void> _checkExistingUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      debugPrint('✅ Utilizador autenticado detectado: ${currentUser.uid}');
      _prefillFromAuthUser(currentUser);
      if (mounted) {
        setState(() {
          _isExistingUser = true;
          _existingUserId = currentUser.uid;
        });
      }
      await _loadExistingUserData(currentUser.uid);
    } else {
      debugPrint('ℹ️ Nenhum utilizador autenticado. Fluxo de novo registo.');
    }
  }

  Future<void> _loadExistingUserData(String uid) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        debugPrint('⚠️ Documento do utilizador não encontrado');
        if (mounted) {
          Get.snackbar(
            'Conta sem perfil',
            'Ainda não encontramos os seus dados no perfil. Preencha e serão guardados ao finalizar.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: shellYellow.withValues(alpha: 0.9),
            colorText: Colors.black87,
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 4),
          );
        }
        return;
      }
      final userData = userDoc.data()!;
      if (!mounted) return;
      setState(() {
        final nome = _getFirstNonEmpty(userData, ['nome', 'name', 'fullName']);
        final telefone = _getFirstNonEmpty(userData, [
          'telefone',
          'phone',
          'telemovel',
        ]);
        final email = _getFirstNonEmpty(userData, ['email', 'mail']);
        final emergencia = _getFirstNonEmpty(userData, [
          'emergencia',
          'emergency',
          'emergencyContact',
        ]);
        final tshirt = _getFirstNonEmpty(userData, [
          'tshirt',
          'tShirt',
          'tshirt_size',
        ]);
        final localizacao = _getFirstNonEmpty(userData, [
          'localizacao',
          'location',
          'ilha',
        ]);

        if (_nameController.text.trim().isEmpty) {
          _nameController.text = nome;
        }
        if (_phoneController.text.trim().isEmpty) {
          _phoneController.text = telefone;
        }
        if (_emailController.text.trim().isEmpty) {
          _emailController.text = email;
        }
        if (_emergencyContactController.text.trim().isEmpty) {
          _emergencyContactController.text = emergencia;
        }

        _selectedShirtSize = (tshirt.isNotEmpty) ? tshirt : _selectedShirtSize;
        _selectedLocation =
            (localizacao.isNotEmpty) ? localizacao : _selectedLocation;

        _existingVeiculoId = userData['veiculoId'] ?? userData['vehicleId'];
        _existingEquipaId = userData['equipaId'] ?? userData['teamId'];
      });

      if (_existingVeiculoId != null) {
        final veiculoDoc =
            await FirebaseFirestore.instance
                .collection('veiculos')
                .doc(_existingVeiculoId)
                .get();
        if (veiculoDoc.exists) {
          final veiculoData = veiculoDoc.data()!;
          if (!mounted) return;
          setState(() {
            final matricula = _getFirstNonEmpty(veiculoData, [
              'matricula',
              'placa',
              'licensePlate',
            ]);
            final modelo = _getFirstNonEmpty(veiculoData, [
              'modelo',
              'model',
              'carModel',
            ]);
            final nomeEquipa = _getFirstNonEmpty(veiculoData, [
              'nome_equipa',
              'equipa',
              'teamName',
            ]);
            final localizacaoVeiculo = _getFirstNonEmpty(veiculoData, [
              'localizacao',
              'location',
              'ilha',
            ]);

            if (_licensePlateController.text.trim().isEmpty) {
              _licensePlateController.text = matricula;
            }
            if (_carModelController.text.trim().isEmpty) {
              _carModelController.text = modelo;
            }
            if (_teamNameController.text.trim().isEmpty) {
              _teamNameController.text = nomeEquipa;
            }
            if (_selectedLocation == null || _selectedLocation!.isEmpty) {
              _selectedLocation =
                  localizacaoVeiculo.isNotEmpty
                      ? localizacaoVeiculo
                      : _selectedLocation;
            }
            final passageiros = veiculoData['passageiros'] as List?;
            if (passageiros != null) {
              passageirosControllers =
                  passageiros.map((p) {
                    final map = Map<String, dynamic>.from(p);
                    return {
                      'nome': TextEditingController(
                        text: _getFirstNonEmpty(map, ['nome', 'name']),
                      ),
                      'telefone': TextEditingController(
                        text: _getFirstNonEmpty(map, ['telefone', 'phone']),
                      ),
                      'tshirt': TextEditingController(
                        text: _getFirstNonEmpty(map, ['tshirt', 'tShirt']),
                      ),
                    };
                  }).toList();
            }
          });
        }
      }
      debugPrint('✅ Dados do utilizador carregados com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao carregar dados do utilizador: $e');
    }
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
    final pages = <Widget>[
      _buildStepCondutor(),
      _buildStepCarro(),
      _buildStepPassageiros(),
      _buildStepEvento(),
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

  Future<Map<String, dynamic>> _getLocationPriceInfo(String location) async {
    try {
      String? eventPath = _selectedEventPath;
      if (eventPath == null) {
        final qs =
            await FirebaseFirestore.instance
                .collectionGroup('events')
                .where('status', isEqualTo: true)
                .limit(1)
                .get();
        if (qs.docs.isNotEmpty) {
          eventPath = qs.docs.first.reference.path;
          if (mounted) {
            setState(() {
              _selectedEventPath = eventPath;
              _selectedEventId = qs.docs.first.id;
            });
          }
        }
      }
      if (eventPath == null) {
        return {'price': 0.0, 'maxVehicles': -1, 'currentVehicles': 0};
      }

      final eventDoc = await FirebaseFirestore.instance.doc(eventPath).get();

      if (!eventDoc.exists) {
        return {'price': 0.0, 'maxVehicles': -1, 'currentVehicles': 0};
      }

      final eventData = eventDoc.data()!;
      double price = 0;
      int maxVehicles = -1;

      // Suporta dois formatos: (A) { "Santiago": 18000 }, (B) { "Santiago": { "price": 18000, "maxVehicles": 50 } }
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
              .where('eventoId', isEqualTo: eventPath)
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

  Future<void> _loadAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('acceptedTerms') ?? false;
    if (mounted) {
      setState(() => _acceptedTerms = accepted);
    }
  }

  Future<void> _fetchActiveEventOptions() async {
    if (!mounted) return;

    setState(() => _loadingEvents = true);

    Future<List<Map<String, String>>> viaCollectionGroup() async {
      final qs =
          await FirebaseFirestore.instance
              .collectionGroup('events')
              .where('status', isEqualTo: true)
              .get();

      final List<Map<String, String>> results = [];
      for (final d in qs.docs) {
        final eventPath = d.reference.path;
        final data = d.data();
        final eventName =
            (data['name'] ?? data['nome'] ?? 'Evento sem nome').toString();

        String editionName = '';
        final parentEditionRef = d.reference.parent.parent;
        if (parentEditionRef != null) {
          final editionSnap = await parentEditionRef.get();
          if (editionSnap.exists) {
            final ed = editionSnap.data();
            editionName = (ed?['name'] ?? ed?['nome'] ?? '').toString();
          }
        }

        final label =
            (editionName.isNotEmpty) ? '$editionName – $eventName' : eventName;
        results.add({'path': eventPath, 'label': label, 'eventId': d.id});
      }
      return results;
    }

    Future<List<Map<String, String>>> viaPerEdition() async {
      final List<Map<String, String>> results = [];
      final editions =
          await FirebaseFirestore.instance.collection('editions').get();
      for (final ed in editions.docs) {
        final edData = ed.data();
        final editionName = (edData['name'] ?? edData['nome'] ?? '').toString();
        final eventsSnap =
            await ed.reference
                .collection('events')
                .where('status', isEqualTo: true)
                .get();
        for (final ev in eventsSnap.docs) {
          final evData = ev.data();
          final eventName =
              (evData['name'] ?? evData['nome'] ?? 'Evento sem nome')
                  .toString();
          final label =
              (editionName.isNotEmpty)
                  ? '$editionName – $eventName'
                  : eventName;
          results.add({
            'path': ev.reference.path,
            'label': label,
            'eventId': ev.id,
          });
        }
      }
      return results;
    }

    try {
      // 1) Tenta pela collectionGroup (recomendada)
      List<Map<String, String>> results = await viaCollectionGroup();

      // 2) Se vazio ou qualquer problema inesperado, tenta fallback por edição
      if (results.isEmpty) {
        try {
          debugPrint(
            'ℹ️ Nenhum evento via collectionGroup. Tentando fallback por edição…',
          );
          results = await viaPerEdition();
        } catch (e) {
          // se o fallback falhar, relança para ser tratado no catch externo
          rethrow;
        }
      }

      results.sort((a, b) => a['label']!.compareTo(b['label']!));

      if (!mounted) return;
      setState(() {
        _eventOptions = results;
        _loadingEvents = false;
        if (results.length == 1) {
          _selectedEventPath = results.first['path'];
          _selectedEventId = results.first['eventId'];
        }
      });
      debugPrint('✅ ${results.length} evento(s) ativo(s) carregado(s)');
    } catch (e) {
      // 3) Última tentativa: se o erro original foi na collectionGroup (ex.: index/permissions),
      // tenta explicitamente o fallback antes de exibir erro ao utilizador.
      try {
        final results = await viaPerEdition();
        results.sort((a, b) => a['label']!.compareTo(b['label']!));
        if (!mounted) return;
        setState(() {
          _eventOptions = results;
          _loadingEvents = false;
          if (results.length == 1) {
            _selectedEventPath = results.first['path'];
            _selectedEventId = results.first['eventId'];
          }
        });
        debugPrint(
          '✅ Fallback por edição funcionou: ${results.length} evento(s) carregado(s)',
        );
      } catch (fallbackError) {
        debugPrint(
          '❌ Erro ao carregar eventos (group e fallback): $e | fallback: $fallbackError',
        );
        if (!mounted) return;
        setState(() {
          _eventOptions = [];
          _loadingEvents = false;
          _error = 'Erro ao carregar eventos disponíveis';
        });
      }
    }
  }

  void _register() async {
    debugPrint('▶️ Método _register() iniciado');
    debugPrint(
      '🔍 Tipo de registo: ${_isExistingUser ? "Utilizador existente" : "Novo utilizador"}',
    );

    if (!_isExistingUser) {
      if (_passwordController.text != _confirmPasswordController.text) {
        if (!mounted) return;
        setState(() => _error = 'As senhas não coincidem');
        return;
      }
      if (_emailController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty ||
          _confirmPasswordController.text.trim().isEmpty) {
        if (!mounted) return;
        setState(() => _error = 'Email e senha são obrigatórios');
        return;
      }
    }

    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _emergencyContactController.text.trim().isEmpty ||
        _licensePlateController.text.trim().isEmpty ||
        _carModelController.text.trim().isEmpty ||
        _selectedLocation == null ||
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

    if (_selectedEventPath == null || _selectedEventPath!.trim().isEmpty) {
      setState(() => _error = 'Selecione um evento válido antes de finalizar.');
      return;
    }

    debugPrint('✔️ Validações concluídas, verificando limites e preços');

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Ler evento
      final eventDoc =
          await FirebaseFirestore.instance.doc(_selectedEventPath!).get();
      if (!mounted) return;
      if (!eventDoc.exists) {
        setState(
          () =>
              _error =
                  'Evento selecionado não existe mais. Atualize a lista e escolha outro.',
        );
        Get.snackbar(
          'Evento indisponível',
          'O evento selecionado foi removido ou está inativo. Selecione outro evento.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: shellRed.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 4),
        );
        return;
      }

      final Map<String, dynamic> eventData = eventDoc.data()!;
      String? editionName;
      final parentEditionRef = eventDoc.reference.parent.parent;
      if (parentEditionRef != null) {
        try {
          final editionSnap = await parentEditionRef.get();
          if (editionSnap.exists) {
            final editionData = editionSnap.data();
            editionName =
                (editionData?['name'] ?? editionData?['nome'])?.toString();
          }
        } on FirebaseException catch (e) {
          debugPrint('Aviso: falha ao ler edição pai: ${e.code}');
        }
      }
      final nomeEvento =
          (eventData['nome'] ?? eventData['name'] ?? editionName ?? 'Sem nome')
              .toString();

      double price = 0;
      int maxVehicles = -1;
      if (eventData.containsKey('pricesByLocation')) {
        final raw = eventData['pricesByLocation'];
        Map<String, dynamic>? pricesByLocation;
        if (raw is Map) {
          pricesByLocation = Map<String, dynamic>.from(raw);
        }
        if (pricesByLocation != null &&
            pricesByLocation.containsKey(_selectedLocation)) {
          final val = pricesByLocation[_selectedLocation];
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
          debugPrint('💰 Preço para $_selectedLocation: $price CVE');
          debugPrint(
            '🚗 Limite de veículos: ${maxVehicles == -1 ? "Ilimitado" : maxVehicles}',
          );
        }
      } else {
        price = double.tryParse('${eventData['price'] ?? 0}') ?? 0;
      }

      // Verificar limite de veículos
      if (maxVehicles > 0) {
        final veiculosQuery =
            await FirebaseFirestore.instance
                .collection('veiculos')
                .where('eventoId', isEqualTo: _selectedEventPath)
                .where('localizacao', isEqualTo: _selectedLocation)
                .get();
        final totalVeiculos = veiculosQuery.size;
        debugPrint(
          '📊 Veículos já registrados em $_selectedLocation (evento $_selectedEventId): $totalVeiculos/$maxVehicles',
        );
        if (totalVeiculos >= maxVehicles) {
          if (!mounted) return;
          setState(
            () =>
                _error =
                    'Vagas esgotadas em $_selectedLocation. Limite de $maxVehicles veículos atingido.',
          );
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
      }

      // Acompanhantes extra e preço final
      final int extrasCount = (passageirosControllers.length - 1).clamp(0, 2);
      final double extrasTotal = extrasCount * 7500.0;
      final double finalPrice = price + extrasTotal;
      debugPrint(
        '💵 Acompanhantes extra: $extrasCount x 7.500 = ${extrasTotal.toStringAsFixed(0)} CVE',
      );
      debugPrint('💵 Preço final: ${finalPrice.toStringAsFixed(0)} CVE');

      String uid;
      if (_isExistingUser) {
        uid = _existingUserId!;
        // validar duplicidade de registo neste evento com base no caminho completo do evento
        final dupSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('events')
            .where('eventoPath', isEqualTo: _selectedEventPath)
            .limit(1)
            .get();
        if (dupSnap.docs.isNotEmpty) {
          if (!mounted) return;
          setState(() => _error = 'Já está registado neste evento.');
          Get.snackbar(
            'Registo duplicado',
            'Já possui uma inscrição ativa neste evento.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: shellRed.withValues(alpha: 0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 4),
          );
          return;
        }
      } else {
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

      debugPrint(
        '🧭 _selectedEventPath=$_selectedEventPath | _selectedEventId=$_selectedEventId',
      );

      String veiculoId;
      String equipaId;

      // Criar/atualizar veículo
      if (_isExistingUser && _existingVeiculoId != null) {
        veiculoId = _existingVeiculoId!;
        debugPrint('🔄 Atualizando veículo existente: $veiculoId');
        await FirebaseFirestore.instance
            .collection('veiculos')
            .doc(veiculoId)
            .update({
              'matricula': _licensePlateController.text.trim(),
              'modelo': _carModelController.text.trim(),
              'nome_equipa': _teamNameController.text.trim(),
              'localizacao': _selectedLocation ?? '',
              'passageiros': passageiros,
              'eventoId': _selectedEventPath,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } else {
        veiculoId = FirebaseFirestore.instance.collection('veiculos').doc().id;
        debugPrint('🆕 Criando novo veículo: $veiculoId');
        final carData = {
          'ownerId': uid,
          'matricula': _licensePlateController.text.trim(),
          'modelo': _carModelController.text.trim(),
          'nome_equipa': _teamNameController.text.trim(),
          'localizacao': _selectedLocation ?? '',
          'passageiros': passageiros,
          'pontuacao_total': 0,
          'checkpoints': {},
          'eventoId': _selectedEventPath,
          'createdAt': FieldValue.serverTimestamp(),
        };
        await FirebaseFirestore.instance
            .collection('veiculos')
            .doc(veiculoId)
            .set(carData);
      }

      // Criar/atualizar equipa
      if (_isExistingUser && _existingEquipaId != null) {
        equipaId = _existingEquipaId!;
        debugPrint('🔄 Atualizando equipa existente: $equipaId');
        await FirebaseFirestore.instance
            .collection('equipas')
            .doc(equipaId)
            .update({
              'nome': _teamNameController.text.trim(),
              'membros': [uid, ...passageiros.map((p) => p['telefone'])],
              'localizacao': _selectedLocation ?? '',
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } else {
        equipaId = FirebaseFirestore.instance.collection('equipas').doc().id;
        debugPrint('🆕 Criando nova equipa: $equipaId');
        final equipaData = {
          'nome': _teamNameController.text.trim(),
          'hino': '',
          'bandeiraUrl': '',
          'pontuacaoTotal': 0,
          'ranking': 0,
          'membros': [uid, ...passageiros.map((p) => p['telefone'])],
          'localizacao': _selectedLocation ?? '',
        };
        await FirebaseFirestore.instance
            .collection('equipas')
            .doc(equipaId)
            .set(equipaData);
      }

      // Atualizar/criar documento do utilizador
      if (_isExistingUser) {
        debugPrint('🔄 Atualizando dados do utilizador existente');
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'nome': _nameController.text.trim(),
          'telefone': _phoneController.text.trim(),
          'emergencia': _emergencyContactController.text.trim(),
          'tshirt': _selectedShirtSize ?? '',
          'localizacao': _selectedLocation ?? '',
          'veiculoId': veiculoId,
          'equipaId': equipaId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        debugPrint('🆕 Criando documento do novo utilizador');
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'nome': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'telefone': _phoneController.text.trim(),
          'emergencia': _emergencyContactController.text.trim(),
          'tshirt': _selectedShirtSize ?? '',
          'localizacao': _selectedLocation ?? '',
          'role': 'user',
          'eventoId': _selectedEventPath,
          'eventoNome': nomeEvento,
          'ativo': true,
          'veiculoId': veiculoId,
          'equipaId': equipaId,
          'checkpointsVisitados': [],
          'createdAt': FieldValue.serverTimestamp(),
          'paymentStatus': 'pending',
          'transactionId': '',
          'amountPaid': 0,
          'paymentMethod': _paymentMethod,
          'precoBase': price,
          'acompanhantesExtras': extrasCount,
          'valorPorAcompanhante': 7500,
          'precoTotal': finalPrice,
        });
      }

      // Subcoleção de eventos (sempre) — garante ID único sem sobrescrever históricos
      final eventsCol = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('events');
      String subEventDocId = _selectedEventId!;
      final possibleCollision = await eventsCol.doc(subEventDocId).get();
      if (possibleCollision.exists) {
        final data = possibleCollision.data();
        final existingPath = data?['eventoPath'] as String?;
        if (existingPath != null && existingPath != _selectedEventPath) {
          // evita overwrite caso exista um doc antigo com mesmo eventoId de outra edição
          final lastSegment = _selectedEventPath!.split('/').last;
          subEventDocId = '${_selectedEventId}_$lastSegment';
        }
      }
      await eventsCol.doc(subEventDocId).set({
        'eventoId': _selectedEventId,
        'eventoPath': _selectedEventPath,
        'checkpointsVisitados': [],
        'localizacao': _selectedLocation ?? '',
        'preco': price,
        'precoBase': price,
        'acompanhantesExtras': extrasCount,
        'valorPorAcompanhante': 7500,
        'precoTotal': finalPrice,
        'paymentStatus': 'pending',
        'paymentMethod': _paymentMethod,
        'registeredAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Subcoleção events criada com sucesso: $subEventDocId');

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'ultimoLogin': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('acceptedTerms', true);

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

      final mensagem =
          _isExistingUser
              ? 'Registo no evento submetido com sucesso!'
              : 'Conta criada e registo no evento submetido!';
      Get.snackbar(
        'Sucesso',
        '$mensagem Receberá instruções de pagamento pela organização.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
      );
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ FirebaseException no register: ${e.plugin} ${e.code} ${e.message}',
      );
      if (!mounted) return;
      final msg = _mapFriendlyError(e);
      setState(() => _error = msg);
      Get.snackbar(
        'Erro ao realizar inscrição',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: shellRed.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('❌ Erro inesperado no register: $e');
      if (!mounted) return;
      setState(() => _error = 'Ocorreu um erro inesperado. Tente novamente.');
      Get.snackbar(
        'Erro inesperado',
        'Não foi possível concluir a inscrição. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: shellRed.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
      );
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
                _isExistingUser ? 'Registar em Evento' : 'Criar Conta',
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
        return 'Evento e Confirmação';
      case 4:
        return 'Finalização';
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
                if (_isExistingUser)
                  Container(
                    margin: EdgeInsets.only(
                      bottom: _getResponsiveSpacing(context, 24),
                    ),
                    padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withValues(alpha: 0.10),
                          Colors.blue.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        _getResponsiveSpacing(context, 12),
                      ),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: Colors.blue,
                          size: _getResponsiveSpacing(context, 24),
                        ),
                        SizedBox(width: _getResponsiveSpacing(context, 12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bem-vindo de volta!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: _getResponsiveFontSize(context, 16),
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              SizedBox(
                                height: _getResponsiveSpacing(context, 4),
                              ),
                              Text(
                                'Os seus dados foram carregados. Pode alterá-los antes de registar no novo evento.',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 14),
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                if (!_isExistingUser) ...[
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
                        _error != null &&
                        _passwordController.text.trim().isEmpty,
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
                ],
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
                        _selectedShirtSize == null) {
                      setState(
                        () => _error = 'Preencha todos os campos obrigatórios.',
                      );
                      return;
                    }
                    if (!_isExistingUser) {
                      if (_passwordController.text !=
                          _confirmPasswordController.text) {
                        setState(() => _error = 'As senhas não coincidem');
                        return;
                      }
                      if (_emailController.text.trim().isEmpty ||
                          _passwordController.text.trim().isEmpty ||
                          _confirmPasswordController.text.trim().isEmpty) {
                        setState(
                          () => _error = 'Email e senha são obrigatórios.',
                        );
                        return;
                      }
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
                            // Insert capacity info here
                            SizedBox(height: _getResponsiveSpacing(context, 8)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Capacidade (por viatura):',
                                  style: TextStyle(
                                    fontSize: _getResponsiveFontSize(
                                      context,
                                      14,
                                    ),
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  '4 pessoas (Piloto + Co-piloto + 2 acompanhantes)',
                                  style: TextStyle(
                                    fontSize: _getResponsiveFontSize(
                                      context,
                                      14,
                                    ),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
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

        // Show Snackbar if trying to add more than 2 acompanhantes (total 4 pessoas)
        if (passageirosControllers.length >= 3) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Limite atingido: máximo de 2 acompanhantes (total de 4 pessoas por carro).',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 14),
                  ),
                ),
                backgroundColor: shellRed,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(_getResponsiveSpacing(context, 12)),
                duration: const Duration(seconds: 3),
              ),
            );
          });
        }

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
                  'Máximo de 2 acompanhantes (além do co-piloto)',
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
                if (passageirosControllers.length < 3)
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
                        'Adicionar Passageiro', // Regra: inscrição inclui piloto + co-piloto; cada acompanhante extra (até 2) custa 7.500 CVE
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
                    if (passageirosControllers.length > 3) {
                      setState(
                        () =>
                            _error =
                                'Máximo permitido: 2 acompanhantes (equipa com 4 participantes no total).',
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
                if (_loadingEvents)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(spacing),
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: shellOrange),
                          SizedBox(height: spacing),
                          Text(
                            'Carregando eventos disponíveis...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: _getResponsiveFontSize(context, 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_eventOptions.isEmpty)
                  Container(
                    padding: EdgeInsets.all(_getResponsiveSpacing(context, 20)),
                    decoration: BoxDecoration(
                      color: shellRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        _getResponsiveSpacing(context, 16),
                      ),
                      border: Border.all(color: shellRed),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          color: shellRed,
                          size: _getResponsiveSpacing(context, 48),
                        ),
                        SizedBox(height: spacing),
                        Text(
                          'Nenhum evento ativo disponível no momento',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                            color: shellRed,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Entre em contato com a organização para mais informações',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(context, 14),
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        _getResponsiveSpacing(context, 16),
                      ),
                      color: Colors.white,
                      border: Border.all(
                        color:
                            (_error != null && _selectedEventPath == null)
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
                      initialValue: _selectedEventPath,
                      isExpanded: true,
                      hint: Text(
                        'Escolha um evento',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 14),
                          color: Colors.grey.shade600,
                        ),
                      ),
                      items:
                          _eventOptions.map((opt) {
                            return DropdownMenuItem<String>(
                              value: opt['path'],
                              child: Text(
                                opt['label'] ?? '',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 15),
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final selectedEvent = _eventOptions.firstWhere(
                            (e) => e['path'] == val,
                          );
                          setState(() {
                            _selectedEventPath = val;
                            _selectedEventId = selectedEvent['eventId'];
                            _error = null;
                          });
                          debugPrint(
                            '✅ Evento selecionado: ${selectedEvent['label']} | path=${selectedEvent['path']} | id=${selectedEvent['eventId']}',
                          );
                        }
                      },
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.event_outlined,
                          color: shellOrange,
                          size: _getResponsiveSpacing(context, 22),
                        ),
                        border: InputBorder.none,
                        labelText: 'Evento *',
                        labelStyle: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 14),
                          color:
                              (_error != null && _selectedEventPath == null)
                                  ? shellRed
                                  : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                if (_selectedEventPath != null) ...[
                  SizedBox(height: spacing),
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: _getResponsiveSpacing(context, 24),
                        ),
                        SizedBox(width: _getResponsiveSpacing(context, 12)),
                        Expanded(
                          child: Text(
                            'Evento selecionado com sucesso!',
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(context, 14),
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: _getResponsiveSpacing(context, 24)),
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
                    if (_selectedEventPath == null ||
                        _selectedEventPath!.isEmpty) {
                      setState(
                        () => _error = 'Por favor, selecione um evento válido.',
                      );
                      return;
                    }
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
                  isLastStep: false,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Valor base (piloto + co-piloto):',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 14),
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                '${price.toStringAsFixed(0)} CVE',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 16),
                                  fontWeight: FontWeight.bold,
                                  color: shellRed,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: _getResponsiveSpacing(context, 8)),
                          Builder(
                            builder: (ctx) {
                              final extras = (passageirosControllers.length - 1)
                                  .clamp(0, 3);
                              final extrasTotal = extras * 7500;
                              final totalEstimado = price + extrasTotal;
                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Acompanhantes extra:',
                                        style: TextStyle(
                                          fontSize: _getResponsiveFontSize(
                                            context,
                                            14,
                                          ),
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      Text(
                                        '$extras x 7.500 CVE = ${extrasTotal.toStringAsFixed(0)} CVE',
                                        style: TextStyle(
                                          fontSize: _getResponsiveFontSize(
                                            context,
                                            14,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: _getResponsiveSpacing(context, 8),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total estimado:',
                                        style: TextStyle(
                                          fontSize: _getResponsiveFontSize(
                                            context,
                                            15,
                                          ),
                                          color: Colors.grey.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${totalEstimado.toStringAsFixed(0)} CVE',
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
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: spacing),

                    // Método de pagamento (Material 3)
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
                            label: Text('Transferência bancária'),
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

                    // Instruções contextuais
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
                          'Após finalizar, entra na App Pagali ou no site https://pagali.cv na área "Eventos" . Envie o comprovativo para: manoamanooffroad@gmail.com. A participação só será validada após confirmação do pagamento.',
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
                              'Efetue a transferência para o NIB: 000500000831804210197 (Banco Interatlântico). Envie o comprovativo para: manoamanooffroad@gmail.com.',
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(context, 14),
                              ),
                            ),
                            SizedBox(height: _getResponsiveSpacing(context, 8)),
                            Text(
                              'A participação no evento só será validada após a confirmação.',
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
                      onNext: _register,
                      isLastStep: true,
                    ),

                    if (_error != null) ...[
                      SizedBox(height: _getResponsiveSpacing(context, 16)),
                      Container(
                        padding: EdgeInsets.all(
                          _getResponsiveSpacing(context, 16),
                        ),
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
      },
    );
  }
}
