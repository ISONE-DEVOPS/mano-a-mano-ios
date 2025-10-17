import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

class EditParticipantesView extends StatefulWidget {
  final String userId;
  // Opcional: caminho completo do evento (ex.: editions/{ed}/events/{ev})
  final String? eventPath;
  // Opcional: ID do documento dentro de users/{uid}/events/{docId}
  final String? eventDocId;
  const EditParticipantesView({
    super.key,
    required this.userId,
    this.eventPath,
    this.eventDocId,
  });

  @override
  State<EditParticipantesView> createState() => _EditParticipantesViewState();
}

class _EditParticipantesViewState extends State<EditParticipantesView>
    with SingleTickerProviderStateMixin {
  final _personalFormKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Scroll controllers por aba
  final ScrollController _personalScroll = ScrollController();
  final ScrollController _paymentScroll = ScrollController();

  // Keys para rolar até o primeiro campo inválido
  final _nomeKey = GlobalKey();
  final _emailKey = GlobalKey();
  final _telKey = GlobalKey();
  final _emergKey = GlobalKey();
  final _tshirtKey = GlobalKey();
  final _equipaKey = GlobalKey();
  final _veiculoKey = GlobalKey();
  final _priceKey = GlobalKey();

  // Controllers
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final emergenciaController = TextEditingController();
  final tshirtController = TextEditingController();
  final priceController = TextEditingController();

  // Data
  Map<String, String> equipas = {};
  String? equipaSelecionada;
  Map<String, String> veiculos = {};
  String? veiculoSelecionado;

  bool isLoading = true;
  bool isSaving = false;
  bool isPago = false;
  bool isAtivo = true;
  String? role = 'user';
  DateTime? createAt;
  DateTime? ultimoLogin;

  // T-shirt sizes
  final List<String> tamanhosTshirt = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  final List<String> roles = ['admin', 'user', 'staff'];

  final currencyFormatter = NumberFormat.currency(
    locale: 'pt_CV',
    symbol: 'CVE',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _personalScroll.dispose();
    _paymentScroll.dispose();
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    emergenciaController.dispose();
    tshirtController.dispose();
    priceController.dispose();
    super.dispose();
  }

  // Helper para normalizar valores numéricos vindos do Firestore
  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.trim().replaceAll(' ', '').replaceAll(',', '.');
      return double.tryParse(s);
    }
    return null;
  }

  /// Resolve o documento alvo em users/{uid}/events com base em [widget.eventDocId] ou [widget.eventPath].
  /// Fallback: último evento por registeredAt.
  Future<DocumentReference<Map<String, dynamic>>?> _getTargetEventRef() async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId);
    final eventsCol = userRef.collection('events');
    // 1) Se veio eventDocId diretamente
    if (widget.eventDocId != null && widget.eventDocId!.trim().isNotEmpty) {
      return eventsCol.doc(widget.eventDocId!.trim());
    }
    // 2) Se veio eventPath, procura por campo eventoPath
    if (widget.eventPath != null && widget.eventPath!.trim().isNotEmpty) {
      final byPath =
          await eventsCol
              .where('eventoPath', isEqualTo: widget.eventPath!.trim())
              .limit(1)
              .get();
      if (byPath.docs.isNotEmpty) {
        return eventsCol.doc(byPath.docs.first.id);
      }
    }
    // 3) Fallback: último por registeredAt (pode não ser o ativo, mas evita null)
    try {
      final last =
          await eventsCol
              .orderBy('registeredAt', descending: true)
              .limit(1)
              .get();
      if (last.docs.isNotEmpty) return eventsCol.doc(last.docs.first.id);
    } catch (_) {
      final any = await eventsCol.limit(1).get();
      if (any.docs.isNotEmpty) return eventsCol.doc(any.docs.first.id);
    }
    return null;
  }

  Future<void> _carregarDados() async {
    try {
      // Carregar dados do usuário
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .get();

      // Carregar equipas
      final equipesSnapshot =
          await FirebaseFirestore.instance.collection('equipas').get();
      final equipasTemp = <String, String>{};
      for (final doc in equipesSnapshot.docs) {
        equipasTemp[doc.id] = doc['nome'] ?? 'Sem nome';
      }

      // Carregar veículos
      final veiculosSnapshot =
          await FirebaseFirestore.instance.collection('veiculos').get();
      final veiculosTemp = <String, String>{};
      for (final doc in veiculosSnapshot.docs) {
        veiculosTemp[doc.id] =
            '${doc['modelo'] ?? 'Modelo'} - ${doc['matricula'] ?? 'Sem matrícula'}';
      }

      // Carrega o evento alvo (por eventDocId, eventPath ou fallback)
      double? latestEventValorPago;
      double? latestEventPrecoTotal;
      double? latestEventPreco;
      bool? latestEventPagoFlag;
      try {
        final targetRef = await _getTargetEventRef();
        if (targetRef != null) {
          final evSnap = await targetRef.get();
          if (evSnap.exists) {
            final evData = evSnap.data() ?? {};
            final pagamento =
                (evData['pagamento'] ?? {}) as Map<String, dynamic>;
            latestEventValorPago = _asDouble(pagamento['valorPago']);
            latestEventPrecoTotal = _asDouble(evData['precoTotal']);
            latestEventPreco = _asDouble(evData['preco']);
            final status = (evData['paymentStatus'] ?? '').toString();
            if (status.isNotEmpty) {
              latestEventPagoFlag = status.toLowerCase() == 'paid';
            }
            // Se status não existir, infere com base em um dos valores > 0
            latestEventPagoFlag ??=
                (latestEventValorPago ??
                    latestEventPrecoTotal ??
                    latestEventPreco ??
                    0) >
                0;
          }
        }
      } catch (_) {
        // silencioso
      }

      if (!mounted) return;
      setState(() {
        equipas = equipasTemp;
        veiculos = veiculosTemp;

        final data = doc.data();
        if (data != null) {
          nomeController.text = data['nome'] ?? '';
          emailController.text = data['email'] ?? '';
          telefoneController.text = data['telefone'] ?? '';
          emergenciaController.text = data['emergencia'] ?? '';
          tshirtController.text = data['tshirt'] ?? '';
          equipaSelecionada = data['equipaId'];
          veiculoSelecionado = data['veiculoId'];

          // Novos campos
          priceController.text = (data['price'] ?? 0).toString();
          isPago = data['isPago'] ?? false;
          isAtivo = data['ativo'] ?? true;
          role = data['role'] ?? 'user';

          // Prioridade para exibição do preço ao reabrir a tela:
          // 1) pagamento.valorPago  2) precoTotal  3) preco  4) users.price
          final userPrice =
              _asDouble(data['price']) ?? _asDouble(data['preco']);
          final displayPrice =
              latestEventValorPago ??
              latestEventPrecoTotal ??
              latestEventPreco ??
              userPrice ??
              0.0;
          priceController.text = displayPrice.toString();

          // Sincroniza status de pagamento com o evento se existir, senão mantém do user
          if (latestEventPagoFlag != null) {
            isPago = latestEventPagoFlag;
          }

          if (data['createAt'] != null) {
            createAt = (data['createAt'] as Timestamp).toDate();
          }
          if (data['ultimoLogin'] != null) {
            ultimoLogin = (data['ultimoLogin'] as Timestamp).toDate();
          }
        }
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showErrorSnackBar('Erro ao carregar dados: $e');
      }
    }
  }

  Future<void> _salvarAlteracoes() async {
    // Valida apenas a aba ativa + rola até o primeiro campo inválido
    final currentTab = _tabController.index;
    if (currentTab == 0) {
      if (!(_personalFormKey.currentState?.validate() ?? false)) {
        _showErrorSnackBar('Verifique os campos obrigatórios na aba Pessoal.');
        await _scrollToFirstInvalidPersonal();
        return;
      }
    } else if (currentTab == 2) {
      if (!(_paymentFormKey.currentState?.validate() ?? false)) {
        _showErrorSnackBar(
          'Verifique os campos obrigatórios na aba Pagamento.',
        );
        await _scrollToFirstInvalidPayment();
        return;
      }
    }

    setState(() => isSaving = true);

    try {
      // Garantir que o valor está correto (aceita vírgula e espaço)
      final raw = priceController.text
          .trim()
          .replaceAll(' ', '')
          .replaceAll(',', '.');
      final price = double.tryParse(raw.isEmpty ? '0' : raw) ?? 0.0;

      // Debug - remover depois de testar
      developer.log(
        'Salvando price: $price, isPago: $isPago',
        name: 'EditParticipantes',
      );

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId);
      // Grava no documento do utilizador
      await userRef.update({
        'nome': nomeController.text.trim(),
        'email': emailController.text.trim(),
        'telefone': telefoneController.text.trim(),
        'emergencia': emergenciaController.text.trim(),
        'tshirt': tshirtController.text.trim(),
        'equipaId': equipaSelecionada,
        'veiculoId': veiculoSelecionado,
        'price': price,
        'isPago':
            isPago ||
            price > 0, // se há valor, considera pago no perfil (espelho)
        'ativo': isAtivo,
        'role': role,
      });

      // Garante que o controller reflete o valor normalizado (com ponto)
      priceController.text = price.toString();

      // Grava no evento alvo (por eventDocId / eventPath / fallback)
      try {
        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId);
        final targetRef = await _getTargetEventRef();
        DocumentReference<Map<String, dynamic>> eventoRef;
        if (targetRef != null) {
          eventoRef = targetRef;
        } else {
          // Se não existir nenhum, cria um novo doc na subcoleção 'events'
          final eventsCol = userRef.collection('events');
          // Tenta usar o último segmento do eventPath como id (se fornecido), senão gera id automático
          String? newId;
          if (widget.eventPath != null && widget.eventPath!.trim().isNotEmpty) {
            newId = widget.eventPath!.trim().split('/').last;
          }
          eventoRef = newId != null ? eventsCol.doc(newId) : eventsCol.doc();
          await eventoRef.set({
            if (widget.eventPath != null && widget.eventPath!.trim().isNotEmpty)
              'eventoPath': widget.eventPath!.trim(),
            'registeredAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        await eventoRef.set({
          // Mantém o espelho do preço do evento nesta edição
          'preco': price.toDouble(),
          'precoTotal': price.toDouble(),
          'amountPaid': (isPago || price > 0) ? price.toDouble() : 0.0,
          'pagamento': {
            'valorPago': price.toDouble(),
            'metodo': isPago ? 'Pagali' : 'Pendente',
            'atualizadoEm': FieldValue.serverTimestamp(),
          },
          'paymentStatus': (isPago || price > 0) ? 'paid' : 'pending',
          // Garante que o path fica associado, se fornecido
          if (widget.eventPath != null && widget.eventPath!.trim().isNotEmpty)
            'eventoPath': widget.eventPath!.trim(),
        }, SetOptions(merge: true));
      } catch (e) {
        developer.log(
          'Falha ao atualizar pagamento no evento (alvo): $e',
          name: 'EditParticipantes',
          error: e,
        );
      }

      if (!mounted) return;
      _showSuccessSnackBar('Participante atualizado com sucesso!');
      Navigator.of(context).pop(true);
    } catch (e) {
      developer.log('Erro ao salvar', name: 'EditParticipantes', error: e);
      if (mounted) {
        _showErrorSnackBar('Erro ao salvar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Rola até tornar visível um campo identificado por key e scrollController
  Future<void> _ensureVisible(
    GlobalKey key,
    ScrollController controller,
  ) async {
    final ctx = key.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    } else {
      await controller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _scrollToFirstInvalidPersonal() async {
    // Usa as mesmas regras dos validadores
    if ((_validateRequired(nomeController.text, 'Nome') != null)) {
      return _ensureVisible(_nomeKey, _personalScroll);
    }
    if (_validateEmail(emailController.text) != null) {
      return _ensureVisible(_emailKey, _personalScroll);
    }
    if (_validatePhone(telefoneController.text) != null) {
      return _ensureVisible(_telKey, _personalScroll);
    }
    if (_validateRequired(
          emergenciaController.text,
          'Contacto de emergência',
        ) !=
        null) {
      return _ensureVisible(_emergKey, _personalScroll);
    }
    if (_validateRequired(tshirtController.text, 'Tamanho da T-shirt') !=
        null) {
      return _ensureVisible(_tshirtKey, _personalScroll);
    }
    if (equipaSelecionada == null) {
      return _ensureVisible(_equipaKey, _personalScroll);
    }
    if (veiculoSelecionado == null) {
      return _ensureVisible(_veiculoKey, _personalScroll);
    }
    // fallback
    await _personalScroll.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _scrollToFirstInvalidPayment() async {
    if (_validatePrice(priceController.text) != null) {
      return _ensureVisible(_priceKey, _paymentScroll);
    }
    // fallback
    await _paymentScroll.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email é obrigatório';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefone é obrigatório';
    }
    if (value.length < 7) {
      return 'Telefone deve ter pelo menos 7 dígitos';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Valor é obrigatório';
    }
    final normalized = value.trim().replaceAll(' ', '').replaceAll(',', '.');
    final price = double.tryParse(normalized);
    if (price == null || price < 0) {
      return 'Valor inválido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Participante'), elevation: 0),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando dados...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Participante'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white, // cor da aba ativa
          unselectedLabelColor: Colors.white70, // cor das inativas
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Pessoal'),
            Tab(icon: Icon(Icons.group), text: 'Acompanhantes'),
            Tab(icon: Icon(Icons.payment), text: 'Pagamento'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Pontuações'),
          ],
        ),
        actions: [
          if (!isSaving)
            TextButton.icon(
              onPressed: _salvarAlteracoes,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Salvar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDadosPessoaisTab(),
          _buildAcompanhantesTab(),
          _buildPagamentoTab(),
          _buildPontuacoesTab(),
        ],
      ),
    );
  }

  // Adiciona/edita passageiro/acompanhante do veículo
  Future<void> _showPassengerDialog({Map<String, dynamic>? initial, int? index}) async {
    if (veiculoSelecionado == null || veiculoSelecionado!.isEmpty) {
      _showErrorSnackBar('Selecione um veículo primeiro.');
      return;
    }

    final nomeCtrl = TextEditingController(text: (initial?['nome'] ?? '').toString());
    final telCtrl = TextEditingController(text: (initial?['telefone'] ?? '').toString());
    String papel = (initial?['papel'] ?? (initial?['isCoPiloto'] == true ? 'copiloto' : 'acompanhante')).toString().toLowerCase();
    if (papel.isEmpty) papel = 'acompanhante';

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(index == null ? 'Adicionar Acompanhante' : 'Editar Acompanhante'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeCtrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome é obrigatório' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: telCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Telefone é obrigatório';
                    if (v.trim().length < 7) return 'Mínimo 7 dígitos';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: ['condutor','copiloto','acompanhante'].contains(papel) ? papel : 'acompanhante',
                  items: const [
                    DropdownMenuItem(value: 'condutor', child: Text('Condutor')),
                    DropdownMenuItem(value: 'copiloto', child: Text('Co‑piloto')),
                    DropdownMenuItem(value: 'acompanhante', child: Text('Acompanhante')),
                  ],
                  onChanged: (v) => papel = (v ?? 'acompanhante'),
                  decoration: const InputDecoration(labelText: 'Papel'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;

                final veicRef = FirebaseFirestore.instance.collection('veiculos').doc(veiculoSelecionado);
                final veicSnap = await veicRef.get();
                final vData = veicSnap.data() ?? {};
                final rawList = vData['passageiros'];
                final List<Map<String, dynamic>> passageiros = [];
                if (rawList is List) {
                  for (final e in rawList) {
                    if (e is Map) {
                      try {
                        passageiros.add(Map<String, dynamic>.from(e));
                      } catch (_) {}
                    }
                  }
                }

                final newItem = <String, dynamic>{
                  'nome': nomeCtrl.text.trim(),
                  'telefone': telCtrl.text.trim(),
                  'papel': papel,
                  // flags de compatibilidade legada:
                  'isCoPiloto': papel == 'copiloto',
                  'isAcompanhante': papel == 'acompanhante',
                };

                // Se for edição, substitui; senão, adiciona (respeitando limite de 4 pessoas no carro)
                if (index != null) {
                  if (index >= 0 && index < passageiros.length) {
                    passageiros[index] = {...passageiros[index], ...newItem};
                  } else {
                    _showErrorSnackBar('Índice inválido para edição.');
                    return;
                  }
                } else {
                  // Limite total de pessoas no carro: 4 (Piloto + Co‑piloto + até 2 acompanhantes)
                  if (passageiros.length >= 4) {
                    _showErrorSnackBar('Limite de 4 pessoas por viatura atingido.');
                    return;
                  }
                  passageiros.add(newItem);
                }

                await veicRef.update({'passageiros': passageiros});
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                _showSuccessSnackBar(index == null ? 'Acompanhante adicionado!' : 'Acompanhante atualizado!');
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAcompanhantesTab() {
    // Se o participante ainda não tem veículo selecionado
    if (veiculoSelecionado == null || veiculoSelecionado!.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard(
            title: 'Acompanhantes do Condutor',
            icon: Icons.group_outlined,
            children: const [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Nenhum veículo selecionado para este participante. Selecione um veículo na aba Pessoal para ver os passageiros.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('veiculos')
              .doc(veiculoSelecionado)
              .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionCard(
                title: 'Acompanhantes do Condutor',
                icon: Icons.group_outlined,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Erro ao carregar veículo: ${snap.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        if (!snap.hasData || !snap.data!.exists) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionCard(
                title: 'Acompanhantes do Condutor',
                icon: Icons.group_outlined,
                children: const [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Veículo não encontrado.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        final vData = snap.data!.data() ?? {};
        final raw = vData['passageiros'];
        final List<Map<String, dynamic>> passageiros = [];
        if (raw is List) {
          for (final e in raw) {
            if (e is Map) {
              try {
                passageiros.add(Map<String, dynamic>.from(e));
              } catch (_) {}
            }
          }
        }

        final bool canAddPassenger = passageiros.length < 4;

        // Determina índices de condutor e co‑piloto
        int? driverIdx;
        int? copilotoIdx;
        // 1) Condutor = o passageiro cujo userId == widget.userId
        for (var i = 0; i < passageiros.length; i++) {
          final uid = passageiros[i]['userId'];
          if (uid != null && uid.toString() == widget.userId) {
            driverIdx = i;
            break;
          }
        }
        // 2) Copiloto preferencial: flag explícita
        for (var i = 0; i < passageiros.length; i++) {
          final papel =
              (passageiros[i]['papel'] ?? '').toString().toLowerCase();
          final isCo =
              passageiros[i]['isCoPiloto'] == true ||
              papel == 'copiloto' ||
              papel == 'co-piloto' ||
              papel == 'co_piloto';
          if (isCo) {
            copilotoIdx = i;
            break;
          }
        }
        // 3) Se ainda não definido, escolhe o primeiro passageiro diferente do condutor
        if (copilotoIdx == null && passageiros.isNotEmpty) {
          for (var i = 0; i < passageiros.length; i++) {
            if (driverIdx != null && i == driverIdx) continue;
            copilotoIdx = i;
            break;
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Botão rápido para adicionar acompanhante
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: canAddPassenger ? () => _showPassengerDialog() : null,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Adicionar acompanhante'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildSectionCard(
              title: 'Acompanhantes do Condutor',
              icon: Icons.group_outlined,
              children: [
                if (passageiros.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Sem passageiros registados neste veículo.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: passageiros.length,
                    separatorBuilder: (_, _) => const Divider(height: 8),
                    itemBuilder: (_, i) {
                      final p = passageiros[i];
                      final nome = (p['nome'] ?? '').toString();
                      final telefone = (p['telefone'] ?? '').toString();
                      // Papel por identificação (prioriza userId / flags; fallback por posição)
                      String papel;
                      if (driverIdx != null && i == driverIdx) {
                        papel = 'Condutor';
                      } else if (copilotoIdx != null && i == copilotoIdx) {
                        papel = 'Co‑piloto';
                      } else {
                        papel = 'Acompanhante';
                      }

                      // Campos extra quaisquer
                      final extra = <String, String>{};
                      for (final k in p.keys) {
                        if (k == 'nome' ||
                            k == 'telefone' ||
                            k == 'isAcompanhante') {
                          continue;
                        }
                        final v = p[k];
                        if (v == null) continue;
                        extra[k] = v.toString();
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              (driverIdx != null && i == driverIdx)
                                  ? Colors.green
                                  : (copilotoIdx != null && i == copilotoIdx
                                      ? Colors.orange
                                      : Colors.blue),
                          child: Icon(
                            (driverIdx != null && i == driverIdx)
                                ? Icons.directions_car
                                : (copilotoIdx != null && i == copilotoIdx
                                    ? Icons.co_present
                                    : Icons.person_outline),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(nome.isEmpty ? '(Sem nome)' : nome),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (telefone.isNotEmpty)
                              Text('Telefone: $telefone'),
                            if (extra.isNotEmpty)
                              ...extra.entries.map(
                                (e) => Text('${e.key}: ${e.value}'),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(papel),
                              backgroundColor:
                                  (driverIdx != null && i == driverIdx)
                                      ? Colors.green[50]
                                      : (copilotoIdx != null && i == copilotoIdx
                                          ? Colors.orange[50]
                                          : Colors.blue[50]),
                              labelStyle: TextStyle(
                                color:
                                    (driverIdx != null && i == driverIdx)
                                        ? Colors.green[800]
                                        : (copilotoIdx != null && i == copilotoIdx
                                            ? Colors.orange[800]
                                            : Colors.blue[800]),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              tooltip: 'Editar',
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showPassengerDialog(initial: p, index: i),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDadosPessoaisTab() {
    return Form(
      key: _personalFormKey,
      autovalidateMode:
          _tabController.index == 0
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
      child: ListView(
        controller: _personalScroll,
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          _buildStatusCard(),
          const SizedBox(height: 16),

          // Informações Pessoais
          _buildSectionCard(
            title: 'Informações Pessoais',
            icon: Icons.person,
            children: [
              KeyedSubtree(
                key: _nomeKey,
                child: _buildTextFormField(
                  controller: nomeController,
                  label: 'Nome Completo',
                  icon: Icons.person_outline,
                  validator: (value) => _validateRequired(value, 'Nome'),
                ),
              ),
              const SizedBox(height: 16),
              KeyedSubtree(
                key: _emailKey,
                child: _buildTextFormField(
                  controller: emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator:
                      (_) => null, // campo desativado não bloqueia validação
                  enabled: false, // Email não deve ser editável
                ),
              ),
              const SizedBox(height: 16),
              KeyedSubtree(
                key: _telKey,
                child: _buildTextFormField(
                  controller: telefoneController,
                  label: 'Telefone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                ),
              ),
              const SizedBox(height: 16),
              KeyedSubtree(
                key: _emergKey,
                child: _buildTextFormField(
                  controller: emergenciaController,
                  label: 'Contacto de Emergência',
                  icon: Icons.emergency_outlined,
                  keyboardType: TextInputType.phone,
                  validator:
                      (value) =>
                          _validateRequired(value, 'Contacto de emergência'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Configurações do Evento
          _buildSectionCard(
            title: 'Configurações do Evento',
            icon: Icons.settings,
            children: [
              KeyedSubtree(
                key: _tshirtKey,
                child: DropdownButtonFormField<String>(
                  initialValue:
                      tamanhosTshirt.contains(tshirtController.text)
                          ? tshirtController.text
                          : null,
                  decoration: InputDecoration(
                    labelText: 'Tamanho da T-shirt',
                    prefixIcon: const Icon(Icons.checkroom_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items:
                      tamanhosTshirt
                          .map(
                            (size) => DropdownMenuItem(
                              value: size,
                              child: Text(size),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (value) =>
                          setState(() => tshirtController.text = value ?? ''),
                  validator:
                      (value) => _validateRequired(value, 'Tamanho da T-shirt'),
                ),
              ),
              const SizedBox(height: 16),

              KeyedSubtree(
                key: _equipaKey,
                child: DropdownButtonFormField<String>(
                  initialValue:
                      equipas.containsKey(equipaSelecionada)
                          ? equipaSelecionada
                          : null,
                  decoration: InputDecoration(
                    labelText: 'Equipa',
                    prefixIcon: const Icon(Icons.group_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items:
                      equipas.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => equipaSelecionada = val),
                  validator:
                      (value) => value == null ? 'Selecione uma equipa' : null,
                ),
              ),
              const SizedBox(height: 16),

              KeyedSubtree(
                key: _veiculoKey,
                child: DropdownButtonFormField<String>(
                  initialValue:
                      veiculos.containsKey(veiculoSelecionado)
                          ? veiculoSelecionado
                          : null,
                  decoration: InputDecoration(
                    labelText: 'Veículo',
                    prefixIcon: const Icon(Icons.directions_car_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items:
                      veiculos.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => veiculoSelecionado = val),
                  validator:
                      (value) => value == null ? 'Selecione um veículo' : null,
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: InputDecoration(
                  labelText: 'Função (Role)',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items:
                    roles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Row(
                              children: [
                                Icon(
                                  r == 'admin'
                                      ? Icons.admin_panel_settings
                                      : r == 'staff'
                                      ? Icons.support_agent
                                      : Icons.person,
                                  size: 20,
                                  color:
                                      r == 'admin'
                                          ? Colors.red
                                          : r == 'staff'
                                          ? Colors.orange
                                          : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(r.toUpperCase()),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (val) => setState(() => role = val),
              ),
              const SizedBox(height: 16),

              // Switch de status ativo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAtivo ? Icons.check_circle : Icons.cancel,
                      color: isAtivo ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status do Participante',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            isAtivo ? 'Ativo no evento' : 'Inativo',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isAtivo,
                      onChanged: (val) => setState(() => isAtivo = val),
                      activeThumbColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Informações de Auditoria
          if (createAt != null || ultimoLogin != null)
            _buildSectionCard(
              title: 'Informações de Auditoria',
              icon: Icons.info_outline,
              children: [
                if (createAt != null) ...[
                  _buildInfoRow(
                    'Data de Criação',
                    DateFormat('dd/MM/yyyy HH:mm').format(createAt!),
                    Icons.calendar_today,
                  ),
                  const SizedBox(height: 12),
                ],
                if (ultimoLogin != null)
                  _buildInfoRow(
                    'Último Login',
                    DateFormat('dd/MM/yyyy HH:mm').format(ultimoLogin!),
                    Icons.login,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPagamentoTab() {
    final price =
        double.tryParse(
          priceController.text.trim().replaceAll(' ', '').replaceAll(',', '.'),
        ) ??
        0.0;

    return Form(
      key: _paymentFormKey,
      autovalidateMode:
          _tabController.index == 2
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
      child: ListView(
        controller: _paymentScroll,
        padding: const EdgeInsets.all(16),
        children: [
          // Card de resumo de pagamento
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors:
                      isPago
                          ? [Colors.green, Colors.green[700]!]
                          : [Colors.orange, Colors.orange[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    isPago ? Icons.check_circle : Icons.pending,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPago ? 'PAGAMENTO CONFIRMADO' : 'PAGAMENTO PENDENTE',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormatter.format(price),
                    style: const TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Seção de detalhes de pagamento
          _buildSectionCard(
            title: 'Detalhes do Pagamento',
            icon: Icons.payment,
            children: [
              KeyedSubtree(
                key: _priceKey,
                child: TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validatePrice,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Valor do Pagamento (CVE)',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Checkbox de confirmação de pagamento
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isPago ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPago ? Colors.green : Colors.orange,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user,
                          color: isPago ? Colors.green : Colors.orange,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Confirmação de Pagamento',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: isPago,
                      onChanged: (val) => setState(() => isPago = val ?? false),
                      title: const Text(
                        'Confirmar que o pagamento foi recebido',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        isPago
                            ? '✓ Pagamento confirmado e registrado'
                            : 'Marque esta opção após confirmar o recebimento',
                        style: TextStyle(
                          color:
                              isPago ? Colors.green[700] : Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                      activeColor: Colors.green,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Alerta informativo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Certifique-se de confirmar o pagamento apenas após a verificação do valor recebido.',
                        style: TextStyle(color: Colors.blue[900], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Histórico de transações (simulado)
          _buildSectionCard(
            title: 'Histórico de Transações',
            icon: Icons.history,
            children: [
              if (isPago) ...[
                _buildTransactionItem(
                  'Pagamento Recebido',
                  price,
                  DateTime.now(),
                  true,
                ),
              ] else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nenhuma transação registrada',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPontuacoesTab() {
    return FutureBuilder<QuerySnapshot>(
      future: _getPontuacoes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Carregando pontuações...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhuma pontuação registrada',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'As pontuações aparecerão aqui após a participação no evento',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final total = docs.fold<int>(0, (acumulado, doc) {
          final data = doc.data() as Map<String, dynamic>;
          final pontos = data['pontuacaoTotal'] ?? 0;
          return acumulado + (pontos as num).toInt();
        });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTotalScoreCard(total),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Detalhes por Checkpoint',
              icon: Icons.list_alt,
              children: docs.map((doc) => _buildCheckpointCard(doc)).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isAtivo ? Icons.check_circle : Icons.cancel,
                color: isAtivo ? Colors.green : Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nomeController.text.isNotEmpty
                        ? nomeController.text
                        : 'Participante',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatusBadge(
                        isAtivo ? 'ATIVO' : 'INATIVO',
                        isAtivo ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(
                        isPago ? 'PAGO' : 'PENDENTE',
                        isPago ? Colors.blue : Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    String description,
    double amount,
    DateTime date,
    bool isSuccess,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.close,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            currencyFormatter.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isSuccess ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalScoreCard(int total) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, size: 48, color: Colors.white),
            const SizedBox(height: 8),
            const Text(
              'Pontuação Total',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$total pontos',
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckpointCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final pontuacaoTotal = data['pontuacaoTotal'] ?? 0;
    final pontuacaoPergunta = data['pontuacaoPergunta'] ?? 0;
    final pontuacaoJogo = data['pontuacaoJogo'] ?? 0;
    final respostaCorreta = data['respostaCorreta'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Checkpoint: ${doc.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$pontuacaoTotal pontos totais',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: pontuacaoTotal > 0 ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pontuacaoTotal pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildScoreItem(
                    'Pergunta',
                    pontuacaoPergunta,
                    respostaCorreta ? Icons.check_circle : Icons.cancel,
                    respostaCorreta ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildScoreItem(
                    'Jogo',
                    pontuacaoJogo,
                    Icons.sports_esports,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, int score, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$score pts',
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[200],
      ),
    );
  }

  Future<QuerySnapshot> _getPontuacoes() async {
    try {
      final eventosSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('events')
              .limit(1)
              .get();

      if (eventosSnapshot.docs.isEmpty) {
        return QuerySnapshotMock();
      }

      final eventoId = eventosSnapshot.docs.first.id;
      return await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('events')
          .doc(eventoId)
          .collection('pontuacoes')
          .get();
    } catch (e) {
      throw Exception('Erro ao carregar pontuações: $e');
    }
  }
}

class QuerySnapshotMock implements QuerySnapshot {
  @override
  List<QueryDocumentSnapshot<Object?>> get docs =>
      <QueryDocumentSnapshot<Object?>>[];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
