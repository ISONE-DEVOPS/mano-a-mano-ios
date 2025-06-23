import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () async {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        Get.offAllNamed('/login');
        return;
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final role = userDoc.data()?['role'] ?? 'user';

      if (role == 'admin') {
        Get.offAllNamed('/admin');
      } else if (role == 'staff') {
        Get.offAllNamed('/staff');
      } else {
        Get.offAllNamed('/home');
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/Logo_Shell_KM.png', width: 160),
            const SizedBox(height: 20),
            const Text(
              'Mano a Mano - Shell KM',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
