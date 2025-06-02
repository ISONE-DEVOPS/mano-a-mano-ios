

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/final_activities_controller.dart';

/// Tela para exibir e selecionar os desafios finais de team building.
/// Esta tela permite aos administradores ou utilizadores visualizar as atividades disponíveis.
class ChallengeView extends StatelessWidget {
  ChallengeView({super.key});
  final controller = Get.put(FinalActivitiesController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desafios Finais'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(
          () => ListView.builder(
            itemCount: controller.activities.length,
            itemBuilder: (context, index) {
              final activity = controller.activities[index];
              final isSelected = controller.selectedActivity.value == activity;
              return Card(
                color: isSelected ? Colors.yellow[100] : null,
                child: ListTile(
                  title: Text(activity),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () => controller.selectActivity(activity),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}