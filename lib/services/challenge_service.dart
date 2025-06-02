import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge.dart';

/// Serviço responsável pela leitura e escrita dos desafios no Firestore.
class ChallengeService {
  final _collection = FirebaseFirestore.instance.collection('challenges');

  Future<List<Challenge>> getAllChallenges() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => Challenge.fromJson(doc.data())).toList();
  }

  Future<void> addChallenge(Challenge challenge) async {
    await _collection.doc(challenge.id).set(challenge.toJson());
  }

  Future<void> updateChallenge(Challenge challenge) async {
    await _collection.doc(challenge.id).update(challenge.toJson());
  }

  Future<void> deleteChallenge(String id) async {
    await _collection.doc(id).delete();
  }
}
