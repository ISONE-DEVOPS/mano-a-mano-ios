// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../widgets/shared/nav_bottom.dart';
import '../../theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _checkPermissions();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leitura de QR Code'),
        backgroundColor: AppColors.primary,
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  _authService.userData['nome'] ?? 'Usuário',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Info da equipa
            Obx(
              () => Card(
                color: AppColors.background,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.group, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Equipa: ${_authService.userData['equipaNome'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ToggleButtons para Entrada/Saída
            Column(
              children: [
                ToggleButtons(
                  isSelected: _toggleSelections,
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: AppColors.primary,
                  color: AppColors.primary,
                  borderColor: AppColors.primary,
                  selectedBorderColor: AppColors.primary,
                  onPressed: (int index) {
                    setState(() {
                      for (int i = 0; i < _toggleSelections.length; i++) {
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
                      child: Text('Entrada', style: TextStyle(fontSize: 16)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 8.0,
                      ),
                      child: Text('Saída', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),

            const Text(
              'Escaneie o QR Code do posto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),
                    if (isProcessing)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'Processando QR Code...',
                                style: TextStyle(
                                  color: Colors.white,
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
                        color: AppColors.background,
                        elevation: 2,
                        margin: EdgeInsets.zero,
                        child: Center(
                          child: Text(
                            resultMessage!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                      : const Center(
                        child: Text(
                          'Aponte a câmera para o QR do posto',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
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

    setState(() {
      isProcessing = true;
    });

    // Suporta Barcode (QRView)
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

      // Buscar dados do checkpoint
      final checkpointData = await _getCheckpointData(qrCode);
      if (checkpointData == null) {
        _showError('QR Code inválido ou checkpoint não encontrado');
        return;
      }

      log(
        '>>> Checkpoint encontrado: ${checkpointData['checkpointId']}, Tipo selecionado: $_selectedTipo',
      );

      await _processCheckpoint(checkpointData['checkpointId']!, _selectedTipo);
    } catch (e) {
      log('>>> Erro no handleQRScan: $e');
      _showError('Erro ao processar QR Code: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
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
      // Extrai checkpointId diretamente do QR code, seja ele puro, JSON ou com hífen.
      // 1. Se for JSON, extrai checkpoint_id.
      try {
        final jsonData = jsonDecode(qrCode);
        return {'checkpointId': jsonData['checkpoint_id'] ?? ''};
      } catch (_) {}

      // 2. Se contiver hífen, extrai antes do hífen.
      if (qrCode.contains('-')) {
        List<String> parts = qrCode.split('-');
        if (parts.isNotEmpty) {
          return {'checkpointId': parts[0]};
        }
      }

      // 3. Caso contrário, tenta buscar pelo QR code puro no Firestore.
      log('>>> Buscando no Firestore: $qrCode');

      final checkpointDoc =
          await FirebaseFirestore.instance
              .collection('editions')
              .doc('shell_2025')
              .collection('events')
              .doc('shell_km_02')
              .collection('checkpoints')
              .doc(qrCode)
              .get();

      if (!checkpointDoc.exists) {
        log('>>> Checkpoint não encontrado no Firestore');
        return null;
      }

      final data = checkpointDoc.data()!;
      log('>>> Dados do checkpoint encontrado: $data');

      String checkpointId = data['name'] ?? qrCode;
      return {'checkpointId': checkpointId};
    } catch (e) {
      log('>>> Erro ao buscar checkpoint: $e');
      return null;
    }
  }

  Future<void> _processCheckpoint(String checkpointId, String tipo) async {
    try {
      final uid = _authService.currentUser!.uid;
      final veiculoId = _authService.userData['veiculoId'];

      log('>>> Processando: $checkpointId ($tipo) - User: $uid');

      // Verificar estado atual usando a coleção de pontuações do usuário
      final pontuacaoDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('eventos')
              .doc('shell_km_02')
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
        '>>> Estado atual - Entrada: $temEntrada, Saída: $temSaida, Pergunta: $perguntaRespondida',
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
          _showError(
            'Este posto já foi concluído. Não pode registar novamente.',
          );
          return;
        }
        // (Removido: Não bloqueia mais se houver outro checkpoint incompleto)
      } else if (tipo == 'saida') {
        if (!temEntrada) {
          _showError('Precisas fazer check-in neste posto antes de sair.');
          return;
        }

        if (temSaida) {
          _showError('Já fizeste check-out neste posto.');
          return;
        }

        // Verificar se a pergunta foi respondida
        if (!perguntaRespondida) {
          _showError('Deves responder à pergunta antes de fazer check-out.');
          return;
        }

        // Verificar se pode fazer checkout (opcional - comentado por enquanto)
        // bool canCheckOut = await _canCheckOut(checkpointId);
        // if (!canCheckOut) {
        //   _showError('Complete todas as atividades antes do check-out!');
        //   return;
        // }
      }

      // Registrar checkpoint
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
      final registroRef = FirebaseFirestore.instance
          .collection('veiculos')
          .doc(veiculoId)
          .collection('checkpoints')
          .doc(checkpointId)
          .collection('registros');

      await registroRef.add({
        'tipo': tipo,
        'timestamp': now,
        'posto': checkpointId,
        'userId': uid,
      });

      // Atualizar veículo
      await FirebaseFirestore.instance
          .collection('veiculos')
          .doc(veiculoId)
          .set({
            'checkpoints': {
              checkpointId: {tipo: now, 'ultima_leitura': now},
            },
          }, SetOptions(merge: true));

      // Atualizar updatedAt no documento do veículo
      await FirebaseFirestore.instance
          .collection('veiculos')
          .doc(veiculoId)
          .update({'updatedAt': FieldValue.serverTimestamp()});

      // Criar/atualizar evento do usuário
      const eventId = 'shell_2025';
      final eventoDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('eventos')
          .doc(eventId);

      await eventoDocRef.set({
        'editionId': eventId,
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
        // Opcional: atualizar pontuacao_total no documento do veículo (caso tenha pontuado aqui)
        final data = await pontuacaoRef.get();
        if (data.exists) {
          final pontos = (data.data()?['pontuacaoPergunta'] ?? 0) as int;
          await FirebaseFirestore.instance
              .collection('veiculos')
              .doc(veiculoId)
              .update({
                'pontuacao_total': FieldValue.increment(pontos),
                'updatedAt': FieldValue.serverTimestamp(),
              });
        }
      } else {
        await pontuacaoRef.update({'timestampSaida': now});
        await _atualizarTempoTotal(uid);
      }

      // Atualizar checkpoints visitados
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
              .doc('shell_km_02')
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
          .doc('shell_2025')
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
              .doc('shell_km_02')
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
          .doc('shell_2025')
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
              .collectionGroup('shell_2025')
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
