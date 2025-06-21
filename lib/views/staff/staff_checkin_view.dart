import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mano_mano_dashboard/widgets/shared/staff_app_bar.dart';

class StaffCheckinView extends StatefulWidget {
  const StaffCheckinView({super.key});

  @override
  State<StaffCheckinView> createState() => _StaffCheckinViewState();
}

class _StaffCheckinViewState extends State<StaffCheckinView> {
  final MobileScannerController controller = MobileScannerController();
  String? scannedCode;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _showPontuacaoDialog(String? code) {
    if (code == null) return;

    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController pontosController = TextEditingController();
        return AlertDialog(
          title: Text('Registrar Pontuação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID do Participante: $code'),
              const SizedBox(height: 16),
              TextField(
                controller: pontosController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pontuação do Jogo',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.start();
                setState(() {
                  scannedCode = null;
                });
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pontuacao = int.tryParse(pontosController.text) ?? 0;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(code)
                    .collection('events')
                    .doc('shell_km_02')
                    .collection('pontuacoes')
                    .doc('manual_checkpoint')
                    .set({
                      'checkpointId': 'manual_checkpoint',
                      'pontuacaoJogo': pontuacao,
                      'pontuacaoTotal': pontuacao,
                      'timestampEntrada': FieldValue.serverTimestamp(),
                      'timestampSaida': FieldValue.serverTimestamp(),
                    });

                // Atualizar pontuação total da equipa
                final userDoc =
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(code)
                        .get();
                final equipaId = userDoc.data()?['equipaId'];
                if (equipaId != null) {
                  final equipaRef = FirebaseFirestore.instance
                      .collection('equipas')
                      .doc(equipaId);
                  final equipaDoc = await equipaRef.get();
                  final totalAtual =
                      (equipaDoc.data()?['pontuacaoTotal'] ?? 0) as int;
                  await equipaRef.update({
                    'pontuacaoTotal': totalAtual + pontuacao,
                  });
                }

                if (!mounted) return;
                Navigator.of(this.context).pop();
                controller.start();
                setState(() {
                  scannedCode = null;
                });
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StaffAppBar(title: 'Check-in e Pontuação'),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final code = capture.barcodes.first.rawValue;
                if (code != null && scannedCode == null) {
                  setState(() {
                    scannedCode = code;
                  });
                  controller.stop();
                  _showPontuacaoDialog(code);
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                scannedCode == null
                    ? 'Aponte a câmara para o QR Code'
                    : 'Código Lido: $scannedCode',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
