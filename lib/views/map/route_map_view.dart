import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class RouteMapView extends StatefulWidget {
  final String eventId;
  const RouteMapView({super.key, required this.eventId});

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  String? _selectedEventId;
  List<LatLng> _percurso = [];
  Map<String, dynamic> _checkpoints = {};
  bool _loading = true;
  List<Map<String, dynamic>> _events = [];
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadUserEvent();
  }

  Future<void> _loadEvents() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('events').get();

    final events =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return {'id': doc.id, 'name': data['nome'] ?? 'Evento sem nome'};
        }).toList();

    setState(() {
      _events = events;
      if (_selectedEventId == null && events.isNotEmpty) {
        _selectedEventId = events.first['id'];
        _loadData(_selectedEventId!);
      }
    });
  }

  Future<void> _loadUserEvent() async {
    setState(() => _loading = true);

    String eventoId = widget.eventId;

    if (eventoId.isEmpty) {
      final snapshot =
          await FirebaseFirestore.instance.collection('events').limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        eventoId = snapshot.docs.first.id;
      } else {
        setState(() => _loading = false);
        return;
      }
    }

    _selectedEventId = eventoId;
    await _loadData(eventoId);
    setState(() => _loading = false);
  }

  Future<void> _loadData(String eventId) async {
    setState(() {
      _percurso = [];
      _checkpoints = {};
    });
    final doc =
        await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .get();
    final data = doc.data() ?? {};

    final percurso = data['percurso'] as List?;
    if (percurso != null) {
      _percurso =
          percurso
              .map<LatLng>(
                (p) => LatLng(
                  (p['lat'] as num).toDouble(),
                  (p['lng'] as num).toDouble(),
                ),
              )
              .toList();
    }
    _checkpoints = data['checkpoints'] as Map<String, dynamic>? ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Percurso do Evento'),
        backgroundColor: const Color(0xFF0E0E2C),
        foregroundColor: Colors.white,
      ),
      body: Builder(
        builder: (context) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_selectedEventId == null) {
            return const Center(
              child: Text('Você não está inscrito em nenhum evento.'),
            );
          }

          return Column(
            children: [
              Card(
                elevation: 2,
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButton<String>(
                        value: _selectedEventId,
                        hint: const Text('Selecione um evento'),
                        isExpanded: true,
                        items:
                            _events.map<DropdownMenuItem<String>>((event) {
                              return DropdownMenuItem<String>(
                                value: event['id'],
                                child: Text(event['name']),
                              );
                            }).toList(),
                        onChanged: (value) async {
                          if (value == null) return;
                          setState(() {
                            _selectedEventId = value;
                            _loading = true;
                          });
                          await _loadData(value);
                          setState(() => _loading = false);
                        },
                      ),
                      if (_events.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            (_events.firstWhere(
                                  (e) => e['id'] == _selectedEventId,
                                  orElse: () => {'name': ''},
                                )['name']
                                as String),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child:
                      _percurso.isEmpty
                          ? const Center(
                            child: Text(
                              'Este evento não possui percurso configurado.',
                              style: TextStyle(color: Colors.black54),
                            ),
                          )
                          : GoogleMap(
                            initialCameraPosition: const CameraPosition(
                              target: LatLng(16.0, -23.5),
                              zoom: 14,
                            ),
                            onMapCreated: (controller) {
                              _mapController = controller;
                              if (_percurso.length >= 2) {
                                final bounds = LatLngBounds(
                                  southwest: _percurso.reduce(
                                    (a, b) => LatLng(
                                      a.latitude < b.latitude
                                          ? a.latitude
                                          : b.latitude,
                                      a.longitude < b.longitude
                                          ? a.longitude
                                          : b.longitude,
                                    ),
                                  ),
                                  northeast: _percurso.reduce(
                                    (a, b) => LatLng(
                                      a.latitude > b.latitude
                                          ? a.latitude
                                          : b.latitude,
                                      a.longitude > b.longitude
                                          ? a.longitude
                                          : b.longitude,
                                    ),
                                  ),
                                );
                                controller.animateCamera(
                                  CameraUpdate.newLatLngBounds(bounds, 60),
                                );
                              }
                            },
                            polylines: {
                              for (int i = 0; i < _percurso.length - 1; i++)
                                Polyline(
                                  polylineId: PolylineId('segment_$i'),
                                  points: [_percurso[i], _percurso[i + 1]],
                                  color:
                                      i % 2 == 0 ? Colors.red : Colors.orange,
                                  width: 5,
                                ),
                            },
                            // Refatoração para garantir Set<Marker> correto
                            markers:
                                (() {
                                  final sortedEntries =
                                      _checkpoints.entries
                                          .where((e) => e.value is Map)
                                          .toList()
                                        ..sort((a, b) {
                                          final aCodigo =
                                              (a.value['codigo'] as num?) ?? 0;
                                          final bCodigo =
                                              (b.value['codigo'] as num?) ?? 0;
                                          return aCodigo.compareTo(bCodigo);
                                        });
                                  final markerList =
                                      sortedEntries.map((entry) {
                                        final cp =
                                            entry.value as Map<String, dynamic>;
                                        final nome = cp['name'] ?? entry.key;
                                        final codigo = cp['codigo'] ?? 0;
                                        final lat = cp['lat'];
                                        final lng = cp['lng'];

                                        final isStart = codigo == 1;
                                        final isEnd =
                                            codigo == _checkpoints.length;

                                        return Marker(
                                          markerId: MarkerId(entry.key),
                                          position: LatLng(
                                            (lat as num).toDouble(),
                                            (lng as num).toDouble(),
                                          ),
                                          infoWindow: InfoWindow(
                                            title: 'P$codigo - $nome',
                                          ),
                                          icon:
                                              BitmapDescriptor.defaultMarkerWithHue(
                                                isStart
                                                    ? BitmapDescriptor.hueGreen
                                                    : isEnd
                                                    ? BitmapDescriptor.hueRed
                                                    : BitmapDescriptor.hueAzure,
                                              ),
                                        );
                                      }).toSet();
                                  return markerList;
                                })(),
                          ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Início', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red),
                        SizedBox(width: 4),
                        Text('Fim', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.blueAccent),
                        SizedBox(width: 4),
                        Text('Intermediário', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
                final bounds = LatLngBounds(
                  southwest: _percurso.reduce(
                    (a, b) => LatLng(
                      a.latitude < b.latitude ? a.latitude : b.latitude,
                      a.longitude < b.longitude ? a.longitude : b.longitude,
                    ),
                  ),
                  northeast: _percurso.reduce(
                    (a, b) => LatLng(
                      a.latitude > b.latitude ? a.latitude : b.latitude,
                      a.longitude > b.longitude ? a.longitude : b.longitude,
                    ),
                  ),
                );
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngBounds(bounds, 60),
                );
              }
            },
            tooltip: 'Centralizar percurso',
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'abrirmapa',
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
      // bottomNavigationBar: BottomNavBar(currentIndex: 1),
    );
  }
}
