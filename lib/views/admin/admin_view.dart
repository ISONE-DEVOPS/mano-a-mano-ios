import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'generate_qr_view.dart';
import 'perguntas_view.dart';
import 'users_admin_view.dart';
import 'edition_view.dart';
import 'gallery_view.dart';
import 'events_view.dart';
import 'profile_view.dart';
import 'dashboard_admin_view.dart';
import 'package:mano_mano_dashboard/theme/app_backend_theme.dart';
import 'challenge_view.dart';
import 'ranking_detailed_view.dart';
import 'final_activities_view.dart';

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

  final List<Widget> _pages = [
    const DashboardAdminView(),
    const EditionView(),
    const EventsView(),
    const PerguntasView(),
    const GenerateQrView(),
    const GalleryView(),
    const UsersAdminView(),
    ProfileView(),
    const SizedBox(), // Placeholder para Logout
    ChallengeView(),
    const RankingDetailedView(),
    FinalActivitiesView(),
  ];

  final List<String> _menuTitles = [
    'Dashboard',
    'Edição',
    'Eventos',
    'Perguntas',
    'Checkpoints',
    'Galeria',
    'Utilizadores',
    'Perfil',
    'Logout',
    'Desafios',
    'Ranking Detalhado',
    'Atividades Finais',
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppBackendTheme.dark,
      child: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected:
                  (index) => setState(() => _selectedIndex = index),
              labelType: NavigationRailLabelType.all,
              backgroundColor: const Color.fromARGB(255, 14, 1, 1),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.edit),
                  label: Text('Edição'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.event),
                  label: Text('Eventos'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.quiz),
                  label: Text('Perguntas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.qr_code),
                  label: Text('Checkpoints'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.photo_library),
                  label: Text('Galeria'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people),
                  label: Text('Utilizadores'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person),
                  label: Text('Perfil'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.logout),
                  label: Text('Logout'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.flag),
                  label: Text('Desafios'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.leaderboard),
                  label: Text('Ranking'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.sports_score),
                  label: Text('Finais'),
                ),
              ],
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.blueGrey.shade900,
                    width: double.infinity,
                    child: Text(
                      _menuTitles[_selectedIndex],
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  Expanded(child: _pages[_selectedIndex]),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton:
            _selectedIndex == 2
                ? FloatingActionButton(
                  tooltip: 'Adicionar Evento',
                  backgroundColor: Colors.black,
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => showAddEventDialog(context),
                )
                : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
