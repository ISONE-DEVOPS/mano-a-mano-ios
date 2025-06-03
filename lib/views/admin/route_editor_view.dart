import 'package:mano_mano_dashboard/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Checkpoint {
  final String name;
  final int order;
  final LatLng pos;
  Checkpoint({required this.name, required this.order, required this.pos});
}

/// Tela de edição de percurso para Admin (Flutter Web ou Mobile)
class RouteEditorView extends StatefulWidget {
  final String eventId;
  const RouteEditorView({super.key, required this.eventId});

  @override
  State<RouteEditorView> createState() => _RouteEditorViewState();
}

class _RouteEditorViewState extends State<RouteEditorView> {
  List<LatLng> _percurso = [];
  List<Checkpoint> _checkpoints = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingRoute();
  }

  Future<void> _loadExistingRoute() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .get();
    final data = doc.data() ?? {};
    final percurso = data['percurso'] as List?;
    if (percurso != null) {
      _percurso =
          percurso.map<LatLng>((p) {
            return LatLng(
              (p['lat'] as num).toDouble(),
              (p['lng'] as num).toDouble(),
            );
          }).toList();
    }
    final cps = data['checkpoints'] as List<dynamic>? ?? [];
    _checkpoints =
        cps.map<Checkpoint>((c) {
          return Checkpoint(
            name: c['name'] as String? ?? '',
            order: c['order'] as int? ?? 0,
            pos: LatLng(
              (c['lat'] as num).toDouble(),
              (c['lng'] as num).toDouble(),
            ),
          );
        }).toList();
    setState(() => _loading = false);
  }

  Future<void> _saveRoute() async {
    final percursoData =
        _percurso.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
    final checkpointsData =
        _checkpoints
            .map(
              (cp) => {
                'name': cp.name,
                'order': cp.order,
                'lat': cp.pos.latitude,
                'lng': cp.pos.longitude,
              },
            )
            .toList();
    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .update({'percurso': percursoData, 'checkpoints': checkpointsData});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Percurso e checkpoints salvos com sucesso!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final initialPos =
        _percurso.isNotEmpty
            ? _percurso.first
            : const LatLng(
              16.0000,
              -24.0000,
            ); // Coordenadas centrais de Cabo Verde

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Editor de Percurso', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.save, color: Colors.white), onPressed: _saveRoute),
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            onPressed: () {
              setState(() {
                _percurso.clear();
                _checkpoints.clear();
              });
            },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialPos,
          zoom:
              _percurso.isNotEmpty
                  ? 14
                  : 8, // 8 é um bom zoom para ilhas de Cabo Verde
        ),
        onMapCreated: (_) {},
        onTap: (pos) {
          setState(() => _percurso.add(pos));
        },
        onLongPress: (pos) async {
          final controller = TextEditingController();
          final name = await showDialog<String>(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  title: const Text('Nome do checkpoint'),
                  content: TextField(controller: controller, autofocus: true),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, controller.text),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
          if (name != null && name.isNotEmpty) {
            setState(() {
              // Se o ponto ainda não faz parte do percurso, adiciona ao percurso também
              if (!_percurso.any(
                (p) =>
                    p.latitude == pos.latitude && p.longitude == pos.longitude,
              )) {
                _percurso.add(pos);
              }
              _checkpoints.add(
                Checkpoint(name: name, order: _checkpoints.length, pos: pos),
              );
            });
          }
        },
        markers: {
          // Percurso como marcadores simples (opcional)
          for (var p in _percurso)
            Marker(
              markerId: MarkerId('pt_${_percurso.indexOf(p)}'),
              position: p,
            ),
          // Checkpoints com info e ícone diferenciado
          for (var cp in _checkpoints)
            Marker(
              markerId: MarkerId('cp_${cp.order}'),
              position: cp.pos,
              infoWindow: InfoWindow(title: '${cp.order + 1}. ${cp.name}'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            ),
        },
        polylines: {
          Polyline(
            polylineId: const PolylineId('route'),
            points: _percurso,
            color: Colors.red,
            width: 4,
          ),
        },
      ),
    );
  }
}
