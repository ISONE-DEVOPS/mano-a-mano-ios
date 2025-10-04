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
  Map<String, String> _checkpointNames = {};

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _loadCheckpointNames();
  }

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
      }

      if (!mounted) return;
      setState(() {
        _location = locationName;
        _locationError = false;
      });
    } catch (e, stack) {
      debugPrint('Erro ao determinar posição: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _locationError = true;
      });
    }
  }

  Widget _locationErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary,
          ],
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
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            label: Text(
              'Tentar Novamente',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
        ),
      ),
      body: SafeArea(
        child:
            _locationError
                ? _locationErrorWidget()
                : FutureBuilder<bool>(
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
                      future: _loadUserData(),
                      builder: (context, dataSnapshot) {
                        if (dataSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (dataSnapshot.hasError) {
                          return const Center(
                            child: Text('Erro ao carregar dados'),
                          );
                        }

                        final data = dataSnapshot.data ?? {};
                        final userName = data['userName'] ?? '';
                        final eventData = data['eventData'];
                        final uid = data['uid'] as String?;

                        // Se não há evento inscrito
                        if (eventData == null || uid == null) {
                          return Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.primary,
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
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.event_busy,
                                        size: 80,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'Não está inscrito em nenhum evento',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Inscreva-se num evento para participar',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        // Carrega pontuações do evento
                        return FutureBuilder<QuerySnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('eventos')
                                  .doc(eventData['eventId'])
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

                            return _buildEventDashboard(
                              context,
                              userName,
                              eventData,
                              checkpointDocs,
                              uid,
                            );
                          },
                        );
                      },
                    );
                  },
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

  Future<Map<String, dynamic>> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return <String, dynamic>{};

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final userData = userDoc.data() ?? {};
    final userName = userData['nome'] ?? '';

    // Verifica se o usuário está inscrito em algum evento
    final eventosSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('eventos')
            .where('inscrito', isEqualTo: true)
            .limit(1)
            .get();

    Map<String, dynamic>? eventData;

    if (eventosSnapshot.docs.isNotEmpty) {
      final eventoDoc = eventosSnapshot.docs.first;
      final eventoId = eventoDoc.id;

      // Busca dados completos do evento
      final editionSnapshot =
          await FirebaseFirestore.instance
              .collection('editions')
              .doc('shell_2025')
              .get();

      final eventSnapshot =
          await FirebaseFirestore.instance
              .collection('editions')
              .doc('shell_2025')
              .collection('events')
              .doc(eventoId)
              .get();

      if (eventSnapshot.exists) {
        final event = eventSnapshot.data()!;
        final edition = editionSnapshot.data() ?? {};

        // Busca dados da equipa e veículo
        String? grupo;
        Map<String, dynamic>? carData;
        Map<String, dynamic>? equipaData;

        if (userData['equipaId'] != null) {
          final equipaDoc =
              await FirebaseFirestore.instance
                  .collection('equipas')
                  .doc(userData['equipaId'])
                  .get();
          if (equipaDoc.exists) {
            equipaData = equipaDoc.data();
            grupo = equipaData?['grupo'];
          }
        }

        if (userData['veiculoId'] != null) {
          final carDoc =
              await FirebaseFirestore.instance
                  .collection('veiculos')
                  .doc(userData['veiculoId'])
                  .get();
          if (carDoc.exists) {
            carData = carDoc.data();
          }
        }

        eventData = {
          'eventId': eventoId,
          'eventName': event['nome'] ?? 'Shell ao Km',
          'editionName': edition['nome'] ?? '2ª Edição',
          'status': event['status'] ?? false,
          'data': event['data'],
          'grupo': grupo,
          'carData': carData,
          'equipaData': equipaData,
        };
      }
    }

    return {
      'userName': userName,
      'userData': userData,
      'eventData': eventData,
      'uid': uid,
    };
  }

  Widget _buildEventDashboard(
    BuildContext context,
    String userName,
    Map<String, dynamic> eventData,
    List<QueryDocumentSnapshot> checkpointDocs,
    String uid,
  ) {
    // Processar checkpoints
    final Map<String, Map<String, dynamic>> processedCheckpoints = {};

    for (var doc in checkpointDocs) {
      final checkpointId = doc.id;
      final checkpointData = doc.data() as Map<String, dynamic>;

      // Processar timestamps
      dynamic timestampEntrada = checkpointData['timestampEntrada'];
      dynamic timestampSaida = checkpointData['timestampSaida'];

      String? entradaString;
      String? saidaString;

      if (timestampEntrada != null) {
        if (timestampEntrada is Timestamp) {
          entradaString = timestampEntrada.toDate().toIso8601String();
        } else if (timestampEntrada is String) {
          entradaString = timestampEntrada;
        }
      }

      if (timestampSaida != null) {
        if (timestampSaida is Timestamp) {
          saidaString = timestampSaida.toDate().toIso8601String();
        } else if (timestampSaida is String) {
          saidaString = timestampSaida;
        }
      }

      processedCheckpoints[checkpointId] = {
        'checkpointId': checkpointId,
        'nome': _getCheckpointName(checkpointId),
        'timestampEntrada': entradaString,
        'timestampSaida': saidaString,
        'pontuacaoPergunta': checkpointData['pontuacaoPergunta'] ?? 0,
        'pontuacaoJogo': checkpointData['pontuacaoJogo'] ?? 0,
        'pontuacaoTotal': checkpointData['pontuacaoTotal'] ?? 0,
        'respostaCorreta': checkpointData['respostaCorreta'] ?? false,
      };
    }

    // Calcular estatísticas
    final visitedCheckpoints =
        processedCheckpoints.values
            .where(
              (cp) =>
                  cp['timestampEntrada'] != null &&
                  cp['timestampEntrada'].toString().isNotEmpty &&
                  cp['timestampSaida'] != null &&
                  cp['timestampSaida'].toString().isNotEmpty,
            )
            .length;

    // final perguntasCorretas =
    //     processedCheckpoints.values
    //         .where((cp) => cp['respostaCorreta'] == true)
    //         .length;

    final pontuacaoTotal = processedCheckpoints.values.fold<int>(
      0,
      (total, cp) =>
          total +
          ((cp['pontuacaoTotal'] as int? ?? 0) > 0
              ? (cp['pontuacaoTotal'] as int)
              : ((cp['pontuacaoPergunta'] as int? ?? 0) +
                  (cp['pontuacaoJogo'] as int? ?? 0))),
    );

    final int totalCheckpoints = 8;

    return Expanded(
      child: Column(
        children: [
          // Header com dados do usuário
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary,
                ],
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

          // Conteúdo scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Card do Evento
                  Card(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        eventData['eventName'],
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                      ),
                                      Text(
                                        eventData['editionName'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.70),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        eventData['status'] == true
                                            ? Colors.green
                                            : Colors.orange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    eventData['status'] == true
                                        ? 'ATIVO'
                                        : 'AGUARDANDO',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Divider(height: 24),

                            // Informações da Equipa e Veículo
                            if (eventData['equipaData'] != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.groups,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Equipa: ${eventData['equipaData']['nome'] ?? '-'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Grupo ${eventData['grupo'] ?? '-'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],

                            if (eventData['carData'] != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_car,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${eventData['carData']['modelo'] ?? '-'} • ${eventData['carData']['matricula'] ?? '-'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.confirmation_number,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Dístico: ${eventData['carData']['distico'] ?? '-'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Card de Progresso
                  Card(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'PROGRESSO DO EVENTO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '$pontuacaoTotal pts',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Postos Visitados
                          _buildProgressItem(
                            context,
                            icon: Icons.location_on,
                            title: 'Postos Completos',
                            value: '$visitedCheckpoints / $totalCheckpoints',
                            progress:
                                totalCheckpoints > 0
                                    ? (visitedCheckpoints / totalCheckpoints)
                                    : 0.0,
                            color: Colors.blue,
                          ),

                          const SizedBox(height: 16),

                          /*
                          // Perguntas Acertadas
                          _buildProgressItem(
                            context,
                            icon: Icons.check_circle,
                            title: 'Perguntas Acertadas',
                            value:
                                '$perguntasCorretas / ${processedCheckpoints.values.where((cp) => cp['timestampEntrada'] != null).length}',
                            progress:
                                processedCheckpoints.values
                                        .where(
                                          (cp) =>
                                              cp['timestampEntrada'] != null,
                                        )
                                        .isNotEmpty
                                    ? (perguntasCorretas /
                                        processedCheckpoints.values
                                            .where(
                                              (cp) =>
                                                  cp['timestampEntrada'] !=
                                                  null,
                                            )
                                            .length)
                                    : 0.0,
                            color: Colors.green,
                          ),
                          */
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // QR Code para Check-in
                  Card(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'QR CODE PARA CHECK-IN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: QrImageView(
                              data: jsonEncode({
                                'uid': uid,
                                'nome': userName,
                                'matricula':
                                    eventData['carData']?['matricula'] ?? '',
                                'grupo': eventData['grupo'] ?? '',
                              }),
                              version: QrVersions.auto,
                              size: 180.0,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Mostre este código ao staff',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.60),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lista de Checkpoints Visitados
                  Card(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CHECKPOINTS VISITADOS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (processedCheckpoints.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.explore_off,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Nenhum checkpoint visitado ainda',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...processedCheckpoints.values.map(
                              (cp) => _buildCheckpointItem(context, cp),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withValues(alpha: 0.2),
          color: color,
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildCheckpointItem(
    BuildContext context,
    Map<String, dynamic> checkpoint,
  ) {
    final bool completo =
        checkpoint['timestampEntrada'] != null &&
        checkpoint['timestampSaida'] != null;
    final bool emAndamento =
        checkpoint['timestampEntrada'] != null &&
        checkpoint['timestampSaida'] == null;

    String statusText = 'Não visitado';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.radio_button_unchecked;

    if (completo) {
      statusText = 'Completo';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (emAndamento) {
      statusText = 'Em andamento';
      statusColor = Colors.orange;
      statusIcon = Icons.access_time;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(12),
        color: statusColor.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkpoint['nome'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(fontSize: 12, color: statusColor),
                ),
              ],
            ),
          ),
          if (checkpoint['pontuacaoTotal'] != null &&
              (checkpoint['pontuacaoTotal'] as int) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${checkpoint['pontuacaoTotal']} pts',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
