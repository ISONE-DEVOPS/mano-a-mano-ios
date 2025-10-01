import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';
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
        title: const Text(
          'Desafios Finais',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
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
                color:
                    isSelected
                        ? AppColors.primary.withAlpha(20)
                        : AppColors.surface,
                child: ListTile(
                  title: Text(
                    activity,
                    style: TextStyle(
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing:
                      isSelected
                          ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
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
