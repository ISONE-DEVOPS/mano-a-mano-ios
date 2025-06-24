// main.dart - Versão CORRIGIDA - SEM dependência da coleção config
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
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Registrar AuthService
    Get.put(AuthService());

    // Determinar rota inicial SEM depender do Firestore
    final initialRoute = _determineInitialRoute();

    developer.log('Iniciando app com rota: $initialRoute', name: 'main');

    runApp(ManoManoDashboard(initialRoute: initialRoute));
  } catch (e) {
    developer.log('Erro na inicialização: $e', name: 'main');
    // Fallback para rota padrão em caso de erro
    runApp(ManoManoDashboard(initialRoute: kIsWeb ? '/login' : '/splash'));
  }
}

// Função SIMPLIFICADA - sem consulta ao Firestore
String _determineInitialRoute() {
  try {
    if (kIsWeb) {
      developer.log('Plataforma Web detectada - usando /login', name: 'main');
      return '/login';
    } else {
      developer.log(
        'Plataforma Mobile detectada - usando /splash',
        name: 'main',
      );
      return '/splash';
    }
  } catch (e) {
    developer.log('Erro ao determinar rota inicial: $e', name: 'main');
    // Fallback robusto
    return kIsWeb ? '/login' : '/splash';
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.mouse,
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
  };
}

class ManoManoDashboard extends StatelessWidget {
  final String initialRoute;

  const ManoManoDashboard({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    developer.log(
      'Construindo app com rota inicial: $initialRoute',
      name: 'app',
    );

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
      locale: const Locale('pt', 'CV'),
      fallbackLocale: const Locale('pt', 'PT'),

      // Builder com error handling
      builder: (context, child) {
        return _buildWithDynamicTheme(context, child);
      },

      // Configurações de transição
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),

      // Tratamento de rotas não encontradas
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const NotFoundPage(),
      ),

      // Callback para monitorar navegação
      routingCallback: (routing) {
        if (routing?.current != null) {
          developer.log('Navegando para: ${routing!.current}', name: 'routing');
        }
      },
    );
  }

  Widget _buildWithDynamicTheme(BuildContext context, Widget? child) {
    if (child == null) {
      developer.log(
        'ERRO: Child é null no builder - retornando loading',
        name: 'theme-builder',
      );
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando aplicação...'),
            ],
          ),
        ),
      );
    }

    try {
      final currentRoute = Get.currentRoute;
      final isAdminRoute =
          currentRoute.startsWith('/admin') ||
          currentRoute.startsWith('/loading-admin');

      developer.log(
        'Aplicando tema para rota: $currentRoute (admin: $isAdminRoute)',
        name: 'theme',
      );

      // Aplicar tema baseado na rota
      final theme =
          isAdminRoute ? backend.AppBackendTheme.dark : AppTheme.theme;

      return Theme(data: theme, child: child);
    } catch (e) {
      developer.log('Erro ao aplicar tema dinâmico: $e', name: 'theme-builder');
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
    developer.log('Renderizando página 404', name: 'not-found');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Página não encontrada'),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
              const SizedBox(height: 24),
              const Text(
                'Página não encontrada',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'A página que procura não existe ou foi movida.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      try {
                        Get.offAllNamed('/login');
                      } catch (e) {
                        developer.log(
                          'Erro ao navegar para login: $e',
                          name: 'not-found',
                        );
                      }
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Ir para Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      try {
                        if (Get.previousRoute.isNotEmpty) {
                          Get.back();
                        } else {
                          Get.offAllNamed('/login');
                        }
                      } catch (e) {
                        developer.log('Erro ao voltar: $e', name: 'not-found');
                        Get.offAllNamed('/login');
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Voltar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
