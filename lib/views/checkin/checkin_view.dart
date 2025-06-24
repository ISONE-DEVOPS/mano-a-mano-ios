// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  final MobileScannerController _controller = MobileScannerController();
  final AuthService _authService = AuthService.to;

  bool isScanned = false;
  String? resultMessage;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Verificar se pode usar scanner
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
          // Botão de info do usuário
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
                        'Equipa: ${_authService.userData['equipaId'] ?? 'N/A'}',
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
                    MobileScanner(
                      controller: _controller,
                      onDetect: (barcode) => _handleQRScan(barcode),
                    ),

                    // Overlay de loading se estiver processando
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

  Future<void> _handleQRScan(BarcodeCapture barcode) async {
    if (isScanned || isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    final code = barcode.barcodes.first.rawValue ?? '';

    try {
      // Pausar scanner
      await _controller.stop();

      // Validar formato do QR
      Map<String, dynamic> qrData = _parseQRCode(code);
      if (qrData.isEmpty) {
        _showError('QR Code inválido');
        return;
      }

      String checkpointId = qrData['checkpoint_id'];
      // Novo bloco para tratar tipo com fallback seguro e print de debug
      String tipo = '';
      if (qrData.containsKey('type')) {
        tipo = qrData['type'].toString().toLowerCase();
        if (tipo != 'entrada' && tipo != 'saida') {
          tipo = 'entrada'; // fallback seguro
        }
      } else {
        tipo = 'entrada'; // fallback se não existir
      }
      print('>>> QR lido: checkpoint=${qrData['checkpoint_id']}, tipo=$tipo');

      // Verificar se usuário está autenticado
      if (!_authService.isLoggedIn) {
        _showError('Usuário não autenticado');
        return;
      }

      // Verificar se tem veículo atribuído
      if (_authService.userData['veiculoId'] == null) {
        _showError('Veículo não atribuído ao usuário');
        return;
      }

      // Verificar estado atual do checkpoint
      await _processCheckpoint(checkpointId, tipo);
    } catch (e) {
      _showError('Erro ao processar QR Code: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Map<String, dynamic> _parseQRCode(String code) {
    try {
      return jsonDecode(code);
    } catch (e) {
      // Se não for JSON, tentar formato simples
      if (code.contains('-')) {
        List<String> parts = code.split('-');
        if (parts.length >= 2) {
          return {
            'checkpoint_id': parts[0],
            'type': parts[1], // entrada ou saida
          };
        }
      }
      return {};
    }
  }

  Future<void> _processCheckpoint(String checkpointId, String tipo) async {
    try {
      final uid = _authService.currentUser!.uid;
      final veiculoId = _authService.userData['veiculoId'];

      // Verificar registros existentes
      final registrosSnapshot =
          await FirebaseFirestore.instance
              .collection('veiculos')
              .doc(veiculoId)
              .collection('checkpoints')
              .doc(checkpointId)
              .collection('registros')
              .get();

      final temEntrada = registrosSnapshot.docs.any(
        (doc) => doc['tipo'] == 'entrada',
      );
      final temSaida = registrosSnapshot.docs.any(
        (doc) => doc['tipo'] == 'saida',
      );

      // NOVO bloco de verificação do tipo
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

        bool hasIncompleteCheckpoint = await _hasIncompleteCheckpoint(
          uid,
          checkpointId,
        );
        if (hasIncompleteCheckpoint) {
          _showError('Ainda não saíste do último posto visitado.');
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

        bool canCheckOut = await _authService.canCheckOut(checkpointId);
        if (!canCheckOut) {
          _showError('Complete todas as atividades antes do check-out!');
          return;
        }
      }

      // Registrar checkpoint
      await _registerCheckpoint(uid, veiculoId, checkpointId, tipo);

      // Marcar como escaneado
      isScanned = true;

      setState(() {
        resultMessage = 'Check-$tipo registrado para $checkpointId';
      });

      SystemSound.play(SystemSoundType.click);

      _showSuccessMessage(
        'Check-$tipo registrado com sucesso para $checkpointId',
      );

      // Aguardar e navegar
      await Future.delayed(const Duration(seconds: 2));

      if (tipo == 'entrada') {
        _navigateToQuestion(checkpointId);
      } else {
        _navigateToNextHint(checkpointId);
      }
    } catch (e) {
      _showError('Erro ao registrar checkpoint: $e');
    }
  }

  Future<bool> _hasIncompleteCheckpoint(
    String uid,
    String currentCheckpointId,
  ) async {
    final userPontuacoesSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('eventos')
            .doc('shell_2025')
            .collection('pontuacoes')
            .get();

    return userPontuacoesSnapshot.docs.any((doc) {
      final data = doc.data();
      return data['timestampEntrada'] != null &&
          data['timestampSaida'] == null &&
          doc.id != currentCheckpointId;
    });
  }

  Future<void> _registerCheckpoint(
    String uid,
    String veiculoId,
    String checkpointId,
    String tipo,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();

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
    });

    // Atualizar veículo
    await FirebaseFirestore.instance.collection('veiculos').doc(veiculoId).set({
      'checkpoints': {
        checkpointId: {tipo: now, 'ultima_leitura': now},
      },
    }, SetOptions(merge: true));

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
        'pontuacaoJogo': 0,
        'pontuacaoTotal': 0,
        'timestampEntrada': now,
        'timestampSaida': null,
        'perguntaRespondida': false,
      }, SetOptions(merge: true));
    } else {
      await pontuacaoRef.update({'timestampSaida': now});
    }

    // Atualizar checkpoints visitados
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'checkpointsVisitados': FieldValue.arrayUnion([checkpointId]),
    });
  }

  void _navigateToQuestion(String checkpointId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResponderPerguntaView(checkpointId: checkpointId),
      ),
    );
  }

  void _navigateToNextHint(String checkpointId) {
    // Aqui você pode carregar a próxima pista (concha) do Firestore
    // e mostrar no HintPopup
    _loadAndShowNextHint(checkpointId);
  }

  Future<void> _loadAndShowNextHint(String checkpointId) async {
    try {
      // Carregar próxima pista baseada no grupo da equipa
      String grupo = _authService.userData['grupo'] ?? 'A';

      // Buscar pista no Firestore
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

      showDialog(
        context: context,
        builder: (context) => HintPopup(clueText: pistaTexto),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (context) =>
                HintPopup(clueText: 'Parabéns! Continue para o próximo posto.'),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );

    // Retomar scanner após erro
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.start();
        setState(() {
          isProcessing = false;
        });
      }
    });
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
