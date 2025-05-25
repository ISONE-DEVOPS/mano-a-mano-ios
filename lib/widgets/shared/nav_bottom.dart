import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.home,
      Icons.event,
      Icons.qr_code_scanner,
      Icons.person,
    ];
    final routes = ['/home', '/my-events', '/checkin', '/profile'];
    final labels = ['Home', 'Eventos', 'CheckPoint', 'Perfil'];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E2C),
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        // Evita empilhamento de rotas e navegação desnecessária
        onTap: (index) {
          if (index == currentIndex) return;
          final user = FirebaseAuth.instance.currentUser;
          if (index != 0 && user == null) {
            Navigator.of(context).pushReplacementNamed('/login');
            return;
          }
          Navigator.of(context).pushReplacementNamed(routes[index]);
        },
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        iconSize: 28,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: List.generate(4, (index) {
          final isSelected = currentIndex == index;

          return BottomNavigationBarItem(
            label: labels[index],
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration:
                  isSelected
                      ? BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(16),
                      )
                      : null,
              child: Icon(icons[index]),
            ),
          );
        }),
      ),
    );
  }
}
