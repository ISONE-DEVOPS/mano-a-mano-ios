import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _db = FirebaseFirestore.instance;

// Exemplo: criar utilizador condutor
Future<String> criarCondutor(String email, String password, Map<String, dynamic> dadosUser) async {
  final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
  final uid = cred.user!.uid;
  await _db.collection('users').doc(uid).set(dadosUser);
  return uid;
}