import 'package:flutter/material.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';

class GalleryView extends StatelessWidget {
  const GalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Galeria de Fotos', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            return Container(
              color: AppColors.secondaryDark.withAlpha(51),
              child: const Icon(Icons.photo, size: 48, color: AppColors.primary),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondaryDark,
        onPressed: () {
          // ação de upload futura
        },
        child: const Icon(Icons.add_a_photo, color: Colors.black),
      ),
    );
  }
}
