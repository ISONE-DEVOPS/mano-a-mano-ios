import 'package:flutter/material.dart';
import 'package:mano_mano_dashboard/theme/app_colors.dart';

class LoadingAdminView extends StatefulWidget {
  const LoadingAdminView({super.key});

  @override
  State<LoadingAdminView> createState() => _LoadingAdminViewState();
}

class _LoadingAdminViewState extends State<LoadingAdminView> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/register');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/Logo_Shell_KM.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 32),
            Text(
              'Carregando a App Shell ao KM...',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Por favor, aguarde enquanto iniciamos sistema.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary.withAlpha(179),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
