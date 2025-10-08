import 'package:flutter/material.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';

class CustomNavigationRail extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;

  const CustomNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isCollapsed,
  });

  @override
  State<CustomNavigationRail> createState() => _CustomNavigationRailState();
}

class _CustomNavigationRailState extends State<CustomNavigationRail> {
  // Lista de itens do menu principal (atualizada conforme solicitado)
  final List<NavigationItem> _menuItems = [
    NavigationItem(Icons.dashboard, 'Dashboard', 0),
    NavigationItem(Icons.layers, 'Edições', 1),
    NavigationItem(Icons.qr_code, 'QR Codes', 2),
    NavigationItem(Icons.quiz, 'Perguntas', 3),
    NavigationItem(Icons.extension, 'Jogos', 4),
    NavigationItem(Icons.manage_accounts, 'Utilizadores', 5),
    NavigationItem(Icons.groups, 'Participantes', 6),
    NavigationItem(Icons.event_available, 'Participantes por Evento', 7),
    NavigationItem(Icons.leaderboard, 'Ranking', 8),
    NavigationItem(Icons.logout, 'Logout', 9),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCollapsed = widget.isCollapsed;
        return Container(
          width: isCollapsed ? 72 : 220,
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com logo
              _buildHeader(isCollapsed),

              // Menu items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];
                    return _buildMenuItem(
                      context,
                      item.icon,
                      item.label,
                      item.index,
                      isCollapsed,
                    );
                  },
                ),
              ),

              // Footer (opcional)
              if (!isCollapsed) _buildFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCollapsed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
      child: Center(
        child: Column(
          children: [
            if (!isCollapsed) ...[
              Image.asset(
                'assets/images/logo_shell_km.png',
                height: 50,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                'Mano a Mano',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ] else ...[
              Icon(Icons.menu, color: Colors.grey[700], size: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.secondary,
            child: const Icon(Icons.person, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Sistema',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    bool collapsed,
  ) {
    final isSelected = widget.selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: () {
          widget.onItemSelected(index);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 0 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.secondary.withAlpha(25)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border:
                isSelected
                    ? Border.all(
                      color: AppColors.secondary.withAlpha(50),
                      width: 1,
                    )
                    : null,
          ),
          child: Row(
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Tooltip(
                message: collapsed ? label : '',
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.secondary : Colors.grey[600],
                  size: 20,
                ),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color:
                          isSelected ? AppColors.secondary : Colors.grey[700],
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Classe auxiliar para organizar os itens do menu
class NavigationItem {
  final IconData icon;
  final String label;
  final int index;

  NavigationItem(this.icon, this.label, this.index);
}
