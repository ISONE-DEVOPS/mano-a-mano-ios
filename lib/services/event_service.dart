// lib/services/event_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_config.dart';

class EventService extends ChangeNotifier {
  EventService._();
  static final EventService instance = EventService._();

  EventConfig? _current;
  EventConfig? get current => _current;

  final _db = FirebaseFirestore.instance;
  StreamSubscription? _sub;

  /// Carrega o evento ativo (isActive == true).
  Future<void> loadActiveEvent() async {
    await _sub?.cancel();
    final snap =
        await _db
            .collection('events')
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

    if (snap.docs.isEmpty) {
      _current = null;
      notifyListeners();
      return;
    }

    final doc = snap.docs.first;
    _current = EventConfig.fromMap(doc.id, doc.data());
    notifyListeners();

    // escuta alterações em tempo real (ativação/edição via admin)
    _sub = doc.reference.snapshots().listen((d) {
      if (d.exists) {
        _current = EventConfig.fromMap(d.id, d.data()!);
        notifyListeners();
      }
    });
  }

  /// Permite trocar manualmente (ex.: admin switch)
  Future<void> setActiveEvent(String eventId) async {
    // desativa todos e ativa um
    final batch = _db.batch();
    final all = await _db.collection('events').get();
    for (final d in all.docs) {
      batch.update(d.reference, {'isActive': d.id == eventId});
    }
    await batch.commit();
    await loadActiveEvent();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
