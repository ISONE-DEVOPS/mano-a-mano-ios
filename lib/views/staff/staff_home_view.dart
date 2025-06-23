import 'package:flutter/material.dart';
import 'package:mano_mano_dashboard/widgets/shared/staff_app_bar.dart';
import 'package:mano_mano_dashboard/widgets/shared/staff_nav_bottom.dart';

class StaffHomeView extends StatefulWidget {
  const StaffHomeView({super.key});

  @override
  State<StaffHomeView> createState() => _StaffHomeViewState();
}

class _StaffHomeViewState extends State<StaffHomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StaffAppBar(title: 'Staff'),
      body: const Center(child: Text('Selecione uma opção no menu abaixo.')),
      bottomNavigationBar: const StaffNavBottom(),
    );
  }
}
