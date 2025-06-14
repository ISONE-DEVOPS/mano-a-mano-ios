import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../widgets/shared/nav_topbar.dart';
import '../../widgets/shared/nav_bottom.dart';
import '../../theme/app_colors.dart';

class UserEventsView extends StatefulWidget {
  const UserEventsView({super.key});

  @override
  State<UserEventsView> createState() => _UserEventsViewState();
}

class _UserEventsViewState extends State<UserEventsView> {
  late Future<List<Map<String, dynamic>>> _futureEventos;
  String _userName = '';
  String _location = 'Localização indisponível';

  @override
  void initState() {
    super.initState();
    _futureEventos = _loadUserEvents();
    _loadUserData();
    _loadLocation();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final dadosUser = userDoc.data();
      setState(() {
        _userName = dadosUser?['name'] ?? user.email ?? '';
      });
    }
  }

  Future<void> _loadLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low));
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _location = [
            if (place.subAdministrativeArea != null) place.subAdministrativeArea,
            if (place.locality != null) place.locality,
            if (place.country != null) place.country
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        });
      }
    } catch (_) {
      setState(() {
        _location = 'Localização indisponível';
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadUserEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Não está logado, force login
      return Future.error('not_logged_in');
    }

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final dadosUser = userDoc.data();
    if (dadosUser == null) return [];

    // Suporte para múltiplos eventos
    List<dynamic> eventosInscritos = [];
    if (dadosUser['eventosInscritos'] != null) {
      eventosInscritos = List<String>.from(dadosUser['eventosInscritos']);
    } else if (dadosUser['eventoId'] != null) {
      eventosInscritos = [dadosUser['eventoId']];
    }

    if (eventosInscritos.isEmpty) return [];

    final eventsQuery =
        await FirebaseFirestore.instance
            .collection('events')
            .where(FieldPath.documentId, whereIn: eventosInscritos)
            .get();

    return eventsQuery.docs.map((e) => {'id': e.id, ...e.data()}).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(96),
        child: NavTopBar(location: _location, userName: _userName),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureEventos,
        builder: (ctx, snapshot) {
          // Caso usuário não logado
          if (snapshot.hasError && snapshot.error == 'not_logged_in') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/login');
            });
            return const SizedBox.shrink();
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Você não está inscrito em nenhum evento.'),
            );
          }
          final eventos = snapshot.data!;
          return ListView.builder(
            itemCount: eventos.length,
            itemBuilder: (ctx, i) {
              final evento = eventos[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(evento['nome'] ?? 'Evento'),
                  subtitle: Text(
                    evento['data_event'] != null
                        ? (evento['data_event'] as Timestamp)
                            .toDate()
                            .toString()
                        : '',
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamed('/route-map', arguments: evento['id']);
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Ver Percurso'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
