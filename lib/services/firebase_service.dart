import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      // Logging error with developer.log
      developer.log('Login error: $e', name: 'FirebaseService');
      return null;
    }
  }

  // Cadastrar novo usuário com email e senha
  Future<String?> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user?.uid;
    } catch (e) {
      // Logging error with developer.log
      developer.log('Sign up error: $e', name: 'FirebaseService');
      return null;
    }
  }

  // Get stream of cars collection
  Stream<QuerySnapshot> getCarsStream() {
    return _firestore.collection('cars').snapshots();
  }

  Future<void> saveCarData(String uid, Map<String, dynamic> carData) async {
    await _firestore.collection('cars').doc(uid).set(carData);
  }

  // Buscar dados do usuário a partir do UID
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      developer.log(
        'Erro ao buscar dados do usuário: $e',
        name: 'FirebaseService',
      );
      return null;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      developer.log(
        'Erro ao enviar recuperação de senha: $e',
        name: 'FirebaseService',
      );
      return false;
    }
  }

  Future<bool> emailExists(String email) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
