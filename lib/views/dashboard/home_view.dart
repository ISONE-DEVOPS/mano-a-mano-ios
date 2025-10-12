import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
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
  String?
  _selectedEventPath; // Full Firestore path of the active event doc (editions/{editionId}/events/{eventId})

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _isOnline = true;
  Future<Map<String, dynamic>>?
  _userDataFuture; // cache para evitar rebuilds infinitos

  @override
  void initState() {
    super.initState();
    _determinePosition();
    // Monitor de conectividade — não bloqueia a UI
    Connectivity().checkConnectivity().then((results) {
      if (!mounted) return;
      setState(() {
        _isOnline = !(results.contains(ConnectivityResult.none));
      });
    });
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(() {
        _isOnline = !(results.contains(ConnectivityResult.none));
      });
    });
    _userDataFuture = _loadUserData();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _loadCheckpointNames() async {
    final String? eventPath = _selectedEventPath;
    if (eventPath == null) {
      // Ainda não temos um evento selecionado (user pode não estar autenticado ou sem inscrição ativa)
      return;
    }
    try {
      final eventRef = FirebaseFirestore.instance.doc(eventPath);
      final snapshot = await eventRef.collection('checkpoints').get();

      final Map<String, String> names = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        names[doc.id] = data['nome'] ?? data['name'] ?? doc.id;
      }

      if (!mounted) return;
      setState(() {
        _checkpointNames = names;
      });
    } catch (e) {
      debugPrint('Erro ao carregar nomes dos checkpoints para $eventPath: $e');
    }
  }

  String _getCheckpointName(String checkpointId) {
    return _checkpointNames[checkpointId] ?? checkpointId;
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child:
            _locationError
                ? _locationErrorWidget()
                : Column(
                  children: [
                    if (!_isOnline)
                      Container(
                        width: double.infinity,
                        color: const Color(0xFFFFF3CD), // amarelo claro
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.wifi_off,
                              size: 16,
                              color: Color(0xFF856404),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sem conexão — tentando carregar quando voltar.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF856404),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: FutureBuilder<Map<String, dynamic>>(
                        future: _userDataFuture,
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
                          final userData =
                              data['userData'] as Map<String, dynamic>?;

                          // Garante que apenas atualizamos o evento selecionado uma vez, evitando blink por rebuild infinito
                          if (eventData != null &&
                              eventData['eventPath'] != null &&
                              _selectedEventPath != eventData['eventPath']) {
                            WidgetsBinding.instance.addPostFrameCallback((
                              _,
                            ) async {
                              if (!mounted) return;
                              setState(() {
                                _selectedEventPath =
                                    eventData['eventPath'] as String;
                              });
                              await _loadCheckpointNames();
                            });
                          }

                          if (eventData == null || uid == null) {
                            return Column(
                              children: [
                                _buildHeader(userName),
                                Expanded(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

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
                                userData,
                                eventData,
                                checkpointDocs,
                                uid,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
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

  Widget _buildHeader(String userName) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sua localização',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _location,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Data: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return <String, dynamic>{};

    // Carrega dados base do utilizador
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? {};
    final userName = userData['nome'] ?? '';

    // 1) Lê todos os eventos em que o user tem registo (passado/presente), guardando os IDs
    final userEventosSnap =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('eventos')
            .get();
    final Set<String> userEventoIds =
        userEventosSnap.docs.map((d) => d.id).toSet();

    if (userEventoIds.isEmpty) {
      // Nenhuma inscrição encontrada
      if (!mounted) {
        // only return data map
      }
      return {
        'userName': userName,
        'userData': userData,
        'eventData': null,
        'uid': uid,
      };
    }

    // 2) Lista os eventos ATIVOS no Firestore (status == true) em todas as edições
    final activeEventsSnap =
        await FirebaseFirestore.instance
            .collectionGroup('events')
            .where('status', isEqualTo: true)
            .get();

    // 3) Encontra o primeiro evento ativo no qual o user esteja inscrito (interseção por eventId)
    DocumentSnapshot? chosenEventDoc;
    String? chosenEditionName;
    for (final doc in activeEventsSnap.docs) {
      final eventId = doc.id;
      if (userEventoIds.contains(eventId)) {
        chosenEventDoc = doc;
        // Recupera a edição a partir do parent da coleção 'events'
        final editionRef = doc.reference.parent.parent;
        if (editionRef != null) {
          final editionSnap = await editionRef.get();
          final editionData = editionSnap.data();
          chosenEditionName = editionData?['nome'] ?? editionRef.id;
        }
        break;
      }
    }

    Map<String, dynamic>? eventData;

    if (chosenEventDoc != null) {
      final event = chosenEventDoc.data() as Map<String, dynamic>;
      final String eventPath =
          chosenEventDoc
              .reference
              .path; // editions/{editionId}/events/{eventId}
      final String eventId = chosenEventDoc.id;

      // Busca dados da equipa e veículo do utilizador (se existirem)
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
          grupo = (equipaData?['grupo'] as String?);
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

      // (Removido setState e _loadCheckpointNames, agora feito no build via addPostFrameCallback)

      eventData = {
        'eventId': eventId,
        'eventName': event['nome'] ?? 'Evento',
        'editionName': chosenEditionName ?? 'Edição',
        'status': event['status'] ?? false,
        'data': event['data'],
        'grupo': grupo,
        'carData': carData,
        'equipaData': equipaData,
        'eventPath': eventPath,
      };
    } else {
      // O user tem eventos registados, mas nenhum deles está ativo neste momento
      eventData = null;
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
    Map<String, dynamic>? userData,
    Map<String, dynamic> eventData,
    List<QueryDocumentSnapshot> checkpointDocs,
    String uid,
  ) {
    // Processar checkpoints
    final Map<String, Map<String, dynamic>> processedCheckpoints = {};
    double tempoTotalMinutos = 0.0;

    for (var doc in checkpointDocs) {
      final checkpointId = doc.id;
      final checkpointData = doc.data() as Map<String, dynamic>;

      // Processar timestamps
      dynamic timestampEntrada = checkpointData['timestampEntrada'];
      dynamic timestampSaida = checkpointData['timestampSaida'];

      DateTime? entradaDate;
      DateTime? saidaDate;

      if (timestampEntrada != null) {
        if (timestampEntrada is Timestamp) {
          entradaDate = timestampEntrada.toDate();
        } else if (timestampEntrada is String) {
          entradaDate = DateTime.tryParse(timestampEntrada);
        }
      }

      if (timestampSaida != null) {
        if (timestampSaida is Timestamp) {
          saidaDate = timestampSaida.toDate();
        } else if (timestampSaida is String) {
          saidaDate = DateTime.tryParse(timestampSaida);
        }
      }

      // Calcular tempo no checkpoint
      if (entradaDate != null && saidaDate != null) {
        final duracao = saidaDate.difference(entradaDate);
        tempoTotalMinutos += duracao.inMinutes;
      }

      processedCheckpoints[checkpointId] = {
        'checkpointId': checkpointId,
        'nome': _getCheckpointName(checkpointId),
        'timestampEntrada': entradaDate,
        'timestampSaida': saidaDate,
        'pontuacaoPergunta': checkpointData['pontuacaoPergunta'] ?? 0,
        'pontuacaoJogo': checkpointData['pontuacaoJogo'] ?? 0,
        'pontuacaoTotal': checkpointData['pontuacaoTotal'] ?? 0,
        'respostaCorreta': checkpointData['respostaCorreta'] ?? false,
      };
    }

    // Calcular estatísticas
    final postosCompletos =
        processedCheckpoints.values
            .where(
              (cp) =>
                  cp['timestampEntrada'] != null &&
                  cp['timestampSaida'] != null,
            )
            .length;

    final perguntasRespondidas =
        processedCheckpoints.values
            .where((cp) => cp['timestampEntrada'] != null)
            .length;

    final perguntasCorretas =
        processedCheckpoints.values
            .where((cp) => cp['respostaCorreta'] == true)
            .length;

    final pontuacaoTotal = processedCheckpoints.values.fold<int>(
      0,
      (total, cp) =>
          total +
          ((cp['pontuacaoTotal'] as int? ?? 0) > 0
              ? (cp['pontuacaoTotal'] as int)
              : ((cp['pontuacaoPergunta'] as int? ?? 0) +
                  (cp['pontuacaoJogo'] as int? ?? 0))),
    );

    final int totalCheckpoints =
        _checkpointNames.isNotEmpty ? _checkpointNames.length : 8;
    final postosRestantes = totalCheckpoints - postosCompletos;
    final taxaAcerto =
        perguntasRespondidas > 0
            ? (perguntasCorretas / perguntasRespondidas * 100)
            : 0.0;

    return Column(
      children: [
        // Header
        _buildHeader(userName),

        // Conteúdo scrollable
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de informações do participante
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${userData?['nome'] ?? userName} - ${eventData['carData']?['distico'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B00),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Modelo:',
                          eventData['carData']?['modelo'] ?? '-',
                        ),
                        _buildInfoRow(
                          'Dístico:',
                          eventData['carData']?['distico'] ?? '-',
                        ),
                        _buildInfoRow('Grupo:', eventData['grupo'] ?? '-'),
                        const Divider(height: 24),
                        _buildInfoRow(
                          'Pontuação Total:',
                          '$pontuacaoTotal',
                          valueColor: const Color(0xFFFF6B00),
                          valueBold: true,
                        ),
                        _buildInfoRow(
                          'Tempo Total:',
                          '${tempoTotalMinutos.toStringAsFixed(1)} min',
                          valueColor: const Color(0xFFFF6B00),
                          valueBold: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // RESUMO
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RESUMO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildProgressBar(
                          'Postos completos: $postosCompletos de $totalCheckpoints',
                          postosCompletos / totalCheckpoints,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Evento: ${eventData['editionName'] ?? ''} — ${eventData['eventName'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Postos restantes: $postosRestantes',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Perguntas acertadas: $perguntasCorretas de $perguntasRespondidas respondidas',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Taxa de acerto: ${taxaAcerto.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Checkpoints
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Checkpoints:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (processedCheckpoints.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Nenhum checkpoint visitado ainda.',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        else
                          ...processedCheckpoints.values.map(
                            (cp) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                '${cp['nome']} - ${cp['timestampSaida'] != null ? 'Completo' : 'Em andamento'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          QrImageView(
                            data: jsonEncode({
                              'uid': uid,
                              'nome': userName,
                              'matricula':
                                  eventData['carData']?['matricula'] ?? '',
                              'grupo': eventData['grupo'] ?? '',
                            }),
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Mostre este código ao staff',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor,
                fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B00)),
          minHeight: 8,
        ),
      ],
    );
  }
}
