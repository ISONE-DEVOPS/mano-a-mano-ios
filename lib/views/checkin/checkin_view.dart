import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import '../../widgets/shared/nav_bottom.dart';

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
        backgroundColor: const Color(0xFF0E0E2C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Escaneie o QR Code do posto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      setState(() => resultMessage = 'QR inválido');
                      return;
                    }

                    final posto = parts[0];
                    final tipo = parts[1]; // 'entrada' ou 'saida'
                    final uid = FirebaseAuth.instance.currentUser?.uid;

                    if (uid == null) {
                      setState(() => resultMessage = 'Usuário não autenticado');
                      return;
                    }

                    final now = DateTime.now().toUtc().toIso8601String();
                    final registroRef = FirebaseFirestore.instance
                        .collection('cars')
                        .doc(uid)
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
                          .collection('cars')
                          .doc(uid)
                          .update({
                            'checkpoints.$posto.$tipo': now,
                            'checkpoints.$posto.ultima_leitura': now,
                          });

                      setState(
                        () =>
                            resultMessage =
                                'Check-$tipo registrado para $posto',
                      );
                      SystemSound.play(SystemSoundType.click);

                      if (context.mounted) {
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
                      setState(
                        () => resultMessage = 'Erro ao registrar o checkpoint',
                      );
                    }

                    await Future.delayed(const Duration(seconds: 3));
                    if (!mounted) return;

                    _controller.stop();

                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/home');
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
                        color: Colors.grey.shade100,
                        elevation: 2,
                        margin: EdgeInsets.zero,
                        child: Center(
                          child: Text(
                            resultMessage!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                      : const Center(
                        child: Text(
                          'Aponte a câmera para o QR do posto',
                          textAlign: TextAlign.center,
                        ),
                      ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
