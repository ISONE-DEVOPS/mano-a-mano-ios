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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8,
                ),
                child: Center(
                  child: Column(
                    children: [
                      if (!isCollapsed)
                        Image.asset(
                          'assets/images/logo_shell_km.png',
                          height: 50,
                          fit: BoxFit.contain,
                        ),
                    ],
                  ),
                ),
              ),
              _buildMenuItem(
                context,
                Icons.dashboard,
                'Dashboard',
                0,
                isCollapsed,
              ),
              _buildMenuItem(context, Icons.layers, 'Edições', 1, isCollapsed),
              _buildMenuItem(
                context,
                Icons.qr_code,
                'QR Codes',
                2,
                isCollapsed,
              ),
              _buildMenuItem(context, Icons.quiz, 'Perguntas', 3, isCollapsed),
              // _buildMenuItem(context, Icons.extension, 'Jogos', 4, isCollapsed),
              // _buildMenuItem(
              //   context,
              //   Icons.flag,
              //   'Atividades Finais',
              //   5,
              //   isCollapsed,
              // ),
              _buildMenuItem(
                context,
                Icons.bar_chart,
                'Ranking Detalhado',
                4,
                isCollapsed,
              ),
              // _buildMenuItem(
              //   context,
              //   Icons.alt_route,
              //   'Percurso',
              //   7,
              //   isCollapsed,
              // ),
              _buildMenuItem(
                context,
                Icons.people,
                'Participantes',
                5,
                isCollapsed,
              ),
            ],
          ),
        );
      },
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

    return InkWell(
      onTap: () {
        widget.onItemSelected(index);
      },
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
          border:
              isSelected
                  ? const Border(
                    left: BorderSide(color: AppColors.secondary, width: 4),
                  )
                  : null,
        ),
        child: Row(
          mainAxisAlignment:
              collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Tooltip(
              message: label,
              child: Icon(
                icon,
                color: isSelected ? AppColors.secondary : Colors.grey,
              ),
            ),
            if (!collapsed) ...[
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
