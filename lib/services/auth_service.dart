import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> logout() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
  }

  Future<String> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return 'user';

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['role'] ?? 'user';
  }
}
