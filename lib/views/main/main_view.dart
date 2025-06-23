import 'package:flutter/material.dart';
import 'package:mano_mano_dashboard/views/dashboard/home_view.dart';
import 'package:mano_mano_dashboard/views/checkin/checkin_view.dart';
import 'package:mano_mano_dashboard/views/profile/profile_view.dart';
import 'package:mano_mano_dashboard/services/auth_service.dart';

class MainView extends StatefulWidget {
  final int initialIndex;
  const MainView({super.key, this.initialIndex = 0});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  late int _selectedIndex;
  bool isAdmin = false;

  final List<Widget> _pages = [
    const HomeView(),
    const Center(child: Text('Map View (Em construção)')),
    const CheckinView(),
    const ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    loadUserRole();
  }

  void loadUserRole() async {
    final role = await AuthService().getUserRole();
    setState(() {
      isAdmin = role == 'admin';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isAdmin
          ? _pages[_selectedIndex]
          : const Center(
              child: Text(
                "Acesso restrito ao perfil.",
                style: TextStyle(color: Colors.white),
              ),
            ),
      bottomNavigationBar: isAdmin
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              backgroundColor: const Color(0xFF0E0E2C),
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white54,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.qr_code_scanner),
                  label: 'QR Scan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            )
          : null,
    );
  }
}
