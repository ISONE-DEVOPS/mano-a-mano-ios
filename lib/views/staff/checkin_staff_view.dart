// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import '../../widgets/shared/staff_nav_bottom.dart';

class StaffScoreInputView extends StatefulWidget {
  final Map<String, dynamic> participanteData; // nome, matricula, grupo, uid
  // Removido: final String checkpointId;
  final List<Map<String, dynamic>> jogosDisponiveis; // [{id, nome}]
  final List<String> jogosJaPontuados; // [jogoId]

  const StaffScoreInputView({
    super.key,
    required this.participanteData,
    // Removido: required this.checkpointId,
    required this.jogosDisponiveis,
    required this.jogosJaPontuados,
  });

  @override
  State<StaffScoreInputView> createState() => _StaffScoreInputViewState();
}

class _StaffScoreInputViewState extends State<StaffScoreInputView> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedJogoId;
  int? _pontuacao;
  bool _loading = false;
  String? _selectedCheckpointId;
  List<Map<String, dynamic>> _jogosDisponiveis = [];
  List<Map<String, dynamic>> _checkpoints = [];
  final MobileScannerController _scannerController = MobileScannerController();
  bool _qrLido = false;

  @override
  void initState() {
    super.initState();
    _jogosDisponiveis = widget.jogosDisponiveis;
    // Não inicializa mais _selectedCheckpointId via widget.checkpointId
    fetchCheckpoints().then((checkpoints) {
      setState(() {
        _checkpoints = checkpoints;
      });
      // Não carrega checkpoint inicialmente
    });
  }

  Future<List<Map<String, dynamic>>> fetchCheckpoints() async {
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance
            .collection('editions')
            .doc('shell_2025')
            .collection('events')
            .doc('shell_km_02')
            .collection('checkpoints')
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'nome': data['nome'] ?? '',
        'jogosRefs': data['jogosRefs'] ?? [],
        'jogoRef': data['jogoRef'],
      };
    }).toList();
  }

  Future<void> loadJogosFromCheckpoint(Map<String, dynamic> checkpoint) async {
    List<Map<String, dynamic>> jogos = [];
    try {
      if (checkpoint['jogosRefs'] != null &&
          (checkpoint['jogosRefs'] as List).isNotEmpty) {
        final List<dynamic> refs = checkpoint['jogosRefs'];
        for (var ref in refs) {
          if (ref is DocumentReference) {
            final doc = await ref.get();
            if (doc.exists) {
              final data = doc.data() as Map<String, dynamic>;
              jogos.add({'id': doc.id, 'nome': data['nome'] ?? ''});
            }
          }
        }
      } else if (checkpoint['jogoRef'] != null) {
        final ref = checkpoint['jogoRef'];
        if (ref is DocumentReference) {
          final doc = await ref.get();
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            jogos.add({'id': doc.id, 'nome': data['nome'] ?? ''});
          }
        }
      }
    } catch (_) {
      // ignore errors loading jogos
    }
    setState(() {
      _jogosDisponiveis = jogos;
      _selectedJogoId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar jogos que já foram pontuados
    final jogosNaoPontuados =
        _jogosDisponiveis
            .where((j) => !widget.jogosJaPontuados.contains(j['id']))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Inserir Pontuação')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Scanner
            if (!_qrLido)
              SizedBox(
                height: 280,
                width: double.infinity,
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: (barcodeCapture) async {
                    if (_qrLido) return;
                    final qr = barcodeCapture.barcodes.first.rawValue;
                    if (qr == null) return;

                    try {
                      await _scannerController.stop();
                    } catch (_) {
                      // Stream já parado ou inexistente
                    }
                    if (mounted) {
                      setState(() {
                        _qrLido = true;
                      });
                    }

                    try {
                      final data = jsonDecode(qr);
                      final uid = data['uid'];
                      final nome = data['nome'];

                      setState(() {
                        widget.participanteData['uid'] = uid;
                        widget.participanteData['nome'] = nome;
                      });

                      // Nova lógica: buscar checkpoint ativo do user via veículo
                      final userDoc =
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .get();
                      final veiculoId = userDoc.data()?['veiculoId'];
                      if (veiculoId == null) {
                        throw Exception('Veículo não associado ao utilizador');
                      }
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
                            return dData['posto']?.toString().trim() == posto.toString().trim() &&
                                   dData['tipo'] == 'saida';
                          });

                          if (!saidaRegistrada) {
                            checkpointAtivo = posto.toString().trim();
                            break;
                          }
                        }
                      }

                      if (checkpointAtivo == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Este participante ainda não deu entrada em nenhum checkpoint.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() {
                          _qrLido = false;
                        });
                        return;
                      }

                      setState(() {
                        _selectedCheckpointId = checkpointAtivo;
                      });

                      final selectedCheckpoint = _checkpoints.firstWhereOrNull(
                        (c) => c['id'] == checkpointAtivo,
                      );

                      if (selectedCheckpoint == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Checkpoint ativo não encontrado na lista carregada.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() {
                          _qrLido = false;
                        });
                        return;
                      }

                      await loadJogosFromCheckpoint(selectedCheckpoint);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Dados carregados: $nome'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QR inválido'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      setState(() {
                        _qrLido = false;
                      });
                    }
                  },
                ),
              )
            else
              const SizedBox(height: 1),
            // Botão "Escanear outro participante" abaixo do scanner e antes do formulário
            if (_qrLido) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Escanear outro participante'),
                  onPressed: () {
                    setState(() {
                      _qrLido = false;
                      _selectedCheckpointId = null;
                      _selectedJogoId = null;
                      _jogosDisponiveis = [];
                    });
                    _scannerController.start();
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (_qrLido) ...[
              const SizedBox(height: 16),
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
                          const Icon(Icons.person, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            widget.participanteData['nome'] ?? '',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_checkpoints.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Selecione o checkpoint',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _checkpoints.map((checkpoint) {
                              return DropdownMenuItem<String>(
                                value: checkpoint['id'],
                                child: Text(checkpoint['nome'] ?? 'Sem nome'),
                              );
                            }).toList(),
                        value: _selectedCheckpointId,
                        onChanged: (v) async {
                          setState(() {
                            _selectedCheckpointId = v;
                            _selectedJogoId = null;
                            _jogosDisponiveis = [];
                          });
                          final selectedCheckpoint = _checkpoints
                              .firstWhereOrNull((c) => c['id'] == v);
                          if (selectedCheckpoint == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Checkpoint ativo não encontrado na lista carregada.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setState(() {
                              _qrLido = false;
                            });
                            return;
                          }
                          await loadJogosFromCheckpoint(selectedCheckpoint);
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Selecione um checkpoint';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (jogosNaoPontuados.isEmpty)
                        const Text("Nenhum jogo disponível")
                      else
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Selecione o jogo',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              jogosNaoPontuados.map((jogo) {
                                return DropdownMenuItem<String>(
                                  value: jogo['id'],
                                  child: Text(jogo['nome']),
                                );
                              }).toList(),
                          value: _selectedJogoId,
                          onChanged: (v) {
                            setState(() {
                              _selectedJogoId = v;
                            });
                          },
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Selecione um jogo';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Pontuação',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          setState(() {
                            _pontuacao = int.tryParse(v);
                          });
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Digite a pontuação';
                          }
                          final val = int.tryParse(v);
                          if (val == null) return 'Digite um número válido';
                          if (val < 0) return 'Pontuação não pode ser negativa';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed:
                              _loading
                                  ? null
                                  : () async {
                                    final BuildContext scaffoldContext =
                                        context;
                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }
                                    setState(() {
                                      _loading = true;
                                    });
                                    try {
                                      final uid =
                                          widget.participanteData['uid'];
                                      if (uid == null || uid.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Participante inválido. Por favor escaneie o QR novamente.',
                                            ),
                                          ),
                                        );
                                        setState(() {
                                          _loading = false;
                                        });
                                        return;
                                      }
                                      final docRef = FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(uid)
                                          .collection('eventos')
                                          .doc('shell_km_02')
                                          .collection('pontuacoes')
                                          .doc(_selectedCheckpointId!);
                                      await docRef.update({
                                        'jogoId': _selectedJogoId,
                                        'pontuacaoJogo': _pontuacao,
                                        'pontuacaoTotal': FieldValue.increment(
                                          _pontuacao ?? 0,
                                        ),
                                        'timestampPontuacao':
                                            FieldValue.serverTimestamp(),
                                      });
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          scaffoldContext,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Pontuação salva com sucesso',
                                            ),
                                          ),
                                        );
                                      }
                                      if (!mounted) return;
                                      await showDialog(
                                        context: context,
                                        builder:
                                            (dialogContext) => AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              content: SizedBox(
                                                height: 100,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: const [
                                                    Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                      size: 60,
                                                    ),
                                                    SizedBox(height: 12),
                                                    Text(
                                                      'Pontuação salva com sucesso!',
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(
                                                      dialogContext,
                                                    ).pop();
                                                  },
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                      );
                                      setState(() {
                                        _qrLido = false;
                                        _selectedCheckpointId = null;
                                        _selectedJogoId = null;
                                        _jogosDisponiveis = [];
                                      });
                                      _scannerController.start();
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          scaffoldContext,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Erro ao salvar pontuação',
                                            ),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _loading = false;
                                        });
                                      }
                                    }
                                  },
                          child:
                              _loading
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('Salvar Pontuação'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const StaffNavBottom(),
    );
  }
}
