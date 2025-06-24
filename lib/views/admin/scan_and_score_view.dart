import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

class ScanAndScoreView extends StatefulWidget {
  const ScanAndScoreView({super.key});

  @override
  State<ScanAndScoreView> createState() => _ScanAndScoreViewState();
}

class _ScanAndScoreViewState extends State<ScanAndScoreView> {
  final MobileScannerController _scannerController = MobileScannerController();
  final AuthService _authService = AuthService.to;
  final TextEditingController _pointsController = TextEditingController();
  
  // Estado da tela
  Map<String, dynamic> _participanteData = {};
  String _selectedCheckpoint = '';
  String _selectedGame = '';
  bool _isScanned = false;
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Listas dinâmicas
  List<Map<String, dynamic>> _checkpoints = [];
  List<Map<String, dynamic>> _jogosDisponiveis = [];

  // Jogos disponíveis (pode ser carregado do Firestore)
  final List<String> _jogosEstaticos = [
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

  @override
  void initState() {
    super.initState();
    _checkAdminPermission();
    _loadCheckpoints();
  }

  Future<void> _checkAdminPermission() async {
    if (!_authService.isAdmin && !_authService.isStaff) {
      Get.back();
      Get.snackbar(
        'Acesso Negado',
        'Apenas administradores podem acessar esta tela',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _loadCheckpoints() async {
    setState(() => _isLoading = true);
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('editions')
          .doc('shell_2025')
          .collection('events')
          .doc('shell_km_02')
          .collection('checkpoints')
          .get();

      setState(() {
        _checkpoints = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'nome': data['nome'] ?? doc.id,
            'jogosRefs': data['jogosRefs'] ?? [],
            'jogoRef': data['jogoRef'],
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Erro ao carregar checkpoints: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadJogosFromCheckpoint(String checkpointId) async {
    final checkpoint = _checkpoints.firstWhere(
      (c) => c['id'] == checkpointId,
      orElse: () => {},
    );

    if (checkpoint.isEmpty) return;

    List<Map<String, dynamic>> jogos = [];

    try {
      // Carregar jogos do checkpoint
      if (checkpoint['jogosRefs'] != null &&
          (checkpoint['jogosRefs'] as List).isNotEmpty) {
        for (var ref in checkpoint['jogosRefs']) {
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
        }
      } else if (checkpoint['jogoRef'] != null) {
        DocumentSnapshot doc;
        final ref = checkpoint['jogoRef'];
        if (ref is DocumentReference) {
          doc = await ref.get();
        } else if (ref is String) {
          doc = await FirebaseFirestore.instance.doc(ref).get();
        } else {
          return;
        }

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          jogos.add({
            'id': doc.id,
            'nome': data['nome'] ?? 'Jogo sem nome',
            'pontuacaoMax': data['pontuacaoMax'] ?? 100,
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar jogos: $e');
    }

    setState(() {
      _jogosDisponiveis = jogos;
      _selectedGame = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registo de Pontuação - Admin'),
        backgroundColor: AppColors.primary,
        actions: [
          Obx(() => Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Admin: ${_authService.userData['nome'] ?? 'N/A'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instruções
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Escaneie o QR Code do participante para registrar pontuação',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Scanner QR
                  if (!_isScanned)
                    Expanded(
                      flex: 3,
                      child: Card(
                        elevation: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: MobileScanner(
                            controller: _scannerController,
                            onDetect: _handleQRScan,
                          ),
                        ),
                      ),
                    ),

                  // Dados do participante escaneado
                  if (_isScanned) ...[
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  _participanteData['nome'] ?? 'Nome não encontrado',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_participanteData['uid'] != null)
                              Text(
                                'UID: ${_participanteData['uid']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.restart_alt),
                                label: const Text('Escanear outro'),
                                onPressed: _resetScanner,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Formulário
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          // Dropdown Checkpoint
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Selecione o checkpoint',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            value: _selectedCheckpoint.isEmpty ? null : _selectedCheckpoint,
                            items: _checkpoints.map((checkpoint) {
                              return DropdownMenuItem<String>(
                                value: checkpoint['id'],
                                child: Text(checkpoint['nome']),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              if (value != null) {
                                setState(() {
                                  _selectedCheckpoint = value;
                                  _selectedGame = '';
                                });
                                await _loadJogosFromCheckpoint(value);
                              }
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Dropdown Jogo
                          if (_selectedCheckpoint.isNotEmpty)
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Selecione o jogo',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.sports_esports),
                              ),
                              value: _selectedGame.isEmpty ? null : _selectedGame,
                              items: [
                                // Jogos do checkpoint (se houver)
                                ..._jogosDisponiveis.map((jogo) {
                                  return DropdownMenuItem<String>(
                                    value: jogo['id'],
                                    child: Text(
                                      '${jogo['nome']} (Max: ${jogo['pontuacaoMax']} pts)',
                                    ),
                                  );
                                }),
                                // Jogos estáticos como fallback
                                if (_jogosDisponiveis.isEmpty)
                                  ..._jogosEstaticos.map((jogo) {
                                    return DropdownMenuItem<String>(
                                      value: jogo,
                                      child: Text(jogo),
                                    );
                                  }),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedGame = value ?? '');
                              },
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Campo de pontos
                          if (_selectedGame.isNotEmpty)
                            TextFormField(
                              controller: _pointsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Pontos (0 - ${_getMaxPoints()})',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.score),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Digite a pontuação';
                                }
                                final points = int.tryParse(value);
                                if (points == null || points < 0) {
                                  return 'Digite um número válido';
                                }
                                final maxPoints = _getMaxPoints();
                                if (points > maxPoints) {
                                  return 'Pontuação máxima é $maxPoints';
                                }
                                return null;
                              },
                            ),
                          
                          const Spacer(),
                          
                          // Botão salvar
                          if (_selectedGame.isNotEmpty && _pointsController.text.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: _isSaving ? null : _submitScore,
                                child: _isSaving
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
                                          SizedBox(width: 8),
                                          Text('Salvando...'),
                                        ],
                                      )
                                    : const Text(
                                        'Salvar Pontuação',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
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

  void _handleQRScan(BarcodeCapture capture) async {
    if (_isScanned) return;

    final barcode = capture.barcodes.first;
    final qrData = barcode.rawValue ?? '';

    if (qrData.isEmpty) return;

    try {
      await _scannerController.stop();
      setState(() => _isScanned = true);

      // Tentar fazer parse do QR
      Map<String, dynamic> participanteData = {};

      try {
        // Tentar JSON primeiro
        participanteData = jsonDecode(qrData);
      } catch (e) {
        // Tentar formato key=value;key=value
        final parts = qrData.split(';');
        for (var part in parts) {
          final kv = part.split('=');
          if (kv.length == 2) {
            participanteData[kv[0].trim()] = kv[1].trim();
          }
        }
      }

      if (participanteData.isEmpty || participanteData['uid'] == null) {
        throw Exception('QR inválido: dados do participante não encontrados');
      }

      setState(() {
        _participanteData = participanteData;
      });

      Get.snackbar(
        'Sucesso',
        'Dados do participante carregados',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar(
        'Erro',
        'QR inválido ou erro ao processar: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      
      _resetScanner();
    }
  }

  int _getMaxPoints() {
    if (_jogosDisponiveis.isNotEmpty) {
      final jogo = _jogosDisponiveis.firstWhere(
        (j) => j['id'] == _selectedGame,
        orElse: () => {'pontuacaoMax': 100},
      );
      return jogo['pontuacaoMax'] ?? 100;
    }
    return 100; // Default para jogos estáticos
  }

  Future<void> _submitScore() async {
    if (_participanteData['uid'] == null ||
        _selectedCheckpoint.isEmpty ||
        _selectedGame.isEmpty ||
        _pointsController.text.isEmpty) {
      Get.snackbar(
        'Erro',
        'Preencha todos os campos',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = _participanteData['uid'];
      final pontos = int.tryParse(_pointsController.text) ?? 0;

      // Registrar pontuação
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('eventos')
          .doc('shell_2025')
          .collection('pontuacoes')
          .doc(_selectedCheckpoint)
          .set({
            'checkpointId': _selectedCheckpoint,
            'jogosPontuados': {_selectedGame: pontos},
            'pontuacaoJogo': FieldValue.increment(pontos),
            'pontuacaoTotal': FieldValue.increment(pontos),
            'timestampPontuacao': FieldValue.serverTimestamp(),
            'pontuadoPorAdmin': true,
            'adminId': _authService.currentUser?.uid,
          }, SetOptions(merge: true));

      Get.snackbar(
        'Sucesso',
        'Pontuação registrada com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      _resetScanner();

    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao salvar pontuação: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _resetScanner() {
    setState(() {
      _isScanned = false;
      _participanteData = {};
      _selectedCheckpoint = '';
      _selectedGame = '';
      _pointsController.clear();
      _jogosDisponiveis = [];
    });
    
    _scannerController.start();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _pointsController.dispose();
    super.dispose();
  }
}