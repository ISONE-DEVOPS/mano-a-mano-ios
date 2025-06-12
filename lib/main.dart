// main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'routes/app_pages.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_backend_theme.dart' as backend;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((_) {
    Get.put(AuthService());
    Future.microtask(() {
      runApp(
        Listener(
          onPointerSignal: (event) {
            if (event.kind.toString() == 'PointerDeviceKind.trackpad') return;
          },
          child: const ManoManoDashboard(),
        ),
      );
    });
  });
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.mouse,
    PointerDeviceKind.touch,
    // NÃO inclui trackpad
  };
}

class ManoManoDashboard extends StatelessWidget {
  const ManoManoDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard Mano Mano',
      initialRoute: kIsWeb ? '/loading-admin' : '/splash',
      getPages: AppPages.routes,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      scrollBehavior: MyCustomScrollBehavior(),
      builder: (context, child) {
        final currentRoute = Get.currentRoute;
        final isAdmin = currentRoute.startsWith('/admin');
        final theme = isAdmin ? backend.AppBackendTheme.dark : AppTheme.theme;
        return Theme(data: theme, child: child!);
      },
    );
  }
}
