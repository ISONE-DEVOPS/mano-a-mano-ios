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
      developer.log(
        'Loading jogos from checkpoint: ${checkpoint['nome']}',
        name: 'StaffScoreInput',
      );

      // Verificar múltiplos jogos (jogosRefs)
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
      }
      // Verificar jogo único (jogoRef)
      else if (checkpoint['jogoRef'] != null) {
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

      // Carregar jogos já pontuados pelo participante
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

  @override
  Widget build(BuildContext context) {
    // Filtrar jogos que já foram pontuados
    final jogosNaoPontuados =
        _jogosDisponiveis
            .where((j) => !_jogosJaPontuados.contains(j['id']))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inserir Pontuação'),
        backgroundColor: Colors.blue[700],
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  'Staff: ${_authService.userData['nome'] ?? 'N/A'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instruções
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Escaneie o QR Code do participante para começar',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // QR Scanner
            if (!_qrLido)
              Card(
                elevation: 4,
                child: SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: MobileScanner(
                      controller: _scannerController,
                      onDetect: _handleParticipantQRScan,
                    ),
                  ),
                ),
              ),

            // Dados do participante escaneado
            if (_qrLido) ...[
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 24,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _participanteData['nome'] ?? 'Nome não encontrado',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_participanteData['grupo'] != null)
                        Text(
                          'Grupo: ${_participanteData['grupo']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Escanear outro participante'),
                          onPressed: _resetScanner,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Formulário de pontuação
              if (_checkpoints.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Dropdown de checkpoint
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Selecione o checkpoint',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
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
                          validator:
                              (v) =>
                                  v == null ? 'Selecione um checkpoint' : null,
                        ),

                        const SizedBox(height: 16),

                        // Loading de jogos
                        if (_loadingJogos)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 8),
                                  Text('Carregando jogos...'),
                                ],
                              ),
                            ),
                          )
                        // Dropdown de jogos
                        else if (_selectedCheckpointId != null &&
                            jogosNaoPontuados.isEmpty)
                          Card(
                            color: Colors.orange[50],
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text(
                                    "Nenhum jogo disponível para este checkpoint",
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_selectedCheckpointId != null)
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Selecione o jogo',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.sports_esports),
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
                            onChanged:
                                (v) => setState(() => _selectedJogoId = v),
                            validator:
                                (v) => v == null ? 'Selecione um jogo' : null,
                          ),

                        const SizedBox(height: 16),

                        // Campo de pontuação
                        if (_selectedJogoId != null)
                          TextFormField(
                            decoration: InputDecoration(
                              labelText:
                                  'Pontuação (0 - ${jogosNaoPontuados.firstWhereOrNull((j) => j['id'] == _selectedJogoId)?['pontuacaoMax'] ?? 100})',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.score),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged:
                                (v) => setState(
                                  () => _pontuacao = int.tryParse(v),
                                ),
                            validator: _validatePontuacao,
                          ),

                        const Spacer(),

                        // Botão de salvar
                        if (_selectedJogoId != null && _pontuacao != null)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 4,
                              ),
                              onPressed: _loading ? null : _savePontuacao,
                              child:
                                  _loading
                                      ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
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
                ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const StaffNavBottom(),
    );
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

      // Carregar dados do usuário
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

      // Detectar checkpoint ativo automaticamente
      await _detectActiveCheckpoint(uid, userData['veiculoId']);

      Get.snackbar(
        'Sucesso',
        'Dados do participante carregados: $nome',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
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
      );

      _resetScanner();
    }
  }

  Future<void> _detectActiveCheckpoint(String uid, String? veiculoId) async {
    if (veiculoId == null) return;

    try {
      // Buscar checkpoint ativo via registros do veículo
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
          // Verificar se tem saída registrada
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
    });

    final selectedCheckpoint = _checkpoints.firstWhereOrNull(
      (c) => c['id'] == checkpointId,
    );

    if (selectedCheckpoint != null) {
      await _loadJogosFromCheckpoint(selectedCheckpoint);
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

  Future<void> _savePontuacao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final uid = _participanteData['uid'];
      if (uid == null || uid.isEmpty) {
        throw Exception('Participante inválido');
      }

      // Salvar pontuação no Firestore
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

      // Mostrar sucesso
      await _showSuccessDialog();

      // Reset para próximo participante
      _resetScanner();
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
            content: const SizedBox(
              height: 120,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 60),
                  SizedBox(height: 16),
                  Text(
                    'Pontuação salva com sucesso!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
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

    _scannerController.start();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }
}
