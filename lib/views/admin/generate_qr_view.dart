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
  Map<String, String> _eventos = {};
  String? _eventoSelecionado;
  String? _postoSelecionado;
  List<String> _postos = [];
  String _tipo = 'entrada';
  String? _qrData;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _carregarEventos();
  }

  void _carregarEventos() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('events').get();
    final mapa = {
      for (var doc in snapshot.docs) doc.id: doc['nome'] ?? 'Sem nome',
    };
    setState(() {
      _eventos = Map<String, String>.from(mapa);
    });
  }

  void _carregarPostos(String eventId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .get();
    final data = doc.data();
    if (data == null) return;
    if (!data.containsKey('checkpoints')) return;
    final checkpoints = Map<String, dynamic>.from(data['checkpoints']);
    final postos = checkpoints.keys.toList();
    setState(() {
      _postos = postos;
      _postoSelecionado = null;
      _qrData = null;
    });
  }

  void _generateQR() async {
    if (_eventoSelecionado == null) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Selecione um evento')),
      );
      return;
    }

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
            .doc(_eventoSelecionado!)
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
      'codigo': postoData['codigo'] ?? '',
      'lat': postoData['lat'] ?? '',
      'lng': postoData['lng'] ?? '',
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
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gerar QR Code - Checkpoint',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Selecionar Evento',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 320),
                child: DropdownButtonFormField<String>(
                  value: _eventoSelecionado,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade300,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    labelStyle: const TextStyle(color: Colors.black),
                    hintStyle: const TextStyle(color: Colors.black54),
                  ),
                  items:
                      _eventos.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _eventoSelecionado = value;
                      if (value != null) {
                        _carregarPostos(value);
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Selecionar Posto',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 320),
                child: DropdownButtonFormField<String>(
                  value: _postoSelecionado,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade300,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    labelStyle: const TextStyle(color: Colors.black),
                    hintStyle: const TextStyle(color: Colors.black54),
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black54,
                  ),
                  items:
                      _postos.map((posto) {
                        return DropdownMenuItem(
                          value: posto,
                          child: Text(posto),
                        );
                      }).toList(),
                  onChanged:
                      _postos.isEmpty
                          ? null
                          : (value) =>
                              setState(() => _postoSelecionado = value),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tipo de Checkpoint',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
              ),
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
                                isSelected ? Colors.red : Colors.grey.shade300,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            tipo.toUpperCase(),
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                    label: Text(
                      'Gerar QR',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryDark,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
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

                              final uri = Uri.file(imagePath.path);
                              final launched = await launchUrl(uri);

                              if (!launched && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Não foi possível abrir o ficheiro',
                                    ),
                                  ),
                                );
                              }
                            },
                    icon: const Icon(Icons.share),
                    label: Text(
                      'Partilhar',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
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
