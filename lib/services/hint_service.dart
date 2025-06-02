

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hint.dart';

/// Serviço responsável pela gestão de pistas (Hints) no Firestore.
class HintService {
  final _collection = FirebaseFirestore.instance.collection('hints');

  /// Retorna todas as pistas armazenadas.
  Future<List<Hint>> getAllHints() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => Hint.fromJson(doc.data())).toList();
  }

  /// Adiciona uma nova pista.
  Future<void> addHint(Hint hint) async {
    await _collection.doc(hint.id).set(hint.toJson());
  }

  /// Atualiza uma pista existente.
  Future<void> updateHint(Hint hint) async {
    await _collection.doc(hint.id).update(hint.toJson());
  }

  /// Remove uma pista pelo seu ID.
  Future<void> deleteHint(String id) async {
    await _collection.doc(id).delete();
  }
}