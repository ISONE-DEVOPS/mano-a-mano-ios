import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanAndScoreView extends StatefulWidget {
  const ScanAndScoreView({super.key});

  @override
  State<ScanAndScoreView> createState() => _ScanAndScoreViewState();
}

class _ScanAndScoreViewState extends State<ScanAndScoreView> {
  String scannedData = '';
  String selectedGame = '';
  final TextEditingController _pointsController = TextEditingController();
  bool isScanned = false;

  final List<String> jogos = [
    'Prova do Lubrificante',
    'Torre de Bashell',
    'A-Seta no Balão',
    'Remate à Baliza',
    'Troca de Pneu Imaginária',
    'Transporta a Botija',
    'Caça ao Tesouro',
    'Corrida de Pneus',
    'Tiro às Garrafas',
  ];

  void _submitScore() async {
    if (scannedData.isEmpty ||
        selectedGame.isEmpty ||
        _pointsController.text.isEmpty) {
      return;
    }

    final parts = scannedData.split('\n');
    final nome = parts
        .firstWhere((e) => e.startsWith('Nome:'), orElse: () => 'Nome:')
        .replaceFirst('Nome: ', '');
    final matricula = parts
        .firstWhere(
          (e) => e.startsWith('Matrícula:'),
          orElse: () => 'Matrícula:',
        )
        .replaceFirst('Matrícula: ', '');
    final email = parts
        .firstWhere((e) => e.startsWith('Email:'), orElse: () => 'Email:')
        .replaceFirst('Email: ', '');
    final telefone = parts
        .firstWhere((e) => e.startsWith('Telefone:'), orElse: () => 'Telefone:')
        .replaceFirst('Telefone: ', '');

    await FirebaseFirestore.instance.collection('scores').add({
      'nome': nome,
      'matricula': matricula,
      'email': email,
      'telefone': telefone,
      'jogo': selectedGame,
      'pontos': int.tryParse(_pointsController.text) ?? 0,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pontuação registrada com sucesso.')),
    );
    setState(() {
      scannedData = '';
      selectedGame = '';
      _pointsController.clear();
      isScanned = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registo de Pontuação')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!isScanned)
              SizedBox(
                height: 300,
                child: MobileScanner(
                  onDetect: (capture) {
                    final barcode = capture.barcodes.first;
                    setState(() {
                      scannedData = barcode.rawValue ?? '';
                      isScanned = true;
                    });
                  },
                ),
              ),
            if (isScanned) ...[
              Text('Dados escaneados:\n$scannedData'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedGame.isEmpty ? null : selectedGame,
                hint: const Text('Selecione o jogo'),
                items:
                    jogos
                        .map(
                          (jogo) =>
                              DropdownMenuItem(value: jogo, child: Text(jogo)),
                        )
                        .toList(),
                onChanged:
                    (value) => setState(() => selectedGame = value ?? ''),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Pontos'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitScore,
                child: const Text('Salvar Pontuação'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
