import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
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
  bool _locationError = false; // To track if location fetching failed
  final FirebaseService firebaseService = FirebaseService();
  String? _eventoAtivoNome;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _loadPercurso();
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
          // _percurso =
          //     pontos
          //         .map(
          //           (p) => LatLng(
          //             (p['lat'] as num).toDouble(),
          //             (p['lng'] as num).toDouble(),
          //           ),
          //         )
          //         .toList();
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

  // Helper method to log info messages (replace with Logger if available)
  void _logInfo(String message) {
    // final logger = Logger();
    // logger.i(message);
    // If logger package is not used, comment above and use print or nothing
    // print(message);
  }

  void _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locationError = true;
        });
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: Exception('Location services are disabled.'),
            library: 'Location',
            context: ErrorDescription('Determining position'),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _locationError = true;
          });
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: Exception('Location permissions are denied.'),
              library: 'Location',
              context: ErrorDescription('Determining position'),
            ),
          );
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      String locationName =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          // Try locality, subAdministrativeArea, administrativeArea, country
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
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: e,
            library: 'Geocoding',
            context: ErrorDescription('Obtaining location name'),
          ),
        );
        locationName = 'Localização indisponível';
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

  // Widget to display when location fails, with retry button
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

  // Widget to display when no cars are registered, with register button
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
          onPressed: () {
            // Example visual only, no action implemented
          },
          icon: const Icon(Icons.add),
          label: const Text('Registrar carro'),
        ),
      ],
    );
  }

  // Widget to display error fetching cars, with retry button
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
          // Usuário não autenticado
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
                    // Novo FutureBuilder para buscar user e car por veiculoId
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
                            if (veiculoId == null ||
                                veiculoId.toString().isEmpty) {
                              return {
                                'userName': userName,
                                'userData': userData,
                                'carData': null,
                                'carId': null,
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
                          final userNameFallback = '';
                          return _carsErrorWidget(userNameFallback);
                        }
                        final data = snapshot.data ?? {};
                        final userName = data['userName'] ?? '';
                        final carData =
                            data['carData'] as Map<String, dynamic>?;
                        final carId = data['carId'] as String?;
                        if (carData == null || carId == null) {
                          return _noCarsWidget(userName);
                        }
                        // Widget principal com dados do carro
                        return FutureBuilder<QuerySnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('veiculos')
                                  .doc(carId)
                                  .collection('checkpoints')
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
                            final Map<String, Map<String, dynamic>>
                            checkpoints = {
                              for (var doc in checkpointDocs)
                                doc.id: {
                                  ...(doc.data() as Map<String, dynamic>),
                                  '__sort':
                                      (doc.data()
                                          as Map<
                                            String,
                                            dynamic
                                          >)['ultima_leitura'] ??
                                      '',
                                },
                            };
                            final sortedEntries =
                                checkpoints.entries.toList()..sort(
                                  (a, b) => (b.value['__sort'] as String)
                                      .compareTo(a.value['__sort'] as String),
                                );
                            final visitedCheckpoints =
                                checkpoints.entries.where((entry) {
                                  final cp = entry.value;
                                  return cp.containsKey('entrada') ||
                                      cp.containsKey('saida');
                                }).length;
                            final int totalCheckpoints = checkpoints.length;
                            final double progress =
                                totalCheckpoints > 0
                                    ? (visitedCheckpoints / totalCheckpoints)
                                        .clamp(0.0, 1.0)
                                    : 0.0;
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
                                              // Text('Marca: ${carData['marca'] ?? '-'}'),
                                              Text(
                                                'Modelo: ${carData['modelo'] ?? '-'}',
                                              ),
                                              Text(
                                                'Dístico: ${carData['distico'] ?? '-'}',
                                              ),
                                              if (_eventoAtivoNome != null)
                                                Text(
                                                  'Evento: $_eventoAtivoNome',
                                                ),
                                              Text(
                                                'Pontuação Total: ${carData['pontuacao_total'] ?? 0}',
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
                                                'Postos visitados: $visitedCheckpoints de $totalCheckpoints',
                                              ),
                                              const SizedBox(height: 8),
                                              LinearProgressIndicator(
                                                value: progress,
                                                backgroundColor: Colors.white
                                                    .withAlpha(61),
                                                color: AppColors.secondaryDark,
                                                minHeight: 8,
                                              ),
                                              const Divider(height: 24),
                                              const Text(
                                                'Checkpoints:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              if (checkpoints.isNotEmpty)
                                                ...(() {
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
                                                    final cp = Map<
                                                      String,
                                                      dynamic
                                                    >.from(entry.value as Map);
                                                    final rawData =
                                                        cp['ultima_leitura']
                                                            as String?;
                                                    String dataFormatada =
                                                        'Data desconhecida';
                                                    if (rawData != null) {
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
                                                        .add(
                                                          MapEntry(
                                                            entry.key,
                                                            cp,
                                                          ),
                                                        );
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
                                                              final posto =
                                                                  entry.key;
                                                              final cp =
                                                                  entry.value;
                                                              final entrada =
                                                                  cp['entrada'] ??
                                                                  '-';
                                                              final saida =
                                                                  cp['saida'] ??
                                                                  '-';
                                                              final ultimaLeitura =
                                                                  cp['ultima_leitura'];
                                                              String
                                                              ultimaFormatada =
                                                                  '';
                                                              if (ultimaLeitura !=
                                                                      null &&
                                                                  ultimaLeitura
                                                                      is String) {
                                                                final data =
                                                                    DateTime.tryParse(
                                                                      ultimaLeitura,
                                                                    );
                                                                if (data !=
                                                                    null) {
                                                                  ultimaFormatada =
                                                                      '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
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
                                                                                  '-' &&
                                                                              saida !=
                                                                                  '-'
                                                                          ? Icons
                                                                              .check_circle
                                                                          : (entrada !=
                                                                                  '-'
                                                                              ? Icons.login
                                                                              : Icons.logout),
                                                                      size: 18,
                                                                      color:
                                                                          entrada !=
                                                                                      '-' &&
                                                                                  saida !=
                                                                                      '-'
                                                                              ? Colors.green
                                                                              : (entrada !=
                                                                                      '-'
                                                                                  ? Colors.orange
                                                                                  : Colors.red),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    Expanded(
                                                                      child: Text(
                                                                        '$posto → Entrada: $entrada | Saída: $saida${ultimaFormatada.isNotEmpty ? ' | Hora: $ultimaFormatada' : ''}',
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
                                                })(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Substituição: Exibe QR Code com UID e nome do usuário autenticado
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: QrImageView(
                                    data:
                                        'UID: ${FirebaseAuth.instance.currentUser?.uid ?? ''}\nNome: ${userName ?? ''}',
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
      // floatingActionButton removido conforme solicitado.
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          // Atualize conforme necessário
          if (index != _selectedIndex) {
            Navigator.pushReplacementNamed(context, [
              '/home',
              '/my-events',
              '/checkin',
              '/ranking',
              '/profile',
            ][index]);
          }
        },
      ),
    );
  }
}
