import 'package:flutter/material.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';

class CustomNavigationRail extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<CustomNavigationRail> createState() => _CustomNavigationRailState();
}

class _CustomNavigationRailState extends State<CustomNavigationRail> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _collapsed ? 72 : 220,
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: Center(
              child: Column(
                children: [
                  if (!_collapsed)
                    Image.asset(
                      'assets/images/logo_shell_km.png',
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                  IconButton(
                    icon: Icon(
                      _collapsed ? Icons.chevron_right : Icons.chevron_left,
                    ),
                    onPressed: () {
                      setState(() {
                        _collapsed = !_collapsed;
                      });
                    },
                    tooltip: _collapsed ? 'Expandir menu' : 'Colapsar menu',
                  ),
                ],
              ),
            ),
          ),
          _buildMenuItem(context, Icons.dashboard, 'Dashboard', 0, _collapsed),
          _buildMenuItem(context, Icons.layers, 'Edições', 1, _collapsed),
          _buildMenuItem(context, Icons.qr_code, 'QR Codes', 2, _collapsed),
          _buildMenuItem(context, Icons.quiz, 'Perguntas', 3, _collapsed),
          _buildMenuItem(context, Icons.extension, 'Jogos', 4, _collapsed),
          _buildMenuItem(
            context,
            Icons.flag,
            'Atividades Finais',
            5,
            _collapsed,
          ),
          _buildMenuItem(
            context,
            Icons.bar_chart,
            'Ranking Detalhado',
            6,
            _collapsed,
          ),
          _buildMenuItem(context, Icons.alt_route, 'Percurso', 7, _collapsed),
          _buildMenuItem(context, Icons.people, 'Participantes', 8, _collapsed),
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
                  ? Border(
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
