// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/auth_service.dart';
import '../../widgets/shared/nav_bottom.dart';
import '../checkin/responder_pergunta_view.dart';
import '../checkin/hint_popup.dart';

class CheckinView extends StatefulWidget {
  const CheckinView({super.key});

  @override
  State<CheckinView> createState() => _CheckinViewState();
}

class _CheckinViewState extends State<CheckinView> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  final AuthService _authService = AuthService.to;

  bool isScanned = false;
  String? resultMessage;
  bool isProcessing = false;
  final List<bool> _toggleSelections = [true, false];

  String get _selectedTipo => _toggleSelections[0] ? 'entrada' : 'saida';

  // Configuração do evento
  bool _isSingleMode = false;
  String? _activeEditionId;
  String? _activeEventId;
  bool _isLoadingConfig = true;
  bool _hasActiveEvent = false;
  String? _activeEventName;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadActiveEventConfig();
  }

  Future<void> _checkPermissions() async {
    bool canUse = await _authService.canUseScanner();
    if (!canUse) {
      Get.back();
      Get.snackbar(
        'Acesso Negado',
        'Você não tem permissão para usar o scanner',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Carrega a configuração do evento ativo (edição + evento + modo)
  Future<void> _loadActiveEventConfig() async {
    try {
      setState(() => _isLoadingConfig = true);

      // 1. Buscar edição ativa
      final editionsSnapshot =
          await FirebaseFirestore.instance
              .collection('editions')
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

      if (editionsSnapshot.docs.isEmpty) {
        log('>>> Nenhuma edição ativa encontrada');
        _setDefaultConfig();
        return;
      }

      final editionDoc = editionsSnapshot.docs.first;
      _activeEditionId = editionDoc.id;
      log('>>> Edição ativa: $_activeEditionId');

      // 2. Buscar evento ativo dentro da edição
      final eventsSnapshot =
          await FirebaseFirestore.instance
              .collection('editions')
              .doc(_activeEditionId)
              .collection('events')
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

      if (eventsSnapshot.docs.isEmpty) {
        log('>>> Nenhum evento ativo encontrado na edição');
        _setDefaultConfig();
        return;
      }

      final eventDoc = eventsSnapshot.docs.first;
      _activeEventId = eventDoc.id;
      final eventData = eventDoc.data();
      _activeEventName =
          (eventData['nome'] ?? eventData['name'] ?? _activeEventId) as String?;
      _hasActiveEvent = true;

      // 3. Carregar modo de check-in
      final checkinMode =
          (eventData['checkinMode'] as String? ?? 'entry_exit')
              .toLowerCase()
              .trim();

      setState(() {
        _isSingleMode = checkinMode == 'single';
        _isLoadingConfig = false;
      });

      log('>>> Evento ativo: $_activeEventId');
      log('>>> Modo de check-in: $checkinMode (single: $_isSingleMode)');
    } catch (e) {
      log('>>> Erro ao carregar configuração do evento: $e');
      _setDefaultConfig();
    }
  }

  void _setDefaultConfig() {
    setState(() {
      _activeEditionId = 'shell_2025';
      _activeEventId = 'shell_km_02';
      _isSingleMode = false;
      _isLoadingConfig = false;
    });
    log('>>> Usando configuração padrão');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Leitura de QR Code'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  _authService.userData['nome'] ?? 'Usuário',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoadingConfig
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Carregando configuração...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Info da equipa
                    Obx(
                      () => Card(
                        color: Theme.of(context).colorScheme.surface,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.event,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Evento: ${_activeEventName ?? '-'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.group,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Equipa: ${_authService.userData['equipaNome'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              if (_isSingleMode)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.70),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Modo: Check-in único',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.70),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ToggleButtons para Entrada/Saída (apenas quando NÃO for single)
                    if (!_isSingleMode)
                      Column(
                        children: [
                          ToggleButtons(
                            isSelected: _toggleSelections,
                            borderRadius: BorderRadius.circular(8),
                            selectedColor:
                                Theme.of(context).colorScheme.onPrimary,
                            fillColor: Theme.of(context).colorScheme.primary,
                            color: Theme.of(context).colorScheme.primary,
                            borderColor: Theme.of(context).colorScheme.primary,
                            selectedBorderColor:
                                Theme.of(context).colorScheme.primary,
                            onPressed: (int index) {
                              setState(() {
                                for (
                                  int i = 0;
                                  i < _toggleSelections.length;
                                  i++
                                ) {
                                  _toggleSelections[i] = i == index;
                                }
                              });
                            },
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  'Entrada',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  'Saída',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),

                    Text(
                      _isSingleMode
                          ? 'Escaneie o QR Code do checkpoint'
                          : 'Escaneie o QR Code do posto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      flex: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            kIsWeb
                                ? Container(
                                  alignment: Alignment.center,
                                  color: Theme.of(context).colorScheme.surface,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'Leitura de QR não está disponível na versão Web. Use a app móvel para fazer o check-in.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.80),
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                )
                                : Stack(
                                  children: [
                                    QRView(
                                      key: qrKey,
                                      onQRViewCreated: _onQRViewCreated,
                                    ),
                                    if (isProcessing)
                                      Container(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.54),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              CircularProgressIndicator(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Processando QR Code...',
                                                style: TextStyle(
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Expanded(
                      flex: 1,
                      child:
                          resultMessage != null
                              ? Card(
                                color: Theme.of(context).colorScheme.surface,
                                elevation: 2,
                                margin: EdgeInsets.zero,
                                child: Center(
                                  child: Text(
                                    resultMessage!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.70),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                              : Center(
                                child: Text(
                                  _isSingleMode
                                      ? 'Aponte a câmera para o QR do checkpoint'
                                      : 'Aponte a câmera para o QR do posto',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.70),
                                  ),
                                ),
                              ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index != 2) {
            if (!mounted) return;
            Navigator.of(context).pushReplacementNamed(
              [
                '/home',
                '/my-events',
                '/checkin',
                '/ranking',
                '/profile',
              ][index],
            );
          }
        },
      ),
    );
  }

  Future<void> _handleQRScan(dynamic barcode) async {
    if (isScanned || isProcessing) return;

    // Validar se há evento ativo
    if (!_hasActiveEvent || _activeEventId == null) {
      _showError('Nenhum evento ativo disponível para check-in');
      return;
    }

    setState(() => isProcessing = true);

    String qrCode = '';
    if (barcode is Barcode) {
      qrCode = barcode.code ?? '';
    }
    log('>>> QR Code detectado: $qrCode');

    try {
      await _controller?.pauseCamera();

      if (!_authService.isLoggedIn) {
        _showError('Usuário não autenticado');
        return;
      }

      if (_authService.userData['veiculoId'] == null) {
        _showError('Veículo não atribuído ao usuário');
        return;
      }

      final checkpointData = await _getCheckpointData(qrCode);
      if (checkpointData == null) {
        _showError('QR Code inválido ou checkpoint não encontrado');
        return;
      }

      final tipoSelecionado = _isSingleMode ? 'single' : _selectedTipo;
      log(
        '>>> Checkpoint: ${checkpointData['checkpointId']}, Tipo: $tipoSelecionado',
      );

      await _processCheckpoint(
        checkpointData['checkpointId']!,
        tipoSelecionado,
      );
    } catch (e) {
      log('>>> Erro no handleQRScan: $e');
      _showError('Erro ao processar QR Code: $e');
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    controller.scannedDataStream.listen((barcode) {
      _handleQRScan(barcode);
    });
  }

  Future<Map<String, String>?> _getCheckpointData(String qrCode) async {
    try {
      // 1. Tentar parsear como JSON
      try {
        final jsonData = jsonDecode(qrCode);
        return {'checkpointId': jsonData['checkpoint_id'] ?? ''};
      } catch (_) {}

      // 2. Se contém hífen, extrair parte antes do hífen
      if (qrCode.contains('-')) {
        List<String> parts = qrCode.split('-');
        if (parts.isNotEmpty) {
          return {'checkpointId': parts[0]};
        }
      }

      // 3. Buscar no Firestore na estrutura correta
      if (_activeEditionId != null && _activeEventId != null) {
        final checkpointDoc =
            await FirebaseFirestore.instance
                .collection('editions')
                .doc(_activeEditionId)
                .collection('events')
                .doc(_activeEventId)
                .collection('checkpoints')
                .doc(qrCode)
                .get();

        if (checkpointDoc.exists) {
          final data = checkpointDoc.data()!;
          log('>>> Checkpoint encontrado no Firestore: $data');
          return {'checkpointId': data['name'] ?? qrCode};
        }
      }

      // 4. Usar o QR code diretamente como ID
      log('>>> Usando QR como checkpoint ID');
      return {'checkpointId': qrCode};
    } catch (e) {
      log('>>> Erro ao buscar checkpoint: $e');
      return null;
    }
  }

  Future<void> _processCheckpoint(String checkpointId, String tipo) async {
    // Validação adicional de segurança
    if (!_hasActiveEvent ||
        _activeEventId == null ||
        _activeEditionId == null) {
      _showError('Evento não está ativo. Não é possível fazer check-in.');
      return;
    }

    try {
      final eventPath = '$_activeEditionId/$_activeEventId';
      final uid = _authService.currentUser!.uid;
      final veiculoId = _authService.userData['veiculoId'];

      log('>>> Processando: $checkpointId ($tipo) - Evento: $eventPath');

      if (_isSingleMode) {
        // ===== MODO SINGLE: Check-in único =====
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('eventos')
            .doc(_activeEventId)
            .collection('pontuacoes')
            .doc(checkpointId);

        final existing = await docRef.get();
        if (existing.exists && existing.data()?['validated'] == true) {
          _showError('Este checkpoint já foi validado.');
          return;
        }

        await docRef.set({
          'checkpointId': checkpointId,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'validated': true,
          'mode': 'single',
          'editionId': _activeEditionId,
          'eventId': _activeEventId,
        });

        // Registrar no veículo
        await _registerVehicleCheckpoint(veiculoId, checkpointId, 'single');

        isScanned = true;
        setState(() {
          resultMessage = 'Checkpoint validado: $checkpointId';
        });

        SystemSound.play(SystemSoundType.click);
        _showSuccessMessage('Checkpoint validado com sucesso!');

        await Future.delayed(const Duration(seconds: 2));
        return;
      }

      // ===== MODO ENTRY/EXIT: Check-in duplo =====
      final pontuacaoDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('eventos')
              .doc(_activeEventId)
              .collection('pontuacoes')
              .doc(checkpointId)
              .get();

      bool temEntrada = false;
      bool temSaida = false;
      bool perguntaRespondida = false;

      if (pontuacaoDoc.exists) {
        final data = pontuacaoDoc.data()!;
        temEntrada = data['timestampEntrada'] != null;
        temSaida = data['timestampSaida'] != null;
        perguntaRespondida = data['perguntaRespondida'] ?? false;
      }

      log(
        '>>> Estado: Entrada=$temEntrada, Saída=$temSaida, Pergunta=$perguntaRespondida',
      );

      // Validações
      if (tipo == 'entrada') {
        if (temEntrada && !temSaida) {
          _showError(
            'Já fizeste check-in neste posto. Agora deves fazer check-out.',
          );
          return;
        }
        if (temEntrada && temSaida) {
          _showError('Este posto já foi concluído.');
          return;
        }
      } else if (tipo == 'saida') {
        if (!temEntrada) {
          _showError('Precisas fazer check-in neste posto antes de sair.');
          return;
        }
        if (temSaida) {
          _showError('Já fizeste check-out neste posto.');
          return;
        }
        if (!perguntaRespondida) {
          _showError('Deves responder à pergunta antes de fazer check-out.');
          return;
        }
      }

      await _registerCheckpoint(uid, veiculoId, checkpointId, tipo);

      isScanned = true;
      setState(() {
        resultMessage = 'Check-$tipo registrado para $checkpointId';
      });

      SystemSound.play(SystemSoundType.click);
      _showSuccessMessage('Check-$tipo registrado com sucesso!');

      await Future.delayed(const Duration(seconds: 2));

      if (tipo == 'entrada') {
        _navigateToQuestion(checkpointId);
      } else {
        _navigateToNextHint(checkpointId);
      }
    } catch (e) {
      log('>>> Erro em _processCheckpoint: $e');
      _showError('Erro ao registrar checkpoint: $e');
    }
  }

  Future<void> _registerVehicleCheckpoint(
    String veiculoId,
    String checkpointId,
    String tipo,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await FirebaseFirestore.instance
          .collection('veiculos')
          .doc(veiculoId)
          .set({
            'checkpoints': {
              checkpointId: {tipo: now, 'ultima_leitura': now},
            },
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      log('>>> Erro ao registrar no veículo: $e');
    }
  }

  Future<void> _registerCheckpoint(
    String uid,
    String veiculoId,
    String checkpointId,
    String tipo,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();
    log('>>> Registrando: $checkpointId ($tipo)');

    try {
      // Registrar no veículo
      await _registerVehicleCheckpoint(veiculoId, checkpointId, tipo);

      // Criar/atualizar evento do usuário
      final eventoDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('eventos')
          .doc(_activeEventId);

      await eventoDocRef.set({
        'editionId': _activeEditionId,
        'eventId': _activeEventId,
        'grupo': _authService.userData['grupo'] ?? 'A',
        'checkpointsVisitados': [],
        'pontuacaoTotal': 0,
        'tempoTotal': 0,
        'classificacao': 0,
      }, SetOptions(merge: true));

      // Registrar pontuação
      final pontuacaoRef = eventoDocRef
          .collection('pontuacoes')
          .doc(checkpointId);

      if (tipo == 'entrada') {
        await pontuacaoRef.set({
          'checkpointId': checkpointId,
          'respostaCorreta': false,
          'pontuacaoPergunta': 0,
          'pontuacaoJogo': 0,
          'pontuacaoTotal': 0,
          'timestampEntrada': now,
          'timestampSaida': null,
          'perguntaRespondida': false,
          'jogosPontuados': {},
        }, SetOptions(merge: true));
      } else {
        await pontuacaoRef.update({'timestampSaida': now});
        await _atualizarTempoTotal(uid);
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'checkpointsVisitados': FieldValue.arrayUnion([checkpointId]),
      });

      log('>>> Checkpoint registrado com sucesso!');
      await _atualizarPontuacaoTotal(uid);
      await _atualizarClassificacaoGeral();
    } catch (e) {
      log('>>> Erro ao registrar: $e');
      rethrow;
    }
  }

  Future<void> _atualizarPontuacaoTotal(String uid) async {
    try {
      final pontuacoesSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('eventos')
              .doc(_activeEventId)
              .collection('pontuacoes')
              .get();

      int total = 0;

      for (var doc in pontuacoesSnapshot.docs) {
        final data = doc.data();
        total +=
            ((data['pontuacaoPergunta'] ?? 0) as num).toInt() +
            ((data['pontuacaoJogo'] ?? 0) as num).toInt();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('eventos')
          .doc(_activeEventId)
          .update({'pontuacaoTotal': total});

      log('>>> pontuacaoTotal atualizada: $total');
    } catch (e) {
      log('>>> Erro ao atualizar pontuacaoTotal: $e');
    }
  }

  Future<void> _atualizarTempoTotal(String uid) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('eventos')
              .doc(_activeEventId)
              .collection('pontuacoes')
              .get();

      int totalSegundos = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final entrada =
            (data['timestampEntrada'] != null)
                ? DateTime.tryParse(data['timestampEntrada'])
                : null;
        final saida =
            (data['timestampSaida'] != null)
                ? DateTime.tryParse(data['timestampSaida'])
                : null;

        if (entrada != null && saida != null) {
          totalSegundos += saida.difference(entrada).inSeconds;
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('eventos')
          .doc(_activeEventId)
          .update({'tempoTotal': totalSegundos});

      log('>>> tempoTotal atualizado: $totalSegundos segundos');
    } catch (e) {
      log('>>> Erro ao atualizar tempoTotal: $e');
    }
  }

  Future<void> _atualizarClassificacaoGeral() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collectionGroup(_activeEventId!)
              .orderBy('pontuacaoTotal', descending: true)
              .orderBy('tempoTotal')
              .get();

      int posicao = 1;

      for (var doc in snapshot.docs) {
        await doc.reference.update({'classificacao': posicao});
        posicao++;
      }

      log('>>> classificacoes atualizadas');
    } catch (e) {
      log('>>> Erro ao atualizar classificacao: $e');
    }
  }

  void _navigateToQuestion(String checkpointId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResponderPerguntaView(checkpointId: checkpointId),
      ),
    );
  }

  void _navigateToNextHint(String checkpointId) {
    _loadAndShowNextHint(checkpointId);
  }

  Future<void> _loadAndShowNextHint(String checkpointId) async {
    try {
      String grupo = _authService.userData['grupo'] ?? 'A';

      final conchaSnapshot =
          await FirebaseFirestore.instance
              .collection('conchas')
              .where('checkpointId', isEqualTo: checkpointId)
              .where('grupo', isEqualTo: grupo)
              .limit(1)
              .get();

      String pistaTexto = 'Parabéns! Continue para o próximo posto.';

      if (conchaSnapshot.docs.isNotEmpty) {
        pistaTexto = conchaSnapshot.docs.first.data()['texto'] ?? pistaTexto;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => HintPopup(clueText: pistaTexto),
        );
      }
    } catch (e) {
      log('>>> Erro ao carregar pista: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => HintPopup(
                clueText: 'Parabéns! Continue para o próximo posto.',
              ),
        );
      }
    }
  }

  void _showError(String message) {
    log('>>> ERRO: $message');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }

    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        await _controller?.resumeCamera();
        setState(() {
          isProcessing = false;
          isScanned = false;
        });
      }
    });
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
