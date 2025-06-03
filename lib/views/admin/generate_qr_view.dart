// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';

class GenerateQrView extends StatefulWidget {
  const GenerateQrView({super.key});

  @override
  State<GenerateQrView> createState() => _GenerateQrViewState();
}

class _GenerateQrViewState extends State<GenerateQrView> {
  String? _postoSelecionado;
  List<String> _postos = [];
  String _tipo = 'entrada';
  String? _qrData;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _carregarPostos();
  }

  void _carregarPostos() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('events')
            .doc('3kqVSO4rgvIamJo0Och3')
            .get();
    final data = doc.data();
    if (data == null || data['checkpoints'] == null) return;

    final checkpoints = Map<String, dynamic>.from(data['checkpoints']);
    setState(() {
      _postos = checkpoints.keys.toList();
    });
  }

  void _generateQR() async {
    if (_postoSelecionado == null) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Selecione um posto')),
      );
      return;
    }

    if (_qrData != null &&
        _qrData!.contains('"posto_id": "$_postoSelecionado"') &&
        _qrData!.contains('"tipo": "$_tipo"')) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('QR já gerado para esse posto e tipo')),
      );
      return;
    }

    final doc =
        await FirebaseFirestore.instance
            .collection('events')
            .doc('3kqVSO4rgvIamJo0Och3')
            .get();
    final data = doc.data();
    if (data == null || data['checkpoints'] == null) return;

    if (!mounted) return;

    final checkpoints = Map<String, dynamic>.from(data['checkpoints']);
    final postoData = Map<String, dynamic>.from(
      checkpoints[_postoSelecionado!] ?? {},
    );
    final qrJson = {
      'posto_id': _postoSelecionado,
      'tipo': _tipo,
      'nome': postoData['name'] ?? '',
    };

    setState(() {
      _qrData = qrJson.toString();
    });

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('QR Code gerado com sucesso')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondaryDark,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gerar QR Code - Checkpoint'),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selecionar Posto'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _postoSelecionado,
                items:
                    _postos
                        .map(
                          (posto) => DropdownMenuItem(
                            value: posto,
                            child: Text(posto),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _postoSelecionado = value),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Escolha um posto',
                ),
              ),
              const SizedBox(height: 20),
              const Text('Tipo de Checkpoint'),
              const SizedBox(height: 6),
              Row(
                children:
                    ['entrada', 'saida'].map((tipo) {
                      final isSelected = _tipo == tipo;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton(
                          onPressed: () => setState(() => _tipo = tipo),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isSelected
                                    ? (tipo == 'entrada'
                                        ? AppColors.primary
                                        : AppColors.primary)
                                    : AppColors.secondaryDark.withAlpha(51),
                            foregroundColor:
                                isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                          ),
                          child: Text(tipo.toUpperCase()),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: _generateQR,
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Gerar QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryDark,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        _qrData == null
                            ? null
                            : () async {
                              final image =
                                  await _screenshotController.capture();
                              if (image == null) return;

                              final directory =
                                  await getApplicationDocumentsDirectory();
                              final imagePath =
                                  await File(
                                    '${directory.path}/qr_code_${_postoSelecionado}_$_tipo.png',
                                  ).create();
                              await imagePath.writeAsBytes(image);

                              if (!mounted) return;

                              final uri = Uri.file(imagePath.path);
                              final launched = await launchUrl(uri);

                              if (!mounted) return;

                              if (!mounted) return;
                              if (!launched) {
                                final messenger = ScaffoldMessenger.of(context);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Não foi possível abrir o ficheiro',
                                    ),
                                  ),
                                );
                              }
                            },
                    icon: const Icon(Icons.share),
                    label: const Text('Partilhar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_qrData != null)
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Screenshot(
                        controller: _screenshotController,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary,
                              width: 4,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          child: QrImageView(
                            data: _qrData!,
                            version: QrVersions.auto,
                            size: 200.0,
                            embeddedImage: const AssetImage(
                              'assets/images/shell_logo.png',
                            ),
                            embeddedImageStyle: const QrEmbeddedImageStyle(
                              size: Size(40, 40),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        child: Text(
                          'Checkpoint: $_postoSelecionado',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
