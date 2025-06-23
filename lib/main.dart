// main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'routes/app_pages.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_backend_theme.dart' as backend;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final configDoc = await firestore.collection('config').doc('evento2025').get();
  final inscricoesAbertas = configDoc.data()?['inscricoesAbertas'] ?? false;

  final initialRoute = kIsWeb
      ? (inscricoesAbertas ? '/login' : '/closed')
      : '/splash';

  Get.put(AuthService());

  runApp(
    Listener(
      onPointerSignal: (event) {
        if (event.kind.toString() == 'PointerDeviceKind.trackpad') return;
      },
      child: ManoManoDashboard(initialRoute: initialRoute),
    ),
  );
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
  final String initialRoute;

  const ManoManoDashboard({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard Mano Mano',
      // Inicialização dinâmica da rota com base no estado das inscrições no Firestore
      // (Veja abaixo como buscar essa flag antes de runApp)
      initialRoute: initialRoute,
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
