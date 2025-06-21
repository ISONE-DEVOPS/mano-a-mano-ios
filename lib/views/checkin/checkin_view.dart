// ignore_for_file: use_build_context_synchronously

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
                    isScanned = true;

                    final code = barcode.barcodes.first.rawValue ?? '';
                    final parts = code.split('-'); // ex: posto12-entrada
                    if (parts.length != 2) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QR inválido'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final posto = parts[0];
                    final tipo = parts[1]; // 'entrada' ou 'saida'
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

                      await FirebaseFirestore.instance
                          .collection('veiculos')
                          .doc(veiculoId)
                          .set({
                            'checkpoints': {
                              posto: {tipo: now, 'ultima_leitura': now},
                            },
                          }, SetOptions(merge: true));

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

                      final pontuacaoRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('eventos')
                          .doc(eventId)
                          .collection('pontuacoes')
                          .doc(posto);

                      final pontuacaoSnapshot = await pontuacaoRef.get();
                      if (!pontuacaoSnapshot.exists) {
                        await pontuacaoRef.set({
                          'checkpointId': posto,
                          'respostaCorreta': false,
                          'pontuacaoJogo': 0,
                          'pontuacaoTotal': 0,
                          'timestampEntrada': tipo == 'entrada' ? now : null,
                          'timestampSaida': tipo == 'saida' ? now : null,
                        }, SetOptions(merge: true));
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Este checkpoint já foi registrado anteriormente.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        await pontuacaoRef.set({
                          'timestampEntrada': tipo == 'entrada' ? now : null,
                          'timestampSaida': tipo == 'saida' ? now : null,
                        }, SetOptions(merge: true));
                      }

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .update({
                            'checkpointsVisitados': FieldValue.arrayUnion([
                              posto,
                            ]),
                          });

                      setState(
                        () =>
                            resultMessage =
                                'Check-$tipo registrado para $posto',
                      );
                      SystemSound.play(SystemSoundType.click);

                      if (mounted) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Check-$tipo registrado com sucesso para $posto',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
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

                    if (tipo == 'entrada') {
                      if (!mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ResponderPerguntaView(checkpointId: posto),
                        ),
                      );
                    }
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
            Navigator.pushReplacementNamed(
              context,
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
