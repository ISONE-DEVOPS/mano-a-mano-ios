import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GenerateQrView extends StatefulWidget {
  const GenerateQrView({super.key});

  @override
  State<GenerateQrView> createState() => _GenerateQrViewState();
}

class _GenerateQrViewState extends State<GenerateQrView> {
  final _postoController = TextEditingController();
  String _tipo = 'entrada';
  String? _qrData;

  void _generateQR() {
    final posto = _postoController.text.trim();
    if (posto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insira o identificador do posto')),
      );
      return;
    }
    setState(() {
      _qrData = '$posto-$_tipo';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerar QR Code - Checkpoint')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Identificador do Posto'),
            const SizedBox(height: 6),
            TextField(
              controller: _postoController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ex: posto12',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Tipo de Checkpoint'),
            const SizedBox(height: 6),
            DropdownButton<String>(
              value: _tipo,
              items: const [
                DropdownMenuItem(value: 'entrada', child: Text('Entrada')),
                DropdownMenuItem(value: 'saida', child: Text('Saída')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _tipo = value);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _generateQR,
              child: const Text('Gerar QR Code'),
            ),
            const SizedBox(height: 24),
            if (_qrData != null)
              Center(
                child: QrImageView(
                  data: _qrData!,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
