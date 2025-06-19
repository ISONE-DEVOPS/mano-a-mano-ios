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

    final parts = scannedData.split(';');
    final Map<String, String> parsed = {};
    for (var part in parts) {
      final kv = part.split('=');
      if (kv.length == 2) {
        parsed[kv[0].trim()] = kv[1].trim();
      }
    }

    final uid = parsed['uid'] ?? '';
    final pontuacaoAnterior = int.tryParse(parsed['pontuacao'] ?? '0') ?? 0;
    final respostaUser = int.tryParse(parsed['resposta'] ?? '-1') ?? -1;

    final pontos = int.tryParse(_pointsController.text) ?? 0;
    final perguntaQuery =
        await FirebaseFirestore.instance
            .collection('perguntas')
            .where('checkpoint', isEqualTo: selectedGame)
            .limit(1)
            .get();

    int pontuacaoPergunta = 0;
    bool respostaCorreta = false;
    if (perguntaQuery.docs.isNotEmpty) {
      final doc = perguntaQuery.docs.first.data();
      final correta = doc['respostaCerta'];
      respostaCorreta = correta == respostaUser;
      if (respostaCorreta) {
        pontuacaoPergunta = doc['pontos'] ?? 0;
      }
    }

    final pontuacaoTotal = pontuacaoAnterior + pontos + pontuacaoPergunta;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('events')
        .doc('shell_km_02')
        .collection('pontuacoes')
        .doc(selectedGame.toLowerCase().replaceAll(' ', '_'))
        .set({
          'checkpointId': selectedGame,
          'pontuacaoJogo': pontos,
          'pontuacaoPergunta': pontuacaoPergunta,
          'pontuacaoTotal': pontuacaoTotal,
          'respostaCorreta': respostaCorreta,
          'timestampEntrada': FieldValue.serverTimestamp(),
          'timestampSaida': FieldValue.serverTimestamp(),
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
