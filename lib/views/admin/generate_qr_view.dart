// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show kIsWeb;

class GenerateQrView extends StatefulWidget {
  const GenerateQrView({super.key});

  @override
  State<GenerateQrView> createState() => _GenerateQrViewState();
}

class _GenerateQrViewState extends State<GenerateQrView> {
  List<String> _edicoes = [];
  String? _edicaoSelecionada;
  Map<String, String> _eventos = {};
  String? _eventoSelecionado;
  String? _postoSelecionado;
  List<String> _postos = [];
  String _tipo = 'entrada';
  String? _qrData;
  final ScreenshotController _screenshotController = ScreenshotController();
  Map<String, dynamic>? _checkpointPreview;

  @override
  void initState() {
    super.initState();
    _carregarEdicoes();
  }

  void _carregarEdicoes() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('editions').get();
    final edicoes = snapshot.docs.map((doc) => doc.id).toList();
    setState(() {
      _edicoes = edicoes;
    });
  }

  void _carregarEventos(String edicaoId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('editions')
            .doc(edicaoId)
            .collection('events')
            .get();
    final mapa = {
      for (var doc in snapshot.docs) doc.id: doc['nome'] ?? 'Sem nome',
    };
    setState(() {
      _eventos = Map<String, String>.from(mapa);
    });
  }

  void _carregarPostos(String edicaoId, String eventoId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('editions')
            .doc(edicaoId)
            .collection('events')
            .doc(eventoId)
            .collection('checkpoints')
            .get();

    final mapa = {for (var doc in snapshot.docs) doc.id: doc['nome'] ?? doc.id};

    setState(() {
      _postos = mapa.entries.map((e) => '${e.key}|${e.value}').toList();
      _postoSelecionado = null;
      _qrData = null;
    });
  }

  void _generateQR() async {
    if (_edicaoSelecionada == null) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Selecione uma edição')),
      );
      return;
    }
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
    final checkpointSnapshot =
        await FirebaseFirestore.instance
            .collection('editions')
            .doc(_edicaoSelecionada!)
            .collection('events')
            .doc(_eventoSelecionado!)
            .collection('checkpoints')
            .doc(_postoSelecionado!)
            .get();

    final checkpointData = checkpointSnapshot.data();

    if (checkpointData == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados do checkpoint não encontrados')),
      );
      return;
    }

    setState(() {
      _checkpointPreview = checkpointData;
    });

    final qrJson = {
      'edition': _edicaoSelecionada ?? '',
      'evento_id': _eventoSelecionado,
      'checkpoint_id': _postoSelecionado,
      'checkpoint_nome': checkpointData['nome'] ?? '',
      'tipo': _tipo,
      'lat': checkpointData['localizacao']?.latitude ?? '',
      'lng': checkpointData['localizacao']?.longitude ?? '',
      'percurso': checkpointData['percurso'] ?? '',
      'pergunta1Id': checkpointData['pergunta1Id'] ?? '',
      'pergunta2Id': checkpointData['pergunta2Id'] ?? '',
      'jogoId': checkpointData['jogoId'] ?? '',
    };

    setState(() {
      _qrData = qrJson.entries
          .map((e) => '"${e.key}": "${e.value}"')
          .join(', ');
      _qrData = '{$_qrData}';
    });

    // Save the full QR content in Firestore checkpoint
    await FirebaseFirestore.instance
        .collection('editions')
        .doc(_edicaoSelecionada!)
        .collection('events')
        .doc(_eventoSelecionado!)
        .collection('checkpoints')
        .doc(_postoSelecionado!)
        .set({'qrData': qrJson}, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('QR Code gerado com sucesso')));
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
                'Selecionar Edição',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: DropdownButtonFormField<String>(
                  value: _edicaoSelecionada,
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
                    hintStyle: const TextStyle(color: Colors.black),
                  ),
                  items:
                      _edicoes.map((edicao) {
                        return DropdownMenuItem(
                          value: edicao,
                          child: Text(
                            'Edição $edicao',
                            style: const TextStyle(color: Colors.black),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _edicaoSelecionada = value;
                      _eventoSelecionado = null;
                      _postos = [];
                      _checkpointPreview = null;
                      _qrData = null;
                      if (value != null) {
                        _carregarEventos(value);
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Selecionar Evento',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
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
                    hintStyle: const TextStyle(color: Colors.black),
                  ),
                  items:
                      _eventos.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(
                                entry.value,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _eventoSelecionado = value;
                      if (value != null && _edicaoSelecionada != null) {
                        _carregarPostos(_edicaoSelecionada!, value);
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
                ).textTheme.bodyMedium?.copyWith(color: Colors.black),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: DropdownButtonFormField<String>(
                  value: _postoSelecionado,
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
                    hintStyle: const TextStyle(color: Colors.black),
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  items:
                      _postos.map((postoRaw) {
                        final parts = postoRaw.split('|');
                        final id = parts[0];
                        final nome = parts.length > 1 ? parts[1] : parts[0];
                        return DropdownMenuItem(
                          value: id,
                          child: Text(
                            nome,
                            style: const TextStyle(color: Colors.black),
                          ),
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
                ).textTheme.bodyMedium?.copyWith(color: Colors.black),
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
                            padding: const EdgeInsets.symmetric(
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
                      padding: const EdgeInsets.symmetric(
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
                      padding: const EdgeInsets.symmetric(
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

                              if (kIsWeb) {
                                await Printing.layoutPdf(
                                  onLayout: (_) async => image,
                                );
                              } else {
                                final tempDir = await getTemporaryDirectory();
                                final file =
                                    await File(
                                      '${tempDir.path}/qr_code_print.png',
                                    ).create();
                                await file.writeAsBytes(image);

                                await Printing.layoutPdf(
                                  onLayout: (_) async => image,
                                );
                              }
                            },
                    icon: const Icon(Icons.print),
                    label: Text(
                      'Imprimir',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
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

                              final pdf = pw.Document();
                              pdf.addPage(
                                pw.Page(
                                  build:
                                      (pw.Context context) => pw.Center(
                                        child: pw.Column(
                                          mainAxisSize: pw.MainAxisSize.min,
                                          children: [
                                            pw.Text(
                                              'QR Code - Checkpoint',
                                              style: const pw.TextStyle(
                                                fontSize: 24,
                                              ),
                                            ),
                                            pw.SizedBox(height: 20),
                                            pw.Text(
                                              'Edição: ${_edicaoSelecionada ?? ''}',
                                            ),
                                            pw.Text(
                                              'Evento: ${_eventoSelecionado ?? ''}',
                                            ),
                                            pw.Text(
                                              'Checkpoint: ${_checkpointPreview?['nome'] ?? _postoSelecionado}',
                                            ),
                                            pw.SizedBox(height: 20),
                                            pw.Image(
                                              pw.MemoryImage(image),
                                              width: 200,
                                              height: 200,
                                            ),
                                          ],
                                        ),
                                      ),
                                ),
                              );
                              await Printing.layoutPdf(
                                onLayout: (_) => pdf.save(),
                              );
                            },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(
                      'Exportar PDF',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
              // Preview do checkpoint
              if (_checkpointPreview != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Preview do Checkpoint',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nome: ${_checkpointPreview!['nome'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.black),
                      ),
                      Text(
                        'Percurso: ${_checkpointPreview!['percurso'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.black),
                      ),
                      Text(
                        'Pergunta 1 ID: ${_checkpointPreview!['pergunta1Id'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.black),
                      ),
                      Text(
                        'Pergunta 2 ID: ${_checkpointPreview!['pergunta2Id'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.black),
                      ),
                      Text(
                        'Jogo ID: ${_checkpointPreview!['jogoId'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.black),
                      ),
                      if (_checkpointPreview!['localizacao'] != null)
                        Text(
                          'Localização: ${_checkpointPreview!['localizacao'].latitude}, ${_checkpointPreview!['localizacao'].longitude}',
                          style: const TextStyle(color: Colors.black),
                        ),
                    ],
                  ),
                ),
              ],
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
