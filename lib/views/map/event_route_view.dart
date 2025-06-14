import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/shared/nav_topbar.dart';
import '../../widgets/shared/nav_bottom.dart';

class EventRouteView extends StatefulWidget {
  const EventRouteView({super.key});

  @override
  State<EventRouteView> createState() => _EventRouteViewState();
}

class _EventRouteViewState extends State<EventRouteView> {
  List<DocumentSnapshot> _eventosDoUser = [];
  String? _selectedEventId;
  List<LatLng> _percurso = [];
  Map<String, dynamic> _checkpoints = {};
  bool _loading = true;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _carregarEventosDoUser();
  }

  Future<void> _carregarEventosDoUser() async {
    setState(() => _loading = true);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    // Supondo que userDoc.data()?['eventos'] seja uma lista de IDs dos eventos do user
    List<String> ids = [];
    if (userDoc.data()?['eventos'] != null) {
      ids = List<String>.from(userDoc.data()?['eventos']);
    } else if (userDoc.data()?['eventoId'] != null) {
      // Caso use só um evento por user
      ids = [userDoc.data()?['eventoId']];
    }
    if (ids.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    // Busca todos eventos
    final snap =
        await FirebaseFirestore.instance
            .collection('events')
            .where(FieldPath.documentId, whereIn: ids)
            .get();
    setState(() {
      _eventosDoUser = snap.docs;
      _loading = false;
    });
  }

  Future<void> _loadPercurso(String eventId) async {
    setState(() {
      _percurso = [];
      _checkpoints = {};
      _selectedEventId = eventId;
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
          percurso.map<LatLng>((p) {
            if (p is Map) {
              // Caso salvo como {lat, lng}
              return LatLng(
                (p['lat'] as num).toDouble(),
                (p['lng'] as num).toDouble(),
              );
            } else if (p is GeoPoint) {
              // Caso salvo como GeoPoint
              return LatLng(p.latitude, p.longitude);
            }
            throw Exception('Formato inválido de percurso');
          }).toList();
    }
    _checkpoints = data['checkpoints'] as Map<String, dynamic>? ?? {};
    setState(() {});
    if (_mapController != null && _percurso.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateToBounds();
      });
    }
  }

  void _animateToBounds() {
    if (_percurso.isEmpty) return;
    LatLngBounds bounds;
    if (_percurso.length == 1) {
      final point = _percurso.first;
      bounds = LatLngBounds(southwest: point, northeast: point);
    } else {
      double south = _percurso.first.latitude;
      double north = _percurso.first.latitude;
      double west = _percurso.first.longitude;
      double east = _percurso.first.longitude;
      for (var point in _percurso) {
        if (point.latitude < south) south = point.latitude;
        if (point.latitude > north) north = point.latitude;
        if (point.longitude < west) west = point.longitude;
        if (point.longitude > east) east = point.longitude;
      }
      bounds = LatLngBounds(
          southwest: LatLng(south, west), northeast: LatLng(north, east));
    }
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    List<MapEntry<String, dynamic>> sortedEntries = _checkpoints.entries
        .where((e) => e.value is Map)
        .toList()
      ..sort((a, b) {
        final aCodigo = (a.value['codigo'] as num?) ?? 0;
        final bCodigo = (b.value['codigo'] as num?) ?? 0;
        return aCodigo.compareTo(bCodigo);
      });

    final markerList = sortedEntries.map((entry) {
      final cp = entry.value as Map<String, dynamic>;
      final nome = cp['name'] ?? entry.key;
      final codigo = cp['codigo'] ?? 0;
      final lat = cp['lat'];
      final lng = cp['lng'];

      final isStart = codigo == 1;
      final isEnd = codigo == _checkpoints.length;

      return Marker(
        markerId: MarkerId(entry.key),
        position: LatLng((lat as num).toDouble(), (lng as num).toDouble()),
        infoWindow: InfoWindow(title: 'P$codigo - $nome'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isStart
              ? BitmapDescriptor.hueGreen
              : isEnd
                  ? BitmapDescriptor.hueRed
                  : BitmapDescriptor.hueAzure,
        ),
      );
    }).toSet();

    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: NavTopBar(
            userName: FirebaseAuth.instance.currentUser?.displayName ?? '',
            location:
                _selectedEventId == null
                    ? ''
                    : (_eventosDoUser.firstWhere(
                          (e) => e.id == _selectedEventId,
                          orElse: () => _eventosDoUser.first,
                        )['nome'] ??
                        ''),
          ),
        ),
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _eventosDoUser.isEmpty
                ? const Center(
                  child: Text('Nenhum evento encontrado para você.'),
                )
                : Column(
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: DropdownButton<String>(
                        hint: const Text('Selecione o evento'),
                        value: _selectedEventId,
                        isExpanded: true,
                        items:
                            _eventosDoUser
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.id,
                                    child: Text(e['nome'] ?? e.id),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _loadPercurso(value);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child:
                          _selectedEventId == null
                              ? const Center(
                                child: Text('Selecione um evento.'),
                              )
                              : (_percurso.isEmpty
                                  ? const Center(
                                    child: Text(
                                      'Este evento ainda não possui percurso definido.',
                                    ),
                                  )
                                  : GoogleMap(
                                    onMapCreated: (controller) {
                                      _mapController = controller;
                                      _animateToBounds();
                                    },
                                    initialCameraPosition: CameraPosition(
                                      target:
                                          _percurso.isNotEmpty
                                              ? _percurso.first
                                              : const LatLng(16.0, -24.0),
                                      zoom: _percurso.isNotEmpty ? 14 : 8,
                                    ),
                                    polylines: {
                                      Polyline(
                                        polylineId: const PolylineId('route'),
                                        points: _percurso,
                                        color: Colors.red,
                                        width: 4,
                                      ),
                                    },
                                    markers: markerList,
                                  )),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.green, size: 16),
                              SizedBox(width: 4),
                              Text('Início', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.red, size: 16),
                              SizedBox(width: 4),
                              Text('Fim', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.blueAccent, size: 16),
                              SizedBox(width: 4),
                              Text('Intermediário', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      ),
    );
  }
}
