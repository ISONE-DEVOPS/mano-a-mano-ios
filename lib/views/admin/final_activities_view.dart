import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';
import '../../controllers/final_activities_controller.dart';

/// Tela que lista as atividades finais do evento e permite selecionar uma para destaque.
/// Utilizada pela organização para visualizar e gerir as atividades de team building.
class FinalActivitiesView extends StatelessWidget {
  FinalActivitiesView({super.key});
  final controller = Get.put(FinalActivitiesController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Atividades Finais', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(
          () => ListView.separated(
            itemCount: controller.activities.length,
            separatorBuilder: (context, _) => Divider(color: AppColors.textSecondary.withAlpha(61)),
            itemBuilder: (context, index) {
              final activity = controller.activities[index];
              final isSelected = controller.selectedActivity.value == activity;
              return ListTile(
                title: Text(
                  activity,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
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