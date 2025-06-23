import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StaffNavBottom extends StatelessWidget {
  const StaffNavBottom({super.key});

  int _getCurrentIndex() {
    final route = Get.currentRoute;
    if (route == '/staff/jogos') return 0;
    if (route == '/scan-score') return 1;
    if (route == '/staff/perfil') return 2;
    return 0;
  }

  void _onTap(int index) {
    switch (index) {
      case 0:
        Get.offAllNamed('/staff/jogos');
        break;
      case 1:
        Get.offAllNamed('/scan-score');
        break;
      case 2:
        Get.offAllNamed('/staff/perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _getCurrentIndex(),
      onTap: _onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.videogame_asset),
          label: 'Jogos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'QR Code',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}
