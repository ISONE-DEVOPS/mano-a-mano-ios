import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mano_mano_dashboard/views/profile/profile_view.dart';

class CustomTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onScanPressed;

  const CustomTopBar({
    super.key,
    required this.title,
    required this.onScanPressed,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.email ?? 'Utilizador';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: 'Opções de utilizador',
            icon: Row(
              children: [
                const Icon(
                  Icons.account_circle,
                  size: 24,
                  color: Colors.black87,
                ),
                const SizedBox(width: 8),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.black54),
              ],
            ),
            onSelected: (value) {
              if (value == 'perfil') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileView()),
                );
              } else if (value == 'logout') {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'perfil',
                    child: Text('Ver Perfil', style: TextStyle(color: Colors.black)),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Text('Logout', style: TextStyle(color: Colors.black)),
                  ),
                ],
          ),
        ],
      ),
    );
  }
}
