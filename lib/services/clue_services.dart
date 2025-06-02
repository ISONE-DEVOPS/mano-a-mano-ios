import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/clue.dart';

/// Serviço de gestão de pistas (conchas) no Firestore.
class ClueService {
  final _collection = FirebaseFirestore.instance.collection('clues');

  Future<List<Clue>> getAllClues() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => Clue.fromJson(doc.data())).toList();
  }

  Future<void> addClue(Clue clue) async {
    await _collection.doc(clue.id).set(clue.toJson());
  }

  Future<void> updateClue(Clue clue) async {
    await _collection.doc(clue.id).update(clue.toJson());
  }

  Future<void> deleteClue(String id) async {
    await _collection.doc(id).delete();
  }
}