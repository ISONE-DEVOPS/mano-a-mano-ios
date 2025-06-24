// main.dart - Versão Corrigida
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
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Registrar AuthService antes de verificar configurações
    Get.put(AuthService());

    // Determinar rota inicial com tratamento de erro
    final initialRoute = await _determineInitialRoute();

    runApp(ManoManoDashboard(initialRoute: initialRoute));
  } catch (e) {
    developer.log('Erro na inicialização: $e', name: 'main');
    // Fallback para rota padrão em caso de erro
    runApp(ManoManoDashboard(initialRoute: kIsWeb ? '/login' : '/splash'));
  }
}

Future<String> _determineInitialRoute() async {
  try {
    final firestore = FirebaseFirestore.instance;

    // Timeout para evitar espera infinita
    final configDoc = await firestore
        .collection('config')
        .doc('evento2025')
        .get()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            developer.log(
              'Timeout ao buscar configuração - usando configuração padrão',
              name: 'main',
            );
            // Retorna um DocumentSnapshot vazio em caso de timeout
            throw Exception('Timeout na configuração');
          },
        );

    if (configDoc.exists) {
      // Lógica de rota inicial: sempre '/login' para web, '/splash' para outros
      return kIsWeb ? '/login' : '/splash';
    } else {
      developer.log(
        'Documento de configuração não encontrado - criando configuração padrão',
        name: 'main',
      );
      await _createDefaultConfig(firestore);
      return kIsWeb ? '/login' : '/splash';
    }
  } catch (e) {
    developer.log('Erro ao determinar rota inicial: $e', name: 'main');
    // Fallback em caso de erro
    return kIsWeb ? '/login' : '/splash';
  }
}

Future<void> _createDefaultConfig(FirebaseFirestore firestore) async {
  try {
    await firestore.collection('config').doc('evento2025').set({
      'inscricoesAbertas': true,
      'eventoAtivo': false,
      'dataEvento': DateTime(2025, 6, 28),
      'versaoApp': '1.0.0',
      'configuradoEm': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    developer.log('Erro ao criar configuração padrão: $e', name: 'main');
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.mouse,
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    // Não inclui trackpad para evitar conflitos
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
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      scrollBehavior: MyCustomScrollBehavior(),

      // Configuração de localização
      locale: const Locale('pt', 'CV'), // Português de Cabo Verde
      fallbackLocale: const Locale('pt', 'PT'),

      // Builder corrigido para aplicar tema baseado na rota
      builder: (context, child) {
        return _buildWithDynamicTheme(context, child);
      },

      // Configurações adicionais
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),

      // Tratamento de rotas não encontradas
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const NotFoundPage(),
      ),
    );
  }

  Widget _buildWithDynamicTheme(BuildContext context, Widget? child) {
    if (child == null) return const SizedBox.shrink();

    try {
      final currentRoute = Get.currentRoute;
      final isAdminRoute = currentRoute.startsWith('/admin');

      // Aplicar tema baseado na rota
      final theme =
          isAdminRoute ? backend.AppBackendTheme.dark : AppTheme.theme;

      return Theme(data: theme, child: child);
    } catch (e) {
      developer.log('Erro ao aplicar tema dinâmico: $e', name: 'main');
      // Fallback para tema padrão
      return Theme(data: AppTheme.theme, child: child);
    }
  }
}

// Página para rotas não encontradas
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Página não encontrada',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'A página que procura não existe.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 24),
            BackButton(),
          ],
        ),
      ),
    );
  }
}
