import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'participantes_view.dart';
import 'dashboard_admin_view.dart';
import 'edition_view.dart';
import 'generate_qr_view.dart';
import 'perguntas_view.dart' as perguntas_view;
import 'jogos_create_view.dart';
//import 'final_activities_view.dart';
import 'ranking_detailed_view.dart';
import 'package:mano_mano_dashboard/theme/app_backend_theme.dart';
import 'package:mano_mano_dashboard/widgets/shared/custom_navigation_rail.dart';
import 'package:mano_mano_dashboard/widgets/shared/custom_top_bar.dart';

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
                title: const Text('Novo Evento'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Título',
                          ),
                          validator:
                              (v) =>
                                  v == null || v.isEmpty
                                      ? 'Informe o título'
                                      : null,
                        ),
                        TextFormField(
                          controller: localController,
                          decoration: const InputDecoration(labelText: 'Local'),
                          validator:
                              (v) =>
                                  v == null || v.isEmpty
                                      ? 'Informe o local'
                                      : null,
                        ),
                        TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: 'Preço'),
                          keyboardType: TextInputType.number,
                          validator:
                              (v) =>
                                  v == null || v.isEmpty
                                      ? 'Informe o preço'
                                      : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Data e Hora:'),
                            TextButton(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (!context.mounted || date == null) return;
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
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
                              child: Text(
                                selectedDate == null
                                    ? 'Selecionar'
                                    : DateFormat(
                                      'dd/MM/yyyy – HH:mm',
                                    ).format(selectedDate!),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Ativo:'),
                            Switch(
                              value: status,
                              onChanged: (v) => setState(() => status = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() != true ||
                          selectedDate == null) {
                        return;
                      }
                      await FirebaseFirestore.instance.collection('events').add(
                        {
                          'nome': nameController.text.trim(),
                          'local': localController.text.trim(),
                          'price':
                              double.tryParse(priceController.text.trim()) ?? 0,
                          'data_event': selectedDate,
                          'status': status,
                          'percurso': <Map<String, dynamic>>[],
                          'checkpoints': <Map<String, dynamic>>[],
                        },
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      nameController.clear();
                      localController.clear();
                      priceController.clear();
                    },
                    child: const Text('Salvar'),
                  ),
                ],
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
    const JogosCreateView(),
    const ParticipantesView(),
    const RankingDetailedView(),
  ];

  final List<String> _menuTitles = [
    'Dashboard',
    'Edições',
    'QR Codes',
    'Perguntas',
    'Jogos',
    'Participantes',
    'Ranking Detalhado',
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppBackendTheme.dark,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;
          return Scaffold(
            drawer:
                isMobile
                    ? Drawer(
                      child: ListView.builder(
                        itemCount: _menuTitles.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_menuTitles[index]),
                            onTap: () {
                              setState(() => _selectedIndex = index);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    )
                    : null,
            body: Row(
              children: [
                if (!isMobile)
                  CustomNavigationRail(
                    selectedIndex: _selectedIndex,
                    isCollapsed: _isCollapsed,
                    onItemSelected: (index) {
                      if (index == 10) {
                        FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushReplacementNamed('/login');
                        return;
                      }
                      setState(() => _selectedIndex = index);
                    },
                  ),
                Expanded(
                  child: Column(
                    children: [
                      if (!isMobile)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: Icon(
                              _isCollapsed
                                  ? Icons.chevron_right
                                  : Icons.chevron_left,
                            ),
                            onPressed: () {
                              setState(() {
                                _isCollapsed = !_isCollapsed;
                              });
                            },
                          ),
                        ),
                      CustomTopBar(
                        title:
                            _menuTitles.asMap().containsKey(_selectedIndex)
                                ? _menuTitles[_selectedIndex]
                                : '',
                        onScanPressed:
                            () => Navigator.pushNamed(context, '/scan-score'),
                      ),
                      Expanded(
                        child:
                            _pages.asMap().containsKey(_selectedIndex)
                                ? _pages[_selectedIndex]
                                : const Center(
                                  child: Text('Página não encontrada'),
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
}
