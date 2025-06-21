import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';

class UserTypeProvider with ChangeNotifier {
  final String userType;

  UserTypeProvider(this.userType);
}

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final isStaff = data['tipo'] == 'staff';

        final icons =
            isStaff
                ? [Icons.quiz, Icons.qr_code_scanner, Icons.star, Icons.person]
                : [
                  Icons.home,
                  Icons.event,
                  Icons.qr_code_scanner,
                  Icons.leaderboard,
                  Icons.person,
                ];

        final labels =
            isStaff
                ? ['Jogos', 'Scan QR', 'Pontuação', 'Perfil']
                : ['Home', 'Eventos', 'CheckPoint', 'Ranking', 'Perfil'];

        return Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            border: Border(
              top: BorderSide(color: Colors.white.withAlpha(25), width: 0.5),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              if (isStaff) {
                switch (index) {
                  case 0:
                    Navigator.pushNamed(context, '/jogos');
                    break;
                  case 1:
                    Navigator.pushNamed(context, '/scan-score');
                    break;
                  case 2:
                    Navigator.pushNamed(context, '/pontuacao');
                    break;
                  case 3:
                    Navigator.pushNamed(context, '/perfil');
                    break;
                }
              } else {
                onTap(index);
              }
            },
            backgroundColor: Colors.transparent,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            iconSize: 28,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: List.generate(icons.length, (index) {
              final isSelected = currentIndex == index;

              return BottomNavigationBarItem(
                label: labels[index],
                icon: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration:
                      isSelected
                          ? BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(16),
                          )
                          : null,
                  child: Icon(icons[index]),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
