import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mano_mano_dashboard/widgets/shared/staff_app_bar.dart';

class StaffHomeView extends StatefulWidget {
  const StaffHomeView({super.key});

  @override
  State<StaffHomeView> createState() => _StaffHomeViewState();
}

class _StaffHomeViewState extends State<StaffHomeView> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'QR Code',
      'route': '/staff/checkin',
      'icon': Icons.qr_code_scanner,
    },
    {'title': 'Jogos', 'route': '/staff/jogos', 'icon': Icons.videogame_asset},
    {
      'title': 'Pontuação',
      'route': '/staff/ver_pontuacao',
      'icon': Icons.leaderboard,
    },
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Get.toNamed(_pages[index]['route']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StaffAppBar(title: _pages[_selectedIndex]['title']),
      body: Center(child: Text('Selecione uma opção no menu abaixo.')),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items:
            _pages
                .map(
                  (page) => BottomNavigationBarItem(
                    icon: Icon(page['icon']),
                    label: page['title'],
                  ),
                )
                .toList(),
      ),
    );
  }
}
