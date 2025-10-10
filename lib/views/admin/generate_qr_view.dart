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

class GenerateQrView extends StatefulWidget {
  const GenerateQrView({super.key});

  @override
  State<GenerateQrView> createState() => _GenerateQrViewState();
}

class _GenerateQrViewState extends State<GenerateQrView>
    with SingleTickerProviderStateMixin {
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
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isSingleCheckin = false;
  final Map<String, bool> _qrGerados = {};

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _carregarEdicoes();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _carregarEdicoes() async {
    setState(() => _isLoading = true);
    final snapshot =
        await FirebaseFirestore.instance.collection('editions').get();
    final edicoes = snapshot.docs.map((doc) => doc.id).toList();
    setState(() {
      _edicoes = edicoes;
      _isLoading = false;
    });
  }

  void _carregarEventos(String edicaoId) async {
    setState(() => _isLoading = true);
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
      _isLoading = false;
    });
  }

  void _carregarPostos(String edicaoId, String eventoId) async {
    setState(() => _isLoading = true);
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
      _checkpointPreview = null;
      _isSingleCheckin = false;
      _qrGerados.clear();
      _isLoading = false;
    });
  }

  Future<void> _carregarCheckpointInfo(String checkpointId) async {
    setState(() => _isLoading = true);

    final checkpointSnapshot =
        await FirebaseFirestore.instance
            .collection('editions')
            .doc(_edicaoSelecionada!)
            .collection('events')
            .doc(_eventoSelecionado!)
            .collection('checkpoints')
            .doc(checkpointId)
            .get();

    final checkpointData = checkpointSnapshot.data();

    if (checkpointData == null) {
      setState(() => _isLoading = false);
      _showSnackBar('Dados do checkpoint não encontrados', Colors.red);
      return;
    }

    final qrDataMap = checkpointData['qrData'] as Map<String, dynamic>?;
    if (qrDataMap != null) {
      setState(() {
        _qrGerados['entrada'] = qrDataMap.containsKey('entrada');
        _qrGerados['saida'] = qrDataMap.containsKey('saida');
      });
    }

    setState(() {
      _checkpointPreview = checkpointData;
      _isSingleCheckin = checkpointData['singleCheckin'] == true;
      _isLoading = false;
    });

    _showSnackBar(
      _isSingleCheckin
          ? 'Checkpoint com Check-in Único'
          : 'Checkpoint com Entrada e Saída',
      _isSingleCheckin ? Colors.blue : Colors.purple,
    );
  }

  void _generateQR() async {
    if (_edicaoSelecionada == null) {
      _showSnackBar('⚠️ Selecione uma edição primeiro', Colors.orange);
      return;
    }
    if (_eventoSelecionado == null) {
      _showSnackBar('⚠️ Selecione um evento primeiro', Colors.orange);
      return;
    }
    if (_postoSelecionado == null) {
      _showSnackBar('⚠️ Selecione um posto primeiro', Colors.orange);
      return;
    }

    if (_qrGerados[_tipo] == true) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Text('QR Code já existe'),
                ],
              ),
              content: Text(
                'Já existe um QR Code de $_tipo para este checkpoint. Deseja substituir?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Substituir'),
                ),
              ],
            ),
      );

      if (confirmed != true) return;
    }

    setState(() => _isGenerating = true);

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
      setState(() => _isGenerating = false);
      _showSnackBar('❌ Dados do checkpoint não encontrados', Colors.red);
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
      'tipo': _isSingleCheckin ? 'single' : _tipo,
      'lat': checkpointData['localizacao']?.latitude ?? '',
      'lng': checkpointData['localizacao']?.longitude ?? '',
      'percurso': checkpointData['percurso'] ?? '',
      'perguntaId':
          (checkpointData['perguntaRef'] as DocumentReference?)?.id ?? '',
      'pergunta2Id': checkpointData['pergunta2Id'] ?? '',
      'jogoId': checkpointData['jogoId'] ?? '',
    };

    setState(() {
      _qrData = qrJson.entries
          .map((e) => '"${e.key}": "${e.value}"')
          .join(', ');
      _qrData = '{$_qrData}';
      _isGenerating = false;
      _qrGerados[_tipo] = true;
    });

    final updateKey = _isSingleCheckin ? 'single' : _tipo;
    await FirebaseFirestore.instance
        .collection('editions')
        .doc(_edicaoSelecionada!)
        .collection('events')
        .doc(_eventoSelecionado!)
        .collection('checkpoints')
        .doc(_postoSelecionado!)
        .set({'qrData.$updateKey': qrJson}, SetOptions(merge: true));

    _animationController.forward(from: 0);
    _showSnackBar('✅ QR Code gerado com sucesso!', Colors.green);
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green
                  ? Icons.check_circle
                  : color == Colors.orange
                  ? Icons.warning
                  : Icons.info,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            style: const TextStyle(color: Colors.black87, fontSize: 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            icon: Icon(Icons.arrow_drop_down_circle, color: AppColors.primary),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: onPressed == null ? 0 : 2,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'A carregar...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondaryDark],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.qr_code_2,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Gerador de QR Code',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Crie QR codes para checkpoints do evento',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Configuração
                    _buildSectionCard(
                      title: 'Configuração do Checkpoint',
                      icon: Icons.settings,
                      children: [
                        _buildDropdown(
                          label: 'Edição',
                          icon: Icons.event,
                          value: _edicaoSelecionada,
                          items:
                              _edicoes.map((edicao) {
                                return DropdownMenuItem(
                                  value: edicao,
                                  child: Text('Edição $edicao'),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _edicaoSelecionada = value;
                              _eventoSelecionado = null;
                              _postos = [];
                              _checkpointPreview = null;
                              _qrData = null;
                              _isSingleCheckin = false;
                              _qrGerados.clear();
                              if (value != null) {
                                _carregarEventos(value);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Evento',
                          icon: Icons.celebration,
                          value: _eventoSelecionado,
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
                              if (value != null && _edicaoSelecionada != null) {
                                _carregarPostos(_edicaoSelecionada!, value);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Posto (Checkpoint)',
                          icon: Icons.location_on,
                          value: _postoSelecionado,
                          items:
                              _postos.map((postoRaw) {
                                final parts = postoRaw.split('|');
                                final id = parts[0];
                                final nome =
                                    parts.length > 1 ? parts[1] : parts[0];
                                return DropdownMenuItem(
                                  value: id,
                                  child: Text(nome),
                                );
                              }).toList(),
                          onChanged:
                              _postos.isEmpty
                                  ? (String? value) {}
                                  : (value) {
                                    setState(() {
                                      _postoSelecionado = value;
                                      _qrData = null;
                                    });
                                    if (value != null) {
                                      _carregarCheckpointInfo(value);
                                    }
                                  },
                        ),

                        // Mostrar tipo de check-in apenas se checkpoint selecionado
                        if (_checkpointPreview != null) ...[
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Info sobre tipo de check-in
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  _isSingleCheckin
                                      ? Colors.blue.shade50
                                      : Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _isSingleCheckin
                                        ? Colors.blue.shade200
                                        : Colors.purple.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isSingleCheckin
                                      ? Icons.touch_app
                                      : Icons.compare_arrows,
                                  color:
                                      _isSingleCheckin
                                          ? Colors.blue
                                          : Colors.purple,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isSingleCheckin
                                            ? 'Check-in Único'
                                            : 'Check-in Duplo',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              _isSingleCheckin
                                                  ? Colors.blue.shade900
                                                  : Colors.purple.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _isSingleCheckin
                                            ? 'Este checkpoint tem apenas uma leitura de QR'
                                            : 'Este checkpoint tem entrada e saída',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Mostrar botões de tipo apenas se for double check-in
                          if (!_isSingleCheckin) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Tipo de Checkpoint',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children:
                                  ['entrada', 'saida'].map((tipo) {
                                    final isSelected = _tipo == tipo;
                                    final jaGerado = _qrGerados[tipo] == true;

                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: InkWell(
                                          onTap:
                                              () =>
                                                  setState(() => _tipo = tipo),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isSelected
                                                      ? AppColors.primary
                                                      : Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color:
                                                    isSelected
                                                        ? AppColors.primary
                                                        : Colors.transparent,
                                                width: 2,
                                              ),
                                              boxShadow:
                                                  isSelected
                                                      ? [
                                                        BoxShadow(
                                                          color: AppColors
                                                              .primary
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ]
                                                      : [],
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      tipo == 'entrada'
                                                          ? Icons.login
                                                          : Icons.logout,
                                                      color:
                                                          isSelected
                                                              ? Colors.white
                                                              : Colors
                                                                  .grey
                                                                  .shade700,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      tipo.toUpperCase(),
                                                      style: TextStyle(
                                                        color:
                                                            isSelected
                                                                ? Colors.white
                                                                : Colors
                                                                    .grey
                                                                    .shade700,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (jaGerado) ...[
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.check_circle,
                                                          size: 12,
                                                          color:
                                                              isSelected
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .green,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          'Gerado',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color:
                                                                isSelected
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .green,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botão Gerar
                    Center(
                      child:
                          _isGenerating
                              ? Column(
                                children: [
                                  CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'A gerar QR Code...',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                              : _buildActionButton(
                                label: 'Gerar QR Code',
                                icon: Icons.qr_code_scanner,
                                onPressed:
                                    _checkpointPreview != null
                                        ? _generateQR
                                        : null,
                                backgroundColor: AppColors.secondaryDark,
                              ),
                    ),
                    const SizedBox(height: 32),

                    // Preview do Checkpoint
                    if (_checkpointPreview != null) ...[
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildSectionCard(
                          title: 'Informações do Checkpoint',
                          icon: Icons.info_outline,
                          children: [
                            _buildInfoRow(
                              'Nome',
                              _checkpointPreview!['nome'] ?? 'N/A',
                              Icons.label,
                            ),
                            _buildInfoRow(
                              'Percurso',
                              _checkpointPreview!['percurso'] ?? 'N/A',
                              Icons.route,
                            ),
                            _buildInfoRow(
                              'Tipo Check-in',
                              _isSingleCheckin ? 'Único' : 'Entrada e Saída',
                              _isSingleCheckin
                                  ? Icons.touch_app
                                  : Icons.compare_arrows,
                            ),
                            _buildInfoRow(
                              'Pergunta 1',
                              (_checkpointPreview!['perguntaRef']
                                          as DocumentReference?)
                                      ?.id ??
                                  'N/A',
                              Icons.quiz,
                            ),
                            if (_checkpointPreview!['pergunta2Id'] != null &&
                                _checkpointPreview!['pergunta2Id']
                                    .toString()
                                    .isNotEmpty)
                              _buildInfoRow(
                                'Pergunta 2',
                                _checkpointPreview!['pergunta2Id'],
                                Icons.quiz,
                              ),
                            if (_checkpointPreview!['jogoId'] != null &&
                                _checkpointPreview!['jogoId']
                                    .toString()
                                    .isNotEmpty)
                              _buildInfoRow(
                                'Jogo',
                                _checkpointPreview!['jogoId'],
                                Icons.sports_esports,
                              ),
                            if (_checkpointPreview!['localizacao'] != null)
                              _buildInfoRow(
                                'Coordenadas',
                                '${_checkpointPreview!['localizacao'].latitude.toStringAsFixed(6)}, ${_checkpointPreview!['localizacao'].longitude.toStringAsFixed(6)}',
                                Icons.my_location,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // QR Code e Ações
                    if (_qrData != null) ...[
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            // QR Code Display
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Colors.white, Colors.grey.shade50],
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.primary,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Screenshot(
                                        controller: _screenshotController,
                                        child: QrImageView(
                                          data: _qrData!,
                                          version: QrVersions.auto,
                                          size: 250.0,
                                          backgroundColor: Colors.white,
                                          embeddedImage: const AssetImage(
                                            'assets/images/shell_logo.png',
                                          ),
                                          embeddedImageStyle:
                                              const QrEmbeddedImageStyle(
                                                size: Size(50, 50),
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              'Checkpoint: ${_checkpointPreview?['nome'] ?? _postoSelecionado}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppColors.primary,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            _isSingleCheckin
                                                ? Colors.blue.withValues(
                                                  alpha: 0.1,
                                                )
                                                : _tipo == 'entrada'
                                                ? Colors.green.withValues(
                                                  alpha: 0.1,
                                                )
                                                : Colors.orange.withValues(
                                                  alpha: 0.1,
                                                ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isSingleCheckin
                                                ? Icons.touch_app
                                                : _tipo == 'entrada'
                                                ? Icons.login
                                                : Icons.logout,
                                            size: 16,
                                            color:
                                                _isSingleCheckin
                                                    ? Colors.blue
                                                    : _tipo == 'entrada'
                                                    ? Colors.green
                                                    : Colors.orange,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _isSingleCheckin
                                                ? 'CHECK-IN ÚNICO'
                                                : _tipo.toUpperCase(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  _isSingleCheckin
                                                      ? Colors.blue
                                                      : _tipo == 'entrada'
                                                      ? Colors.green
                                                      : Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Ações
                            _buildSectionCard(
                              title: 'Ações',
                              icon: Icons.touch_app,
                              children: [
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildActionButton(
                                      label: 'Visualizar',
                                      icon: Icons.visibility,
                                      onPressed: () => _showQRDialog(),
                                      backgroundColor: Colors.green,
                                    ),
                                    _buildActionButton(
                                      label: 'Partilhar',
                                      icon: Icons.share,
                                      onPressed: () => _shareQR(),
                                      backgroundColor: Colors.blue,
                                    ),
                                    _buildActionButton(
                                      label: 'Imprimir',
                                      icon: Icons.print,
                                      onPressed: () => _printQR(),
                                      backgroundColor: Colors.purple,
                                    ),
                                    _buildActionButton(
                                      label: 'Exportar PDF',
                                      icon: Icons.picture_as_pdf,
                                      onPressed: () => _exportPDF(),
                                      backgroundColor: Colors.deepOrange,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQRDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.qr_code_2, color: AppColors.primary),
                const SizedBox(width: 12),
                const Text('QR Code Gerado'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: _qrData!,
                    version: QrVersions.auto,
                    size: 250.0,
                    embeddedImage: const AssetImage(
                      'assets/images/shell_logo.png',
                    ),
                    embeddedImageStyle: const QrEmbeddedImageStyle(
                      size: Size(50, 50),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Checkpoint: ${_checkpointPreview?['nome'] ?? _postoSelecionado}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _isSingleCheckin
                            ? Colors.blue.shade50
                            : _tipo == 'entrada'
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _isSingleCheckin
                        ? 'Check-in Único'
                        : _tipo == 'entrada'
                        ? 'ENTRADA'
                        : 'SAÍDA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          _isSingleCheckin
                              ? Colors.blue
                              : _tipo == 'entrada'
                              ? Colors.green
                              : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  void _shareQR() async {
    final image = await _screenshotController.capture();
    if (image == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final tipoStr = _isSingleCheckin ? 'single' : _tipo;
    final imagePath =
        await File(
          '${directory.path}/qr_code_${_postoSelecionado}_$tipoStr.png',
        ).create();
    await imagePath.writeAsBytes(image);

    final uri = Uri.file(imagePath.path);
    final launched = await launchUrl(uri);

    if (!launched && mounted) {
      _showSnackBar('Não foi possível partilhar o ficheiro', Colors.red);
    }
  }

  void _printQR() async {
    final image = await _screenshotController.capture();
    if (image == null) return;

    await Printing.layoutPdf(onLayout: (_) async => image);
  }

  void _exportPDF() async {
    final image = await _screenshotController.capture();
    if (image == null) return;

    final tipoStr = _isSingleCheckin ? 'Check-in Único' : _tipo.toUpperCase();

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
                    style: const pw.TextStyle(fontSize: 24),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('Edição: ${_edicaoSelecionada ?? ''}'),
                  pw.Text('Evento: ${_eventoSelecionado ?? ''}'),
                  pw.Text(
                    'Checkpoint: ${_checkpointPreview?['nome'] ?? _postoSelecionado}',
                  ),
                  pw.Text('Tipo: $tipoStr'),
                  pw.SizedBox(height: 20),
                  pw.Image(pw.MemoryImage(image), width: 300, height: 300),
                ],
              ),
            ),
      ),
    );
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }
}
