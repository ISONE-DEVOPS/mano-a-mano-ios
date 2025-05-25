import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firebase_service.dart';
import '../../widgets/shared/nav_bottom.dart';
import '../../widgets/shared/nav_topbar.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  GoogleMapController? _mapController;
  List<LatLng> _percurso = [];
  final int _selectedIndex = 0;
  String _location = '...';
  bool _locationError = false; // To track if location fetching failed
  bool _carsError = false; // To track if fetching cars failed
  final FirebaseService firebaseService = FirebaseService();
  String? _eventoAtivoNome;

  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(16.0, -23.5),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _loadPercurso();
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
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
              .collection('eventos')
              .where('ativo', isEqualTo: true)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final pontos = List.from(data['percurso'] ?? []);
        setState(() {
          _percurso =
              pontos
                  .map(
                    (p) => LatLng(
                      (p['lat'] as num).toDouble(),
                      (p['lng'] as num).toDouble(),
                    ),
                  )
                  .toList();
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
          colors: [Colors.black, Color(0xFF0E0E2C)],
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
              colors: [Colors.black, Color(0xFF0E0E2C)],
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
              colors: [Colors.black, Color(0xFF0E0E2C)],
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
            setState(() {
              _carsError = false;
            });
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Atualizar'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: AppBar(
          backgroundColor: const Color(0xFF0E0E2C),
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
                      return Center(child: Text('Sem conexão com a internet'));
                    }
                    return StreamBuilder<QuerySnapshot>(
                      stream: firebaseService.getCarsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          // Log error and show retry UI
                          FlutterError.reportError(
                            FlutterErrorDetails(
                              exception: snapshot.error!,
                              library: 'Firestore',
                              context: ErrorDescription('Fetching cars stream'),
                            ),
                          );
                          _carsError = true;
                        }

                        if (_carsError) {
                          final userNameFallback =
                              FirebaseAuth.instance.currentUser?.displayName ??
                              '';
                          return _carsErrorWidget(userNameFallback);
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          final userNameFallback =
                              FirebaseAuth.instance.currentUser?.displayName ??
                              '';
                          return _noCarsWidget(userNameFallback);
                        }

                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        final userNameFallback =
                            FirebaseAuth.instance.currentUser?.displayName ??
                            '';
                        final cars =
                            snapshot.data!.docs
                                .where((doc) => doc.id == uid)
                                .toList();

                        if (uid == null || cars.isEmpty) {
                          return _noCarsWidget(userNameFallback);
                        }

                        return FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .get(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final userData =
                                userSnapshot.data?.data()
                                    as Map<String, dynamic>? ??
                                {};
                            final userName = userData['nome'] ?? '';

                            return Column(
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.black, Color(0xFF0E0E2C)],
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
                                    children:
                                        cars.map((car) {
                                          final data =
                                              car.data()
                                                  as Map<String, dynamic>;
                                          // Busca os checkpoints diretamente da subcoleção
                                          return FutureBuilder<QuerySnapshot>(
                                            future:
                                                FirebaseFirestore.instance
                                                    .collection('cars')
                                                    .doc(car.id)
                                                    .collection('checkpoints')
                                                    .get(),
                                            builder: (
                                              context,
                                              checkpointSnapshot,
                                            ) {
                                              if (checkpointSnapshot
                                                      .connectionState ==
                                                  ConnectionState.waiting) {
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              }
                                              final checkpointDocs =
                                                  checkpointSnapshot
                                                      .data
                                                      ?.docs ??
                                                  [];
                                              final Map<
                                                String,
                                                Map<String, dynamic>
                                              >
                                              checkpoints = {
                                                for (var doc in checkpointDocs)
                                                  doc.id: {
                                                    ...(doc.data()
                                                        as Map<
                                                          String,
                                                          dynamic
                                                        >),
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
                                                  checkpoints.entries.toList()
                                                    ..sort(
                                                      (
                                                        a,
                                                        b,
                                                      ) => (b.value['__sort']
                                                              as String)
                                                          .compareTo(
                                                            a.value['__sort']
                                                                as String,
                                                          ),
                                                    );
                                              final visitedCheckpoints =
                                                  checkpoints.entries.where((
                                                    entry,
                                                  ) {
                                                    final cp = entry.value;
                                                    return cp.containsKey(
                                                          'entrada',
                                                        ) ||
                                                        cp.containsKey('saida');
                                                  }).length;
                                              final int totalCheckpoints =
                                                  checkpoints.length;
                                              final double progress =
                                                  totalCheckpoints > 0
                                                      ? (visitedCheckpoints /
                                                              totalCheckpoints)
                                                          .clamp(0.0, 1.0)
                                                      : 0.0;

                                              return Card(
                                                color: Colors.white,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                elevation: 3,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    20,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${(data['nome_condutor'] != null && data['nome_condutor'].toString().trim().isNotEmpty) ? data['nome_condutor'] : userName} - ${data['matricula'] ?? 'Matrícula desconhecida'}',
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(
                                                            0xFF0E0E2C,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      Text(
                                                        'Marca: ${data['marca'] ?? '-'}',
                                                      ),
                                                      Text(
                                                        'Modelo: ${data['modelo'] ?? '-'}',
                                                      ),
                                                      if (_eventoAtivoNome !=
                                                          null)
                                                        Text(
                                                          'Evento: $_eventoAtivoNome',
                                                        ),
                                                      Text(
                                                        'Pontuação Total: ${data['pontuacao_total'] ?? 0}',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const Divider(height: 24),
                                                      const Text(
                                                        'RESUMO',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Postos visitados: $visitedCheckpoints de $totalCheckpoints',
                                                      ),
                                                      const SizedBox(height: 8),
                                                      LinearProgressIndicator(
                                                        value: progress,
                                                        backgroundColor:
                                                            Colors
                                                                .grey
                                                                .shade300,
                                                        color:
                                                            Colors.blueAccent,
                                                        minHeight: 8,
                                                      ),
                                                      const Divider(height: 24),
                                                      const Text(
                                                        'Checkpoints:',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      if (checkpoints
                                                          .isNotEmpty)
                                                        ...(() {
                                                          Map<
                                                            String,
                                                            List<
                                                              MapEntry<
                                                                String,
                                                                Map<
                                                                  String,
                                                                  dynamic
                                                                >
                                                              >
                                                            >
                                                          >
                                                          agrupadoPorData = {};

                                                          for (var entry
                                                              in sortedEntries) {
                                                            final cp = Map<
                                                              String,
                                                              dynamic
                                                            >.from(
                                                              entry.value
                                                                  as Map,
                                                            );
                                                            final rawData =
                                                                cp['ultima_leitura']
                                                                    as String?;
                                                            String
                                                            dataFormatada =
                                                                'Data desconhecida';

                                                            if (rawData !=
                                                                null) {
                                                              final data =
                                                                  DateTime.tryParse(
                                                                    rawData,
                                                                  );
                                                              if (data !=
                                                                  null) {
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

                                                          return agrupadoPorData
                                                              .entries
                                                              .map<Widget>(
                                                                (
                                                                  grupo,
                                                                ) => Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    const Divider(
                                                                      height:
                                                                          24,
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsets.only(
                                                                        bottom:
                                                                            8,
                                                                      ),
                                                                      child: Text(
                                                                        grupo
                                                                            .key,
                                                                        style: const TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              14,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    ...grupo.value.map((
                                                                      entry,
                                                                    ) {
                                                                      final posto =
                                                                          entry
                                                                              .key;
                                                                      final cp =
                                                                          entry
                                                                              .value;
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
                                                                        padding: const EdgeInsets.only(
                                                                          top:
                                                                              4,
                                                                        ),
                                                                        child: Row(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Icon(
                                                                              entrada !=
                                                                                          '-' &&
                                                                                      saida !=
                                                                                          '-'
                                                                                  ? Icons.check_circle
                                                                                  : (entrada !=
                                                                                          '-'
                                                                                      ? Icons.login
                                                                                      : Icons.logout),
                                                                              size:
                                                                                  18,
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
                                                                              width:
                                                                                  6,
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
                                              );
                                            },
                                          );
                                        }).toList(),
                                  ),
                                ),
                                // Título acima do mapa
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'Percurso do Evento',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: SizedBox(
                                    height: 160,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                              child:
                                                  (_percurso.length >= 2)
                                                      ? GoogleMap(
                                                          initialCameraPosition:
                                                              _initialCameraPosition,
                                                          mapType: MapType.normal,
                                                          onMapCreated: (GoogleMapController controller) {
                                                            _mapController = controller;
                                                            if (_percurso.length >= 2) {
                                                              double minLat = _percurso.first.latitude;
                                                              double maxLat = _percurso.first.latitude;
                                                              double minLng = _percurso.first.longitude;
                                                              double maxLng = _percurso.first.longitude;
                                                              for (final p in _percurso) {
                                                                if (p.latitude < minLat) minLat = p.latitude;
                                                                if (p.latitude > maxLat) maxLat = p.latitude;
                                                                if (p.longitude < minLng) minLng = p.longitude;
                                                                if (p.longitude > maxLng) maxLng = p.longitude;
                                                              }
                                                              final bounds = LatLngBounds(
                                                                southwest: LatLng(minLat, minLng),
                                                                northeast: LatLng(maxLat, maxLng),
                                                              );
                                                              Future.delayed(const Duration(milliseconds: 100), () {
                                                                controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                                                              });
                                                            }
                                                          },
                                                          zoomControlsEnabled: false,
                                                          markers: {
                                                            Marker(
                                                              markerId: const MarkerId(
                                                                'inicio',
                                                              ),
                                                              position: _percurso.first,
                                                              infoWindow:
                                                                  const InfoWindow(
                                                                    title: 'Início',
                                                                  ),
                                                            ),
                                                            Marker(
                                                              markerId: const MarkerId(
                                                                'fim',
                                                              ),
                                                              position: _percurso.last,
                                                              infoWindow:
                                                                  const InfoWindow(
                                                                    title: 'Fim',
                                                                  ),
                                                            ),
                                                          },
                                                          polylines: {
                                                            Polyline(
                                                              polylineId:
                                                                  const PolylineId(
                                                                    'percurso',
                                                                  ),
                                                              points: _percurso,
                                                              color: Colors.blue,
                                                              width: 4,
                                                            ),
                                                          },
                                                        )
                                                      : Container(
                                                          color: Colors.white,
                                                          child: const Center(
                                                            child: Text(
                                                              'Percurso não disponível',
                                                              style: TextStyle(
                                                                color: Colors.black54,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                    ),
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'recenter',
            backgroundColor: const Color(0xFF0E0E2C),
            onPressed: () {
              if (_mapController != null && _percurso.length >= 2) {
                double minLat = _percurso.first.latitude;
                double maxLat = _percurso.first.latitude;
                double minLng = _percurso.first.longitude;
                double maxLng = _percurso.first.longitude;
                for (final p in _percurso) {
                  if (p.latitude < minLat) minLat = p.latitude;
                  if (p.latitude > maxLat) maxLat = p.latitude;
                  if (p.longitude < minLng) minLng = p.longitude;
                  if (p.longitude > maxLng) maxLng = p.longitude;
                }
                final bounds = LatLngBounds(
                  southwest: LatLng(minLat, minLng),
                  northeast: LatLng(maxLat, maxLng),
                );
                _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
              }
            },
            tooltip: 'Centralizar percurso',
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'maps',
            backgroundColor: Colors.blueAccent,
            onPressed: () {
              if (_percurso.isNotEmpty) {
                final destino = _percurso.last;
                final url =
                    'https://www.google.com/maps/dir/?api=1&destination=${destino.latitude},${destino.longitude}&travelmode=driving';
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            },
            tooltip: 'Abrir no Google Maps',
            child: const Icon(Icons.navigation),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _selectedIndex),
    );
  }
}
