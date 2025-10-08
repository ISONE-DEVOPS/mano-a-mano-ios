import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mano_mano_dashboard/views/admin/create_user_view.dart';
import 'participantes_view.dart';
import 'dashboard_admin_view.dart';
import 'edition_view.dart';
import 'generate_qr_view.dart';
import 'perguntas_view.dart' as perguntas_view;
import 'jogos_create_view.dart';
import 'ranking_detailed_view.dart';
import 'participantes_por_evento_view.dart';
import 'package:mano_mano_dashboard/theme/app_backend_theme.dart';

void showAddEventDialog(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final localController = TextEditingController();
  final priceController = TextEditingController();
  DateTime? selectedDate;
  bool status = true;

  showDialog(
    context: context,
    builder:
        (_) => StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E2E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF74C0FC).withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.event_note,
                        color: Color(0xFF74C0FC),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Novo Evento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTextField(
                          controller: nameController,
                          label: 'Título',
                          icon: Icons.title,
                          validator:
                              (v) =>
                                  v == null || v.isEmpty
                                      ? 'Informe o título'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: localController,
                          label: 'Local',
                          icon: Icons.location_on,
                          validator:
                              (v) =>
                                  v == null || v.isEmpty
                                      ? 'Informe o local'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: priceController,
                          label: 'Preço',
                          icon: Icons.euro,
                          keyboardType: TextInputType.number,
                          validator:
                              (v) =>
                                  v == null || v.isEmpty
                                      ? 'Informe o preço'
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF313244),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF45475A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.schedule,
                                color: Color(0xFF74C0FC),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Data e Hora:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                    builder: (context, child) {
                                      return Theme(
                                        data: ThemeData.dark().copyWith(
                                          colorScheme: const ColorScheme.dark(
                                            primary: Color(0xFF74C0FC),
                                            surface: Color(0xFF1E1E2E),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (!context.mounted || date == null) return;
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: ThemeData.dark().copyWith(
                                          colorScheme: const ColorScheme.dark(
                                            primary: Color(0xFF74C0FC),
                                            surface: Color(0xFF1E1E2E),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (!context.mounted || time == null) return;
                                  setState(() {
                                    selectedDate = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                },
                                icon: const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                ),
                                label: Text(
                                  selectedDate == null
                                      ? 'Selecionar'
                                      : DateFormat(
                                        'dd/MM/yyyy – HH:mm',
                                      ).format(selectedDate!),
                                  style: const TextStyle(fontSize: 13),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF74C0FC),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF313244),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF45475A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.toggle_on,
                                color: Color(0xFF74C0FC),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Status Ativo:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: status,
                                onChanged: (v) => setState(() => status = v),
                                activeThumbColor: const Color(0xFF74C0FC),
                                activeTrackColor: const Color(
                                  0xFF74C0FC,
                                ).withAlpha(77),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white60,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() != true ||
                          selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Por favor, preencha todos os campos obrigatórios',
                            ),
                            backgroundColor: Color(0xFFF38BA8),
                          ),
                        );
                        return;
                      }

                      try {
                        await FirebaseFirestore.instance
                            .collection('events')
                            .add({
                              'nome': nameController.text.trim(),
                              'local': localController.text.trim(),
                              'price':
                                  double.tryParse(
                                    priceController.text.trim(),
                                  ) ??
                                  0,
                              'data_event': selectedDate,
                              'status': status,
                              'percurso': <Map<String, dynamic>>[],
                              'checkpoints': <Map<String, dynamic>>[],
                              'created_at': FieldValue.serverTimestamp(),
                            });

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Evento criado com sucesso!'),
                            backgroundColor: Color(0xFFA6E3A1),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao criar evento: $e'),
                            backgroundColor: const Color(0xFFF38BA8),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF74C0FC),
                      foregroundColor: const Color(0xFF1E1E2E),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Criar Evento',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
        ),
  );
}

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  String? Function(String?)? validator,
  TextInputType? keyboardType,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    validator: validator,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: const Color(0xFF74C0FC), size: 20),
      filled: true,
      fillColor: const Color(0xFF313244),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF45475A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF45475A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF74C0FC), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF38BA8)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF38BA8), width: 2),
      ),
    ),
  );
}

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  int _selectedIndex = 0;
  bool _isCollapsed = false;

  final List<Widget> _pages = [
    const DashboardAdminView(),
    const EditionView(),
    const GenerateQrView(),
    const perguntas_view.PerguntasView(),
    const JogosManagementView(),
    const CreateUserView(),
    // const ReportsView(), // Removed
    const ParticipantesView(),
    const ParticipantesPorEventoView(),
    const RankingDetailedView(),
    const SizedBox.shrink(),
  ];

  final List<NavigationItem> _menuItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
      color: const Color(0xFF74C0FC),
    ),
    NavigationItem(
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
      label: 'Edições',
      color: const Color(0xFFA6E3A1),
    ),
    NavigationItem(
      icon: Icons.qr_code_outlined,
      selectedIcon: Icons.qr_code,
      label: 'QR Codes',
      color: const Color(0xFFF9E2AF),
    ),
    NavigationItem(
      icon: Icons.quiz_outlined,
      selectedIcon: Icons.quiz,
      label: 'Perguntas',
      color: const Color(0xFFCBA6F7),
    ),
    NavigationItem(
      icon: Icons.sports_esports_outlined,
      selectedIcon: Icons.sports_esports,
      label: 'Jogos',
      color: const Color(0xFFFAB387),
    ),
    NavigationItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: 'Utilizadores',
      color: const Color(0xFF89B4FA),
      isSubMenu: true,
    ),
    // NavigationItem for 'Reports' removed
    NavigationItem(
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      label: 'Participantes',
      color: const Color(0xFF94E2D5),
      isSubMenu: true,
    ),
    NavigationItem(
      icon: Icons.event_available_outlined,
      selectedIcon: Icons.event_available,
      label: 'Participantes por Evento',
      color: const Color(0xFF94E2D5),
      isSubMenu: true,
    ),
    NavigationItem(
      icon: Icons.leaderboard_outlined,
      selectedIcon: Icons.leaderboard,
      label: 'Ranking',
      color: const Color(0xFFEBA0AC),
    ),
    NavigationItem(
      icon: Icons.logout_outlined,
      selectedIcon: Icons.logout,
      label: 'Logout',
      color: const Color(0xFFF38BA8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppBackendTheme.dark,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;
          return Scaffold(
            backgroundColor: const Color(0xFF1E1E2E),
            appBar:
                isMobile
                    ? AppBar(
                      backgroundColor: const Color(0xFF313244),
                      elevation: 0,
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _menuItems[_selectedIndex].color.withAlpha(
                                26,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _menuItems[_selectedIndex].selectedIcon,
                              color: _menuItems[_selectedIndex].color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _menuItems[_selectedIndex].label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        // Scanner IconButton removido
                      ],
                    )
                    : null,
            drawer: isMobile ? _buildMobileDrawer() : null,
            body: Row(
              children: [
                if (!isMobile) _buildDesktopSidebar(),
                Expanded(
                  child: Column(
                    children: [
                      if (!isMobile) _buildDesktopHeader(),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          child:
                              _pages.asMap().containsKey(_selectedIndex)
                                  ? _pages[_selectedIndex]
                                  : const Center(
                                    child: Text(
                                      'Página não encontrada',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF313244),
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF74C0FC), Color(0xFF89B4FA)],
              ),
            ),
            child: const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Mano a Mano',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Painel Admin',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = _selectedIndex == index;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: ListTile(
                    leading: Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      color: isSelected ? item.color : Colors.white60,
                      size: 22,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: item.color.withAlpha(26),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () => _handleMenuTap(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isCollapsed ? 80 : 280,
      decoration: const BoxDecoration(
        color: Color(0xFF313244),
        border: Border(right: BorderSide(color: Color(0xFF45475A), width: 1)),
      ),
      child: Column(
        children: [
          Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF45475A), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF74C0FC), Color(0xFF89B4FA)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.speed, color: Colors.white, size: 20),
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Mano a Mano',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Admin Dashboard',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
                IconButton(
                  onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                  icon: Icon(
                    _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                    color: Colors.white60,
                  ),
                  iconSize: 20,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = _selectedIndex == index;

                if (item.isSubMenu && index > 4 && index < 9) {
                  // Group management items
                  if (index == 5) {
                    return Column(
                      children: [
                        if (!_isCollapsed)
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'GESTÃO',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        _buildSidebarItem(item, index, isSelected),
                      ],
                    );
                  }
                }

                return _buildSidebarItem(item, index, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(NavigationItem item, int index, bool isSelected) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _isCollapsed ? 8 : 12,
        vertical: 2,
      ),
      child: Tooltip(
        message: _isCollapsed ? item.label : '',
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: _isCollapsed ? 0 : 16,
            vertical: 4,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration:
                isSelected
                    ? BoxDecoration(
                      color: item.color.withAlpha(38),
                      borderRadius: BorderRadius.circular(10),
                    )
                    : null,
            child: Icon(
              isSelected ? item.selectedIcon : item.icon,
              color: isSelected ? item.color : Colors.white60,
              size: 22,
            ),
          ),
          title:
              _isCollapsed
                  ? null
                  : Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
          selected: isSelected,
          selectedTileColor: item.color.withAlpha(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: () => _handleMenuTap(index),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    final currentItem = _menuItems[_selectedIndex];

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF313244),
        border: Border(bottom: BorderSide(color: Color(0xFF45475A), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: currentItem.color.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              currentItem.selectedIcon,
              color: currentItem.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currentItem.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _getPageDescription(_selectedIndex),
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          // ElevatedButton Scanner removido
        ],
      ),
    );
  }

  String _getPageDescription(int index) {
    switch (index) {
      case 0:
        return 'Visão geral do sistema';
      case 1:
        return 'Gerir edições e eventos';
      case 2:
        return 'Gerar códigos QR';
      case 3:
        return 'Gerir perguntas do quiz';
      case 4:
        return 'Gerir jogos e desafios';
      case 5:
        return 'Gerir utilizadores do sistema';
      case 6:
        return 'Gerir participantes';
      case 7:
        return 'Participantes por evento';
      case 8:
        return 'Classificações detalhadas';
      default:
        return '';
    }
  }

  void _handleMenuTap(int index) {
    if (_menuItems[index].label == 'Logout') {
      _showLogoutDialog();
      return;
    }
    setState(() => _selectedIndex = index);
    if (Navigator.canPop(context)) {
      Navigator.pop(context); // Close drawer on mobile
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.logout, color: Color(0xFFF38BA8)),
                SizedBox(width: 12),
                Text('Confirmar Logout', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: const Text(
              'Tem certeza que deseja sair do painel administrativo?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF38BA8),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sair'),
              ),
            ],
          ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color color;
  final bool isSubMenu;

  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.color,
    this.isSubMenu = false,
  });
}
