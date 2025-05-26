// main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes/app_pages.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_backend_theme.dart' as backend;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Get.put(AuthService());
  runApp(const ManoManoDashboard());
}

class ManoManoDashboard extends StatelessWidget {
  const ManoManoDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard Mano Mano',
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        final currentRoute = Get.currentRoute;
        final isAdmin = currentRoute.startsWith('/admin');
        final theme = isAdmin ? backend.AppBackendTheme.dark : AppTheme.theme;
        return Theme(data: theme, child: child!);
      },
    );
  }
}
