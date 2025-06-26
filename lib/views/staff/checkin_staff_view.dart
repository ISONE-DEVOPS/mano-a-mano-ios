// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../widgets/shared/staff_nav_bottom.dart';

class StaffScoreInputView extends StatefulWidget {
  const StaffScoreInputView({super.key});

  @override
  State<StaffScoreInputView> createState() => _StaffScoreInputViewState();
}

class _StaffScoreInputViewState extends State<StaffScoreInputView> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService.to;
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _pontuacaoController = TextEditingController();

  // Estado do formulário
  String? _selectedJogoId;
  int? _pontuacao;
  bool _loading = false;
  String? _selectedCheckpointId;
  bool _qrLido = false;
  bool _loadingJogos = false;

  // Dados do participante
  Map<String, dynamic> _participanteData = {};

  // Listas
  List<Map<String, dynamic>> _jogosDisponiveis = [];
  List<Map<String, dynamic>> _checkpoints = [];
  List<String> _jogosJaPontuados = [];

  @override
  void initState() {
    super.initState();
    _checkStaffPermission();
    _loadCheckpoints();
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar jogos que já foram pontuados
    final jogosNaoPontuados =
        _jogosDisponiveis
            .where((j) => !_jogosJaPontuados.contains(j['id']))
            .toList();

    return PopScope(
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          final canExit = await _showExitConfirmation();
          if (canExit) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Inserir Pontuação',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blue[700],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _safeNavigateBack,
          ),
          actions: [
            // Botão para voltar aos Jogos
            IconButton(
              icon: const Icon(Icons.sports_esports, color: Colors.white),
              onPressed: () => Get.offNamed('/staff/jogos'),
              tooltip: 'Voltar aos Jogos',
            ),
            // Botão Home
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: _safeNavigateHome,
              tooltip: 'Menu Staff',
            ),
            const SizedBox(width: 8),
            // Nome do Staff
            Obx(
              () => Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    'Staff: ${_authService.userData['nome'] ?? 'N/A'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (!_qrLido) _buildQRScannerSection(),
              if (_qrLido) ...[
                _buildParticipantCard(),
                const SizedBox(height: 16),
                _buildScoreForm(jogosNaoPontuados),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
        bottomNavigationBar: const StaffNavBottom(),
      ),
    );
  }

  Widget _buildQRScannerSection() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Título da seção
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.qr_code_scanner, color: Colors.blue[700]),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Digitalizar QR Code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Aponte para o código do participante',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Scanner com tamanho reduzido
            Container(
              height: 200, // Reduzido para ser mais compacto
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue[200]!, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _handleParticipantQRScan,
                    ),
                    // Overlay de foco
                    Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Stack(
                          children: [
                            // Cantos do scanner
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.green,
                                      width: 4,
                                    ),
                                    left: BorderSide(
                                      color: Colors.green,
                                      width: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.green,
                                      width: 4,
                                    ),
                                    right: BorderSide(
                                      color: Colors.green,
                                      width: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 10,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.green,
                                      width: 4,
                                    ),
                                    left: BorderSide(
                                      color: Colors.green,
                                      width: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.green,
                                      width: 4,
                                    ),
                                    right: BorderSide(
                                      color: Colors.green,
                                      width: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Instruções na parte inferior
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withAlpha(179),
                            ],
                          ),
                        ),
                        child: const Text(
                          '🧪 TESTE DE BUILD: Camera ativa - Altura 200 OK',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Dicas de uso
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Certifique-se de que há luz suficiente e o QR Code está bem visível',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green[50]!, Colors.green[100]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _participanteData['nome'] ?? 'Nome não encontrado',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_participanteData['grupo'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Grupo ${_participanteData['grupo']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _resetParticipantData,
                    icon: const Icon(Icons.restart_alt, color: Colors.grey),
                    tooltip: 'Escanear outro participante',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.7 * 255).round()),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Participante identificado com sucesso',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
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

  Widget _buildScoreForm(List<Map<String, dynamic>> jogosNaoPontuados) {
    if (_checkpoints.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Dropdown de checkpoint
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Selecione o checkpoint',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items:
                    _checkpoints.map((checkpoint) {
                      return DropdownMenuItem<String>(
                        value: checkpoint['id'],
                        child: Text(checkpoint['nome'] ?? 'Sem nome'),
                      );
                    }).toList(),
                value: _selectedCheckpointId,
                onChanged: _onCheckpointChanged,
                validator: (v) => v == null ? 'Selecione um checkpoint' : null,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Loading de jogos
          if (_loadingJogos)
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Carregando jogos...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          // Mostrar jogos já pontuados
          else if (_selectedCheckpointId != null &&
              _jogosDisponiveis.isNotEmpty) ...[
            _buildJogosStatus(),
            const SizedBox(height: 16),

            // Se há jogos não pontuados, mostra o formulário
            if (jogosNaoPontuados.isNotEmpty) ...[
              _buildJogoSelector(jogosNaoPontuados),
              const SizedBox(height: 16),

              // Campo de pontuação
              if (_selectedJogoId != null) ...[
                _buildPontuacaoField(jogosNaoPontuados),
                const SizedBox(height: 24),
                _buildSaveButton(),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildJogosStatus() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Status dos Jogos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lista de todos os jogos com status
            ..._jogosDisponiveis.map((jogo) {
              final isPontuado = _jogosJaPontuados.contains(jogo['id']);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPontuado ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isPontuado ? Colors.green[200]! : Colors.orange[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPontuado ? Icons.check_circle : Icons.pending,
                      color: isPontuado ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jogo['nome'] ?? 'Jogo sem nome',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            isPontuado ? 'Já pontuado' : 'Aguardando pontuação',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isPontuado
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Max: ${jogo['pontuacaoMax']} pts',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Resumo
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Progresso: ${_jogosJaPontuados.length}/${_jogosDisponiveis.length} jogos pontuados',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJogoSelector(List<Map<String, dynamic>> jogosNaoPontuados) {
    if (jogosNaoPontuados.isEmpty) {
      return Card(
        elevation: 3,
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Todos os jogos deste checkpoint já foram pontuados! 🎉",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Selecione o próximo jogo para pontuar',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.sports_esports),
            filled: true,
            fillColor: Colors.grey[50],
            helperText: '${jogosNaoPontuados.length} jogo(s) restante(s)',
          ),
          items:
              jogosNaoPontuados.map((jogo) {
                return DropdownMenuItem<String>(
                  value: jogo['id'],
                  child: Text(
                    '${jogo['nome']} (Max: ${jogo['pontuacaoMax']} pts)',
                  ),
                );
              }).toList(),
          value: _selectedJogoId,
          onChanged: (v) {
            setState(() {
              _selectedJogoId = v;
              _pontuacaoController.clear();
              _pontuacao = null;
            });
          },
          validator: (v) => v == null ? 'Selecione um jogo' : null,
        ),
      ),
    );
  }

  Widget _buildPontuacaoField(List<Map<String, dynamic>> jogosNaoPontuados) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextFormField(
          controller: _pontuacaoController,
          decoration: InputDecoration(
            labelText:
                'Pontuação (0 - ${jogosNaoPontuados.firstWhereOrNull((j) => j['id'] == _selectedJogoId)?['pontuacaoMax'] ?? 100})',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.score),
            filled: true,
            fillColor: Colors.grey[50],
            helperText: 'Digite a pontuação obtida pelo participante',
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) => setState(() => _pontuacao = int.tryParse(v)),
          validator: _validatePontuacao,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 6,
        ),
        onPressed:
            _loading
                ? null
                : _canSave()
                ? _savePontuacao
                : null,
        child:
            _loading
                ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Salvando...'),
                  ],
                )
                : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Salvar Pontuação',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  // Método para verificar se pode salvar
  bool _canSave() {
    return _selectedCheckpointId != null &&
        _selectedJogoId != null &&
        _pontuacao != null &&
        _pontuacaoController.text.isNotEmpty &&
        _validatePontuacao(_pontuacaoController.text) == null;
  }

  // MÉTODOS DE NAVEGAÇÃO
  Future<bool> _showExitConfirmation() async {
    if (!_qrLido && _selectedCheckpointId == null && _selectedJogoId == null) {
      return true;
    }

    final ctx = context;
    final result = await showDialog<bool>(
      context: ctx,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text('Confirmar Saída'),
            content: const Text(
              'Há dados preenchidos que serão perdidos. Deseja realmente sair?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Sair'),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  Future<void> _safeNavigateBack() async {
    final canExit = await _showExitConfirmation();
    if (canExit) Get.back();
  }

  Future<void> _safeNavigateHome() async {
    final canExit = await _showExitConfirmation();
    if (canExit) Get.offAllNamed('/staff-home');
  }

  Future<void> _checkStaffPermission() async {
    if (!_authService.isStaff && !_authService.isAdmin) {
      Get.back();
      Get.snackbar(
        'Acesso Negado',
        'Apenas staff pode acessar esta tela',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String? _validatePontuacao(String? value) {
    if (value == null || value.isEmpty) return 'Digite a pontuação';

    final val = int.tryParse(value);
    if (val == null) return 'Digite um número válido';
    if (val < 0) return 'Pontuação não pode ser negativa';

    final maxPontuacao =
        _jogosDisponiveis.firstWhereOrNull(
          (j) => j['id'] == _selectedJogoId,
        )?['pontuacaoMax'] ??
        100;
    if (val > maxPontuacao) return 'Pontuação máxima é $maxPontuacao';

    return null;
  }

  Future<void> _loadCheckpoints() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('editions')
              .doc('shell_2025')
              .collection('events')
              .doc('shell_km_02')
              .collection('checkpoints')
              .get();

      setState(() {
        _checkpoints =
            snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                'nome': data['nome'] ?? '',
                'jogosRefs': data['jogosRefs'] ?? [],
                'jogoRef': data['jogoRef'],
              };
            }).toList();
      });

      if (_checkpoints.isEmpty) {
        Get.snackbar(
          'Sem checkpoints',
          'Nenhum checkpoint encontrado. Verifique a Firestore.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      developer.log('Error loading checkpoints: $e', name: 'StaffScoreInput');
    }
  }

  Future<void> _loadJogosFromCheckpoint(Map<String, dynamic> checkpoint) async {
    setState(() => _loadingJogos = true);

    List<Map<String, dynamic>> jogos = [];

    try {
      if (checkpoint['jogosRefs'] != null &&
          (checkpoint['jogosRefs'] as List).isNotEmpty) {
        final List<dynamic> refs = checkpoint['jogosRefs'];

        for (var ref in refs) {
          try {
            DocumentSnapshot doc;
            if (ref is DocumentReference) {
              doc = await ref.get();
            } else if (ref is String) {
              doc = await FirebaseFirestore.instance.doc(ref).get();
            } else {
              continue;
            }

            if (doc.exists) {
              final data = doc.data() as Map<String, dynamic>;
              jogos.add({
                'id': doc.id,
                'nome': data['nome'] ?? 'Jogo sem nome',
                'pontuacaoMax': data['pontuacaoMax'] ?? 100,
              });
            }
          } catch (e) {
            developer.log(
              'Error loading individual jogo: $e',
              name: 'StaffScoreInput',
            );
          }
        }
      } else if (checkpoint['jogoRef'] != null) {
        try {
          DocumentSnapshot doc;
          final ref = checkpoint['jogoRef'];
          if (ref is DocumentReference) {
            doc = await ref.get();
          } else if (ref is String) {
            doc = await FirebaseFirestore.instance.doc(ref).get();
          } else {
            throw Exception('Invalid reference type');
          }

          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            jogos.add({
              'id': doc.id,
              'nome': data['nome'] ?? 'Jogo sem nome',
              'pontuacaoMax': data['pontuacaoMax'] ?? 100,
            });
          }
        } catch (e) {
          developer.log(
            'Error loading single jogo: $e',
            name: 'StaffScoreInput',
          );
        }
      }

      await _loadJogosJaPontuados();
    } catch (e) {
      developer.log('General error loading jogos: $e', name: 'StaffScoreInput');
    }

    setState(() {
      _jogosDisponiveis = jogos;
      _selectedJogoId = null;
      _loadingJogos = false;
    });
  }

  Future<void> _loadJogosJaPontuados() async {
    if (_participanteData['uid'] == null || _selectedCheckpointId == null) {
      return;
    }

    try {
      final pontuacaoDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_participanteData['uid'])
              .collection('eventos')
              .doc('shell_km_02')
              .collection('pontuacoes')
              .doc(_selectedCheckpointId!)
              .get();

      if (pontuacaoDoc.exists) {
        final data = pontuacaoDoc.data() as Map<String, dynamic>;
        final jogosPontuados = data['jogosPontuados'] as Map<String, dynamic>?;

        if (jogosPontuados != null) {
          setState(() {
            _jogosJaPontuados = jogosPontuados.keys.toList();
          });
        }
      }
    } catch (e) {
      developer.log(
        'Error loading pontuated games: $e',
        name: 'StaffScoreInput',
      );
    }
  }

  Future<void> _handleParticipantQRScan(BarcodeCapture capture) async {
    if (_qrLido) return;

    final qr = capture.barcodes.first.rawValue;
    if (qr == null) return;

    try {
      await _scannerController.stop();
      setState(() => _qrLido = true);

      final data = jsonDecode(qr);
      final uid = data['uid'];
      final nome = data['nome'];

      if (uid == null || nome == null) {
        throw Exception('QR inválido: dados incompletos');
      }

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw Exception('Usuário não encontrado');
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        _participanteData = {
          'uid': uid,
          'nome': nome,
          'grupo': userData['grupo'] ?? 'A',
          'equipaId': userData['equipaId'],
        };
      });

      Get.snackbar(
        'Sucesso',
        'Dados do participante carregados: $nome',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      developer.log(
        'Error processing participant QR: $e',
        name: 'StaffScoreInput',
      );

      Get.snackbar(
        'Erro',
        'QR inválido ou erro ao carregar dados',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      _resetParticipantData();
    }
  }

  Future<void> _onCheckpointChanged(String? checkpointId) async {
    if (checkpointId == null) return;

    setState(() {
      _selectedCheckpointId = checkpointId;
      _selectedJogoId = null;
      _jogosDisponiveis = [];
      _jogosJaPontuados = [];
      _pontuacaoController.clear();
      _pontuacao = null;
    });

    final selectedCheckpoint = _checkpoints.firstWhereOrNull(
      (c) => c['id'] == checkpointId,
    );

    if (selectedCheckpoint != null) {
      await _loadJogosFromCheckpoint(selectedCheckpoint);
    }
  }

  Future<void> _savePontuacao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final uid = _participanteData['uid'];
      if (uid == null || uid.isEmpty) {
        throw Exception('Participante inválido');
      }

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('eventos')
          .doc('shell_km_02')
          .collection('pontuacoes')
          .doc(_selectedCheckpointId!);

      // Garante que o documento do checkpoint existe
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        await docRef.set({
          'timestampEntrada': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await docRef.update({
        'jogosPontuados.$_selectedJogoId': _pontuacao,
        'pontuacaoJogo': FieldValue.increment(_pontuacao ?? 0),
        'pontuacaoTotal': FieldValue.increment(_pontuacao ?? 0),
        'timestampPontuacao': FieldValue.serverTimestamp(),
      });

      // Chamada para atualizar pontuacaoTotal agregada
      await _atualizarPontuacaoTotal(uid);
      await _atualizarClassificacaoGeral();

      // Atualizar lista de jogos já pontuados
      setState(() {
        _jogosJaPontuados.add(_selectedJogoId!);
      });

      final remainingGames =
          _jogosDisponiveis
              .where((j) => !_jogosJaPontuados.contains(j['id']))
              .length;

      if (remainingGames > 0) {
        // Ainda há jogos para pontuar - resetar formulário para o próximo jogo
        await _showSuccessAndContinueDialog(remainingGames);

        setState(() {
          _selectedJogoId = null;
          _pontuacao = null;
        });
        _pontuacaoController.clear();
      } else {
        // Todos os jogos foram pontuados - mostrar sucesso final
        await _showFinalSuccessDialog();
        if (!mounted) return;
        Get.offAllNamed('/staff/jogos');
      }
    } catch (e) {
      developer.log('Error saving score: $e', name: 'StaffScoreInput');

      Get.snackbar(
        'Erro',
        'Erro ao salvar pontuação: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showSuccessAndContinueDialog(int remainingGames) async {
    if (!mounted) return;
    final ctx = context;
    await showDialog(
      context: ctx,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pontuação Salva! ✅',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jogo pontuado com sucesso para ${_participanteData['nome']}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Restam $remainingGames jogo(s) para pontuar neste checkpoint',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Continuar Pontuando'),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _showFinalSuccessDialog() async {
    if (!mounted) return;
    final ctx = context;
    await showDialog(
      context: ctx,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.celebration,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Checkpoint Completo! 🎉',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Todos os jogos foram pontuados para ${_participanteData['nome']} neste checkpoint!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Participante pode prosseguir para o próximo checkpoint',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Finalizar'),
                ),
              ),
            ],
          ),
    );
  }

  void _resetParticipantData() {
    setState(() {
      _qrLido = false;
      _selectedCheckpointId = null;
      _selectedJogoId = null;
      _pontuacao = null;
      _jogosDisponiveis = [];
      _jogosJaPontuados = [];
      _participanteData = {};
    });

    _pontuacaoController.clear();
    _scannerController.start();
  }

  /// Atualiza o campo pontuacaoTotal do documento do evento para o participante,
  /// somando todas as pontuações de perguntas e jogos dos checkpoints.
  Future<void> _atualizarPontuacaoTotal(String uid) async {
    try {
      final pontuacoesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('eventos')
          .doc('shell_km_02')
          .collection('pontuacoes')
          .get();

      int total = 0;

      for (var doc in pontuacoesSnapshot.docs) {
        final data = doc.data();
        total += ((data['pontuacaoPergunta'] ?? 0) as num).toInt() +
                 ((data['pontuacaoJogo'] ?? 0) as num).toInt();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('eventos')
          .doc('shell_km_02')
          .update({'pontuacaoTotal': total});
    } catch (e) {
      developer.log('Erro ao atualizar pontuacaoTotal: $e', name: 'StaffScoreInput');
    }
  }

  /// Atualiza a classificação geral dos participantes do evento shell_km_02
  Future<void> _atualizarClassificacaoGeral() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('shell_km_02')
          .orderBy('pontuacaoTotal', descending: true)
          .orderBy('tempoTotal')
          .get();

      int posicao = 1;
      for (var doc in snapshot.docs) {
        await doc.reference.update({'classificacao': posicao});
        posicao++;
      }

      developer.log('>>> classificacoes atualizadas');
    } catch (e) {
      developer.log('Erro ao atualizar classificacao: $e', name: 'StaffScoreInput');
    }
  }

  @override
  void dispose() {
    _pontuacaoController.dispose();
    _scannerController.dispose();
    super.dispose();
  }
}
