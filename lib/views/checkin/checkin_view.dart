// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import '../../widgets/shared/nav_bottom.dart';
import '../../theme/app_colors.dart';
import '../checkin/responder_pergunta_view.dart';

class CheckinView extends StatefulWidget {
  const CheckinView({super.key});

  @override
  State<CheckinView> createState() => _CheckinViewState();
}

class _CheckinViewState extends State<CheckinView> {
  final MobileScannerController _controller = MobileScannerController();
  bool isScanned = false;
  String? resultMessage;
  bool isProcessing = false;

  @override
  void reassemble() {
    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leitura de QR Code'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                child: MobileScanner(
                  controller: _controller,
                  onDetect: (barcode) async {
                    if (isScanned) return;

                    final code = barcode.barcodes.first.rawValue ?? '';
                    String posto = '';
                    String tipo = '';

                    try {
                      final data = jsonDecode(code);
                      posto = data['checkpoint_id'];
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QR inválido'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    final uid = FirebaseAuth.instance.currentUser?.uid;

                    if (uid == null) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Utilizador não autenticado'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final userDoc =
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .get();
                    if (!mounted) return;
                    final veiculoId = userDoc.data()?['veiculoId'];

                    if (veiculoId == null) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veículo não atribuído ao utilizador'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final registrosSnapshot =
                        await FirebaseFirestore.instance
                            .collection('veiculos')
                            .doc(veiculoId)
                            .collection('checkpoints')
                            .doc(posto)
                            .collection('registros')
                            .get();

                    final temEntrada = registrosSnapshot.docs.any(
                      (doc) => doc['tipo'] == 'entrada',
                    );
                    final temSaida = registrosSnapshot.docs.any(
                      (doc) => doc['tipo'] == 'saida',
                    );

                    if (temEntrada && temSaida) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Este posto já foi concluído. Não pode registar novamente.',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    tipo = !temEntrada ? 'entrada' : 'saida';

                    final now = DateTime.now().toUtc().toIso8601String();

                    final registroRef = FirebaseFirestore.instance
                        .collection('veiculos')
                        .doc(veiculoId)
                        .collection('checkpoints')
                        .doc(posto)
                        .collection('registros');

                    try {
                      await registroRef.add({
                        'tipo': tipo,
                        'timestamp': now,
                        'posto': posto,
                      });
                      if (!mounted) return;

                      await FirebaseFirestore.instance
                          .collection('veiculos')
                          .doc(veiculoId)
                          .set({
                            'checkpoints': {
                              posto: {tipo: now, 'ultima_leitura': now},
                            },
                          }, SetOptions(merge: true));
                      if (!mounted) return;

                      const eventId = 'shell_2025';

                      final eventoDocRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('eventos')
                          .doc(eventId);

                      await eventoDocRef.set({
                        'editionId': eventId,
                        'grupo': 'A',
                        'checkpointsVisitados': [],
                        'pontuacaoTotal': 0,
                        'tempoTotal': 0,
                        'classificacao': 0,
                      }, SetOptions(merge: true));
                      if (!mounted) return;

                      final pontuacaoRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('eventos')
                          .doc(eventId)
                          .collection('pontuacoes')
                          .doc(posto);
                      late DocumentSnapshot<Map<String, dynamic>>
                      pontuacaoSnapshot;
                      pontuacaoSnapshot = await pontuacaoRef.get();

                      // Verifica se o usuário tem algum checkpoint anterior incompleto (entrada sem saída)
                      final userPontuacoesSnapshot =
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('eventos')
                              .doc(eventId)
                              .collection('pontuacoes')
                              .get();

                      final temCheckpointIncompleto = userPontuacoesSnapshot
                          .docs
                          .any((doc) {
                            final data = doc.data();
                            return data['timestampEntrada'] != null &&
                                data['timestampSaida'] == null &&
                                doc.id != posto;
                          });

                      if (tipo == 'entrada' && temCheckpointIncompleto) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ainda não saiu do último posto visitado.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (pontuacaoSnapshot.exists) {
                        final existingData = pontuacaoSnapshot.data();
                        if (tipo == 'entrada' &&
                            existingData?['timestampEntrada'] != null) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Entrada já registrada neste posto.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        if (tipo == 'saida' &&
                            existingData?['timestampSaida'] != null) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saída já registrada neste posto.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                      }

                      if (!pontuacaoSnapshot.exists) {
                        if (tipo == 'saida') {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Não pode registrar saída sem entrada neste posto.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        await pontuacaoRef.set({
                          'checkpointId': posto,
                          'respostaCorreta': false,
                          'pontuacaoJogo': 0,
                          'pontuacaoTotal': 0,
                          'timestampEntrada': now,
                          'timestampSaida': null,
                          'perguntaRespondida':
                              false, // Adiciona flag para controlar se já respondeu
                        }, SetOptions(merge: true));
                        if (!mounted) return;
                      } else {
                        await pontuacaoRef.set({
                          'checkpointId': posto,
                          if (tipo == 'entrada') 'timestampEntrada': now,
                          if (tipo == 'saida') 'timestampSaida': now,
                        }, SetOptions(merge: true));
                        if (!mounted) return;
                      }

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .update({
                            'checkpointsVisitados': FieldValue.arrayUnion([
                              posto,
                            ]),
                          });
                      if (!mounted) return;

                      // Marca como escaneado apenas após todas as validações e registros serem bem-sucedidos
                      isScanned = true;

                      setState(
                        () =>
                            resultMessage =
                                'Check-$tipo registrado para $posto',
                      );
                      SystemSound.play(SystemSoundType.click);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Check-$tipo registrado com sucesso para $posto',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Erro ao registrar o checkpoint'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }

                    await Future.delayed(const Duration(seconds: 3));
                    if (!mounted) return;

                    _controller.stop();

                    debugPrint('Tipo: $tipo | Posto: $posto');

                    // Navegar para a tela de pergunta apenas se for entrada e ainda não respondeu
                    if (tipo.trim().toLowerCase() == 'entrada') {
                      // Verifica novamente os dados após o registro
                      final existingData =
                          (await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser?.uid)
                                  .collection('eventos')
                                  .doc('shell_2025')
                                  .collection('pontuacoes')
                                  .doc(posto)
                                  .get())
                              .data();

                      // Navega se ainda não respondeu a pergunta
                      if (existingData?['perguntaRespondida'] != true) {
                        if (!mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    ResponderPerguntaView(checkpointId: posto),
                          ),
                        );
                      }
                    }
                    // Substituir print por debugPrint para QR detectado
                    debugPrint('QR Code detected: $code');
                  },
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
