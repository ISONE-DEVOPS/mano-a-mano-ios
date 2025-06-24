// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';

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
        body: Column(
          children: [
            // Header com instruções
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scanner QR Code',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Aponte a câmera para o QR do participante',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Botões de navegação rápida
                    Row(
                      children: [
                        Expanded(
                          child: _buildHeaderButton(
                            'Jogos',
                            Icons.sports_esports,
                            () => Get.offNamed('/staff/jogos'),
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildHeaderButton(
                            'Menu Staff',
                            Icons.home,
                            _safeNavigateHome,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Conteúdo principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // QR Scanner melhorado
                    if (!_qrLido) _buildQRScannerSection(),

                    // Dados do participante escaneado
                    if (_qrLido) ...[
                      _buildParticipantCard(),
                      const SizedBox(height: 16),
                      _buildScoreForm(jogosNaoPontuados),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha((0.3 * 255).round())),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
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

            // Scanner com overlay melhorado
            Container(
              height: 300,
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
                        width: 200,
                        height: 200,
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
                          'Posicione o QR Code dentro da área marcada',
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
                    onPressed: _resetScanner,
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

          // Loading de jogos ou dropdown de jogos
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
          else if (_selectedCheckpointId != null && jogosNaoPontuados.isEmpty)
            Card(
              elevation: 3,
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Nenhum jogo disponível para este checkpoint",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_selectedCheckpointId != null) ...[
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Selecione o jogo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.sports_esports),
                    filled: true,
                    fillColor: Colors.grey[50],
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
            ),

            const SizedBox(height: 16),

            // Campo de pontuação
            if (_selectedJogoId != null) ...[
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    controller: _pontuacaoController,
                    decoration: InputDecoration(
                      labelText:
                          'Pontuação (0 - ${jogosNaoPontuados.firstWhereOrNull((j) => j['id'] == _selectedJogoId)?['pontuacaoMax'] ?? 100})',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.score),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      setState(() {
                        _pontuacao = int.tryParse(v);
                      });
                    },
                    validator: _validatePontuacao,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botão de salvar melhorado
              SizedBox(
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
                  onPressed: _loading ? null : _savePontuacao,
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
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
              ),
            ],
          ],
        ],
      ),
    );
  }

  // MÉTODOS DE NAVEGAÇÃO
  Future<bool> _showExitConfirmation() async {
    if (!_qrLido && _selectedCheckpointId == null && _selectedJogoId == null) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
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
    if (canExit) {
      Get.back();
    }
  }

  Future<void> _safeNavigateHome() async {
    final canExit = await _showExitConfirmation();
    if (canExit) {
      Get.offAllNamed('/staff-home');
    }
  }

  // [Resto dos métodos permanecem iguais...]
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
    if (value == null || value.isEmpty) {
      return 'Digite a pontuação';
    }

    final val = int.tryParse(value);
    if (val == null) {
      return 'Digite um número válido';
    }

    if (val < 0) {
      return 'Pontuação não pode ser negativa';
    }

    final maxPontuacao =
        _jogosDisponiveis.firstWhereOrNull(
          (j) => j['id'] == _selectedJogoId,
        )?['pontuacaoMax'] ??
        100;

    if (val > maxPontuacao) {
      return 'Pontuação máxima é $maxPontuacao';
    }

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
    } catch (e) {
      developer.log('Error loading checkpoints: $e', name: 'StaffScoreInput');
    }
  }

  Future<void> _loadJogosFromCheckpoint(Map<String, dynamic> checkpoint) async {
    setState(() {
      _loadingJogos = true;
    });

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

      await _detectActiveCheckpoint(uid, userData['veiculoId']);

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

      _resetScanner();
    }
  }

  Future<void> _detectActiveCheckpoint(String uid, String? veiculoId) async {
    if (veiculoId == null) return;

    try {
      final veiculoCheckpointSnapshot =
          await FirebaseFirestore.instance
              .collection('veiculos')
              .doc(veiculoId)
              .collection('checkpoints')
              .get();

      String? checkpointAtivo;
      for (var doc in veiculoCheckpointSnapshot.docs) {
        final data = doc.data();
        final tipo = data['tipo'];
        final posto = data['posto'];

        if (tipo == 'entrada' && posto != null) {
          final saidaRegistrada = veiculoCheckpointSnapshot.docs.any((d) {
            final dData = d.data();
            return dData['posto']?.toString().trim() ==
                    posto.toString().trim() &&
                dData['tipo'] == 'saida';
          });

          if (!saidaRegistrada) {
            checkpointAtivo = posto.toString().trim();
            break;
          }
        }
      }

      if (checkpointAtivo != null) {
        setState(() {
          _selectedCheckpointId = checkpointAtivo;
        });

        final selectedCheckpoint = _checkpoints.firstWhereOrNull(
          (c) => c['id'] == checkpointAtivo,
        );

        if (selectedCheckpoint != null) {
          await _loadJogosFromCheckpoint(selectedCheckpoint);
        }
      }
    } catch (e) {
      developer.log(
        'Error detecting active checkpoint: $e',
        name: 'StaffScoreInput',
      );
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

      await docRef.update({
        'jogosPontuados.$_selectedJogoId': _pontuacao,
        'pontuacaoJogo': FieldValue.increment(_pontuacao ?? 0),
        'pontuacaoTotal': FieldValue.increment(_pontuacao ?? 0),
        'timestampPontuacao': FieldValue.serverTimestamp(),
      });

      await _showSuccessDialog();
      Get.offAllNamed('/staff/jogos');
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

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
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
                    'Pontuação Salva!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A pontuação foi registrada com sucesso para ${_participanteData['nome']}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
    );
  }

  void _resetScanner() {
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

  @override
  void dispose() {
    _pontuacaoController.dispose();
    _scannerController.dispose();
    super.dispose();
  }
}
