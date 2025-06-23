import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'dart:convert';
import '../../services/firebase_service.dart';
import '../../widgets/shared/nav_bottom.dart';
import '../../widgets/shared/nav_topbar.dart';
import '../../theme/app_colors.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final int _selectedIndex = 0;
  String _location = '...';
  bool _locationError = false;
  final FirebaseService firebaseService = FirebaseService();
  String? _eventoAtivoNome;
  Map<String, String> _checkpointNames = {}; // Cache para nomes dos checkpoints

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _loadPercurso();
    _loadCheckpointNames();
  }

  // Carrega os nomes dos checkpoints
  Future<void> _loadCheckpointNames() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('editions')
              .doc('shell_2025')
              .collection('events')
              .doc('shell_km_02')
              .collection('checkpoints')
              .get();

      final Map<String, String> names = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        names[doc.id] = data['nome'] ?? data['name'] ?? doc.id;
      }

      setState(() {
        _checkpointNames = names;
      });
    } catch (e) {
      debugPrint('Erro ao carregar nomes dos checkpoints: $e');
    }
  }

  // Função para obter o nome do checkpoint
  String _getCheckpointName(String checkpointId) {
    return _checkpointNames[checkpointId] ?? checkpointId;
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final List<ConnectivityResult> results =
          await Connectivity().checkConnectivity();
      if (results.contains(ConnectivityResult.none)) return false;

      final lookup = await InternetAddress.lookup('google.com');
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadPercurso() async {
    if (!await _hasInternetConnection()) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: Exception('Sem conexão com a internet.'),
          library: 'Conectividade',
          context: ErrorDescription('Carregando percurso do evento'),
        ),
      );
      return;
    }
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('editions')
              .doc('shell_2025')
              .collection('events')
              .where('ativo', isEqualTo: true)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          _eventoAtivoNome = data['nome'] ?? 'Evento Ativo';
        });
      }
    } catch (e) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          library: 'Firestore',
          context: ErrorDescription('Carregando percurso do evento'),
        ),
      );
    }
  }

  void _logInfo(String message) {
    // Logger implementation
  }

  void _determinePosition() async {
    try {
      final location = Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          if (!mounted) return;
          setState(() {
            _locationError = true;
          });
          return;
        }
      }

      PermissionStatus permission = await location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await location.requestPermission();
        if (permission == PermissionStatus.denied ||
            permission == PermissionStatus.deniedForever) {
          if (!mounted) return;
          setState(() {
            _locationError = true;
          });
          return;
        }
      }

      final currentLocation = await location.getLocation();
      String locationName =
          '${currentLocation.latitude?.toStringAsFixed(4)}, ${currentLocation.longitude?.toStringAsFixed(4)}';

      try {
        final placemarks = await placemarkFromCoordinates(
          currentLocation.latitude ?? 0,
          currentLocation.longitude ?? 0,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          String? locality =
              place.locality ??
              place.subAdministrativeArea ??
              place.administrativeArea;
          String? country = place.country;
          if (locality != null && locality.isNotEmpty) {
            locationName =
                country != null && country.isNotEmpty
                    ? '$locality, $country'
                    : locality;
          } else if (country != null && country.isNotEmpty) {
            locationName = country;
          } else {
            locationName = 'Localização indisponível';
          }
        }
      } catch (e) {
        locationName = 'Localização indisponível';
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: e,
            library: 'Geocoding',
            context: ErrorDescription('Obtaining location name'),
          ),
        );
      }

      _logInfo('Local obtido: $locationName');

      if (!mounted) return;
      setState(() {
        _location = locationName;
        _locationError = false;
      });
    } catch (e, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: stack,
          library: 'Location',
          context: ErrorDescription('Determining position'),
        ),
      );
      if (!mounted) return;
      setState(() {
        _locationError = true;
      });
    }
  }

  Widget _locationErrorWidget() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: NavTopBar(
              location: 'Localização indisponível',
              userName: '',
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _locationError = false;
                _location = '...';
              });
              _determinePosition();
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              'Tentar Novamente',
              style: TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noCarsWidget(String userName) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: NavTopBar(location: _location, userName: userName),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Center(child: Text('Nenhum carro registado.')),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Registrar carro'),
        ),
      ],
    );
  }

  Widget _carsErrorWidget(String userName) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: NavTopBar(location: _location, userName: userName),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Center(child: Text('Erro ao carregar os carros.')),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {});
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Atualizar'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Usuário não autenticado')),
          );
        }

        return _buildHomeContent(context);
      },
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_locationError)
                _locationErrorWidget()
              else
                FutureBuilder<bool>(
                  future: _hasInternetConnection(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data == false) {
                      return const Center(
                        child: Text('Sem conexão com a internet'),
                      );
                    }
                    return FutureBuilder<Map<String, dynamic>>(
                      future:
                          (() async {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid == null) return <String, dynamic>{};
                            final userDoc =
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .get();
                            final userData = userDoc.data() ?? {};
                            final userName = userData['nome'] ?? '';
                            final veiculoId = userData['veiculoId'];
                            final equipaId = userData['equipaId'];
                            String? grupo;
                            if (equipaId != null &&
                                equipaId.toString().isNotEmpty) {
                              final equipaDoc =
                                  await FirebaseFirestore.instance
                                      .collection('equipas')
                                      .doc(equipaId)
                                      .get();
                              if (equipaDoc.exists) {
                                grupo = equipaDoc.data()?['grupo'];
                              }
                            }
                            if (veiculoId == null ||
                                veiculoId.toString().isEmpty) {
                              return {
                                'userName': userName,
                                'userData': userData,
                                'carData': null,
                                'carId': null,
                                'grupo': grupo,
                                'uid': uid,
                              };
                            }
                            final carDoc =
                                await FirebaseFirestore.instance
                                    .collection('veiculos')
                                    .doc(veiculoId)
                                    .get();
                            final carData =
                                carDoc.exists ? carDoc.data() : null;
                            return {
                              'userName': userName,
                              'userData': userData,
                              'carData': carData,
                              'carId': veiculoId,
                              'grupo': grupo,
                              'uid': uid,
                            };
                          })(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          const userNameFallback = '';
                          return _carsErrorWidget(userNameFallback);
                        }
                        final data = snapshot.data ?? {};
                        final userName = data['userName'] ?? '';
                        final carData =
                            data['carData'] as Map<String, dynamic>?;
                        final carId = data['carId'] as String?;
                        final uid = data['uid'] as String?;

                        if (carData == null || carId == null || uid == null) {
                          return _noCarsWidget(userName);
                        }

                        // CORREÇÃO: Buscar pontuações do usuário, não checkpoints do veículo
                        return FutureBuilder<QuerySnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('eventos')
                                  .doc('shell_2025')
                                  .collection('pontuacoes')
                                  .get(),
                          builder: (context, checkpointSnapshot) {
                            if (checkpointSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final checkpointDocs =
                                checkpointSnapshot.data?.docs ?? [];

                            // Processar dados dos checkpoints
                            final Map<String, Map<String, dynamic>>
                            processedCheckpoints = {};

                            for (var doc in checkpointDocs) {
                              final checkpointId = doc.id;
                              final checkpointData =
                                  doc.data() as Map<String, dynamic>;

                              // Processar timestamp de entrada e saída
                              dynamic timestampEntrada =
                                  checkpointData['timestampEntrada'];
                              dynamic timestampSaida =
                                  checkpointData['timestampSaida'];

                              // Converter Timestamp para String se necessário
                              String? entradaString;
                              String? saidaString;

                              if (timestampEntrada != null) {
                                if (timestampEntrada is Timestamp) {
                                  entradaString =
                                      timestampEntrada
                                          .toDate()
                                          .toIso8601String();
                                } else if (timestampEntrada is String) {
                                  entradaString = timestampEntrada;
                                }
                              }

                              if (timestampSaida != null) {
                                if (timestampSaida is Timestamp) {
                                  saidaString =
                                      timestampSaida.toDate().toIso8601String();
                                } else if (timestampSaida is String) {
                                  saidaString = timestampSaida;
                                }
                              }

                              processedCheckpoints[checkpointId] = {
                                'checkpointId': checkpointId,
                                'nome': _getCheckpointName(checkpointId),
                                'timestampEntrada': entradaString,
                                'timestampSaida': saidaString,
                                'pontuacaoPergunta':
                                    checkpointData['pontuacaoPergunta'] ?? 0,
                                'pontuacaoJogo':
                                    checkpointData['pontuacaoJogo'] ?? 0,
                                'pontuacaoTotal':
                                    checkpointData['pontuacaoTotal'] ?? 0,
                                'respostaCorreta':
                                    checkpointData['respostaCorreta'] ?? false,
                              };
                            }

                            // Ordenar por data de entrada (mais recente primeiro)
                            final sortedEntries =
                                processedCheckpoints.entries.toList()..sort((
                                  a,
                                  b,
                                ) {
                                  final aTime =
                                      a.value['timestampEntrada'] as String? ??
                                      '';
                                  final bTime =
                                      b.value['timestampEntrada'] as String? ??
                                      '';
                                  return bTime.compareTo(aTime);
                                });

                            // Calcular postos completos (com entrada E saída)
                            final visitedCheckpoints =
                                processedCheckpoints.values
                                    .where(
                                      (cp) =>
                                          cp['timestampEntrada'] != null &&
                                          cp['timestampEntrada']
                                              .toString()
                                              .isNotEmpty &&
                                          cp['timestampSaida'] != null &&
                                          cp['timestampSaida']
                                              .toString()
                                              .isNotEmpty,
                                    )
                                    .length;

                            final int totalCheckpoints =
                                8; // ou obter do Firestore
                            final double progress =
                                totalCheckpoints > 0
                                    ? (visitedCheckpoints / totalCheckpoints)
                                        .clamp(0.0, 1.0)
                                    : 0.0;

                            // Calcular pontuação total
                            final pontuacaoTotal = processedCheckpoints.values
                                .fold<int>(
                                  0,
                                  (sum, cp) =>
                                      sum + (cp['pontuacaoTotal'] as int? ?? 0),
                                );

                            return Column(
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: NavTopBar(
                                          location: _location,
                                          userName: userName,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Column(
                                    children: [
                                      Card(
                                        color: AppColors.background,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${(carData['nome_condutor'] != null && carData['nome_condutor'].toString().trim().isNotEmpty) ? carData['nome_condutor'] : userName} - ${carData['matricula'] ?? 'Matrícula desconhecida'}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Modelo: ${carData['modelo'] ?? '-'}',
                                              ),
                                              Text(
                                                'Dístico: ${carData['distico'] ?? '-'}',
                                              ),
                                              Text(
                                                'Grupo: ${data['grupo'] ?? '-'}',
                                              ),
                                              if (_eventoAtivoNome != null)
                                                Text(
                                                  'Evento: $_eventoAtivoNome',
                                                ),
                                              Text(
                                                'Pontuação Total: $pontuacaoTotal',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Divider(height: 24),
                                              const Text(
                                                'RESUMO',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Postos completos: $visitedCheckpoints de $totalCheckpoints',
                                              ),
                                              const SizedBox(height: 8),
                                              LinearProgressIndicator(
                                                value: progress,
                                                backgroundColor: Colors.white
                                                    .withAlpha(61),
                                                color:
                                                    progress >= 1.0
                                                        ? Colors.green
                                                        : (progress >= 0.5
                                                            ? Colors.orange
                                                            : Colors.red),
                                                minHeight: 8,
                                              ),
                                              Text(
                                                'Postos restantes: ${totalCheckpoints - visitedCheckpoints}',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              const Divider(height: 24),
                                              const Text(
                                                'Checkpoints:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              if (processedCheckpoints
                                                  .isNotEmpty)
                                                ...(() {
                                                  // Agrupar por data
                                                  Map<
                                                    String,
                                                    List<
                                                      MapEntry<
                                                        String,
                                                        Map<String, dynamic>
                                                      >
                                                    >
                                                  >
                                                  agrupadoPorData = {};

                                                  for (var entry
                                                      in sortedEntries) {
                                                    final cp = entry.value;
                                                    final rawData =
                                                        cp['timestampEntrada']
                                                            as String?;
                                                    String dataFormatada =
                                                        'Data desconhecida';

                                                    if (rawData != null &&
                                                        rawData.isNotEmpty) {
                                                      final data =
                                                          DateTime.tryParse(
                                                            rawData,
                                                          );
                                                      if (data != null) {
                                                        dataFormatada =
                                                            '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
                                                      }
                                                    }

                                                    agrupadoPorData
                                                        .putIfAbsent(
                                                          dataFormatada,
                                                          () => [],
                                                        )
                                                        .add(entry);
                                                  }

                                                  return agrupadoPorData.entries
                                                      .map<Widget>(
                                                        (grupo) => Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            const Divider(
                                                              height: 24,
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    bottom: 8,
                                                                  ),
                                                              child: Text(
                                                                grupo.key,
                                                                style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            ),
                                                            ...grupo.value.map((
                                                              entry,
                                                            ) {
                                                              final cp =
                                                                  entry.value;
                                                              final nomeCheckpoint =
                                                                  cp['nome'] ??
                                                                  entry.key;
                                                              final entrada =
                                                                  cp['timestampEntrada'];
                                                              final saida =
                                                                  cp['timestampSaida'];
                                                              final pontuacaoTotal =
                                                                  cp['pontuacaoTotal'] ??
                                                                  0;

                                                              // Formatação de horários
                                                              String
                                                              entradaFormatada =
                                                                  '-';
                                                              String
                                                              saidaFormatada =
                                                                  '-';

                                                              if (entrada !=
                                                                      null &&
                                                                  entrada
                                                                      is String &&
                                                                  entrada
                                                                      .isNotEmpty) {
                                                                final dataEntrada =
                                                                    DateTime.tryParse(
                                                                      entrada,
                                                                    );
                                                                if (dataEntrada !=
                                                                    null) {
                                                                  entradaFormatada =
                                                                      '${dataEntrada.hour.toString().padLeft(2, '0')}:${dataEntrada.minute.toString().padLeft(2, '0')}';
                                                                }
                                                              }

                                                              if (saida !=
                                                                      null &&
                                                                  saida
                                                                      is String &&
                                                                  saida
                                                                      .isNotEmpty) {
                                                                final dataSaida =
                                                                    DateTime.tryParse(
                                                                      saida,
                                                                    );
                                                                if (dataSaida !=
                                                                    null) {
                                                                  saidaFormatada =
                                                                      '${dataSaida.hour.toString().padLeft(2, '0')}:${dataSaida.minute.toString().padLeft(2, '0')}';
                                                                }
                                                              }

                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets.only(
                                                                      top: 4,
                                                                    ),
                                                                child: Row(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Icon(
                                                                      entrada !=
                                                                                  null &&
                                                                              entrada.toString().isNotEmpty &&
                                                                              saida !=
                                                                                  null &&
                                                                              saida.toString().isNotEmpty
                                                                          ? Icons
                                                                              .check_circle
                                                                          : (entrada !=
                                                                                      null &&
                                                                                  entrada.toString().isNotEmpty
                                                                              ? Icons.login
                                                                              : Icons.radio_button_unchecked),
                                                                      size: 18,
                                                                      color:
                                                                          entrada !=
                                                                                      null &&
                                                                                  entrada.toString().isNotEmpty &&
                                                                                  saida !=
                                                                                      null &&
                                                                                  saida.toString().isNotEmpty
                                                                              ? Colors.green
                                                                              : (entrada !=
                                                                                          null &&
                                                                                      entrada.toString().isNotEmpty
                                                                                  ? Colors.orange
                                                                                  : Colors.grey),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    Expanded(
                                                                      child: Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Text(
                                                                            nomeCheckpoint,
                                                                            style: const TextStyle(
                                                                              fontWeight:
                                                                                  FontWeight.w600,
                                                                              fontSize:
                                                                                  14,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                            height:
                                                                                2,
                                                                          ),
                                                                          Text(
                                                                            'Entrada: $entradaFormatada | Saída: $saidaFormatada',
                                                                            style: TextStyle(
                                                                              fontSize:
                                                                                  12,
                                                                              color:
                                                                                  Colors.grey[600],
                                                                            ),
                                                                          ),
                                                                          if (pontuacaoTotal >
                                                                              0)
                                                                            Text(
                                                                              'Pontos: $pontuacaoTotal',
                                                                              style: const TextStyle(
                                                                                fontSize:
                                                                                    12,
                                                                                color:
                                                                                    Colors.green,
                                                                                fontWeight:
                                                                                    FontWeight.w600,
                                                                              ),
                                                                            ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }),
                                                          ],
                                                        ),
                                                      )
                                                      .toList();
                                                })()
                                              else
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 8,
                                                  ),
                                                  child: Text(
                                                    'Nenhum checkpoint visitado ainda.',
                                                    style: TextStyle(
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // QR Code
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: QrImageView(
                                    data: jsonEncode({
                                      'uid': uid,
                                      'nome': userName,
                                      'matricula': carData['matricula'] ?? '',
                                      'grupo': data['grupo'] ?? '',
                                    }),
                                    version: QrVersions.auto,
                                    size: 200.0,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index != _selectedIndex) {
            Navigator.pushReplacementNamed(
              context,
              [
                '/home',
                '/my-events',
                '/checkin',
                '/ranking',
                '/profile',
              ][index],
            );
          }
        },
      ),
    );
  }
}
