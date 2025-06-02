

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/final_activities_controller.dart';

/// Tela que lista as atividades finais do evento e permite selecionar uma para destaque.
/// Utilizada pela organização para visualizar e gerir as atividades de team building.
class FinalActivitiesView extends StatelessWidget {
  FinalActivitiesView({super.key});
  final controller = Get.put(FinalActivitiesController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atividades Finais')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(
          () => ListView.separated(
            itemCount: controller.activities.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final activity = controller.activities[index];
              final isSelected = controller.selectedActivity.value == activity;
              return ListTile(
                title: Text(activity),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () => controller.selectActivity(activity),
              );
            },
          ),
        ),
      ),
    );
  }
}