// main.dart - Versão CORRIGIDA - SEM dependência da coleção config
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'routes/app_pages.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_backend_theme.dart' as backend;
import 'dart:developer' as developer;

// ===== Active Event Config (local, sem depender de outros ficheiros) =====
class _EventConfig {
  final String name;
  final String brand; // 'mano' | 'shell' | outros
  final String? logoUrl;
  final String checkinMode; // 'single' | 'entry_exit'
  final bool hasQuestions;
  final bool hasGames;
  final bool hasScoring;

  const _EventConfig({
    required this.name,
    required this.brand,
    required this.logoUrl,
    required this.checkinMode,
    required this.hasQuestions,
    required this.hasGames,
    required this.hasScoring,
  });

  bool get isMano => brand.toLowerCase() == 'mano';
  bool get isShell => brand.toLowerCase() == 'shell';

  factory _EventConfig.fromMap(Map<String, dynamic> m) {
    final brand = (m['brand'] as String? ?? 'shell').toLowerCase();
    return _EventConfig(
      name: m['name'] as String? ?? 'Evento',
      brand: brand,
      logoUrl: m['logoUrl'] as String?,
      checkinMode: (m['checkinMode'] as String? ?? 'entry_exit').toLowerCase(),
      hasQuestions: (m['hasQuestions'] as bool?) ?? true,
      hasGames: (m['hasGames'] as bool?) ?? true,
      hasScoring: (m['hasScoring'] as bool?) ?? true,
    );
  }
}

/// Notificador global do evento ativo (para reatividade simples, sem novos serviços).
final ValueNotifier<_EventConfig?> _activeEvent = ValueNotifier<_EventConfig?>(null);

/// Inicia o watcher do evento ativo (events.where isActive==true). Reconstrói o tema em tempo real.
Future<void> _initActiveEventWatcher() async {
  try {
    final db = FirebaseFirestore.instance;
    final q = await db.collection('events').where('isActive', isEqualTo: true).limit(1).get();
    if (q.docs.isEmpty) {
      developer.log('Nenhum evento ativo encontrado. Usando tema padrão.', name: 'event');
      _activeEvent.value = null;
      return;
    }
    final doc = q.docs.first;
    _activeEvent.value = _EventConfig.fromMap(doc.data());
    developer.log('Evento ativo: ${_activeEvent.value!.name} (${_activeEvent.value!.brand})', name: 'event');

    // Escuta alterações do evento ativo (ex.: alternar Shell & Mano no Admin)
    doc.reference.snapshots().listen((snap) {
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      _activeEvent.value = _EventConfig.fromMap(data);
      developer.log('Evento atualizado: ${_activeEvent.value!.name} (${_activeEvent.value!.brand})', name: 'event');
    });
  } catch (e) {
    developer.log('Falha ao carregar evento ativo: $e', name: 'event', error: e);
    _activeEvent.value = null; // fallback
  }
}

/// Constrói um ThemeData dinâmico baseado no evento ativo.
ThemeData _buildEventTheme(_EventConfig? cfg) {
  if (cfg == null) {
    // fallback: tema padrão já existente
    return AppTheme.theme;
  }

  // Paletas: Shell (amarelo/vermelho) vs Mano (preto/laranja)
  // Shell Yellow #FFC600 / Shell Red #DD1D21; Mano primary #FF6600 e onPrimary #000000
  final bool isMano = cfg.isMano;
  final Brightness brightness = isMano ? Brightness.dark : Brightness.light;
  final Color primary = isMano ? const Color(0xFFFF6600) : const Color(0xFFFFC600);
  final Color onPrimary = isMano ? const Color(0xFF000000) : const Color(0xFFDD1D21);
  final Color surface = isMano ? const Color(0xFF121212) : Colors.white;
  final Color onSurface = isMano ? Colors.white : Colors.black87;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: onPrimary,
    secondary: primary,
    onSecondary: onPrimary,
    error: Colors.redAccent,
    onError: Colors.white,
    surface: surface,
    onSurface: onSurface,
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: const StadiumBorder(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
    ),
  );
}
// ===== Fim bloco: Active Event Config =====

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Registrar AuthService
    Get.put(AuthService());

    // Iniciar watcher do evento ativo (para tema/fluxo dinâmico: Shell vs Mano)
    await _initActiveEventWatcher();

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

    return ValueListenableBuilder<_EventConfig?>(
      valueListenable: _activeEvent,
      builder: (context, cfg, _) {
        final dynamicTheme = _buildEventTheme(cfg);

        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Dashboard Mano a Mano',
          initialRoute: initialRoute,
          getPages: AppPages.routes,

          // Tema dinâmico por evento (Shell vs Mano). O builder abaixo ainda pode sobrepor para rotas admin.
          theme: dynamicTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          scrollBehavior: MyCustomScrollBehavior(),

          // Configuração de localização
          locale: const Locale('pt', 'CV'),
          fallbackLocale: const Locale('pt', 'PT'),

          // Builder com error handling + override de tema para rotas admin
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
