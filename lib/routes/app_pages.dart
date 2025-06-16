import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/dashboard/home_view.dart';
import '../views/splash/splash_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/profile/profile_view.dart';
import '../views/profile/delete_account_view.dart';
import '../views/checkin/checkin_view.dart';
//import '../views/main/main_view.dart';
import '../views/admin/admin_view.dart';
import '../views/admin/edition_view.dart';
import '../views/payment/payment_view.dart';
import '../views/map/route_map_view.dart';
//import '../views/map/event_route_view.dart';
import '../views/admin/route_editor_view.dart';
import '../views/events/user_events_view.dart';
import '../views/auth/forgot_password_view.dart';
import '../views/events/event_details_view.dart';
import '../views/admin/add_checkpoints_view.dart';
import '../views/terms/terms_screen.dart';
import '../views/privacy/privacy_policy_screen.dart';
import '../views/admin/challenge_view.dart';
import '../views/checkin/checkpoint_questions_view.dart';
import '../views/admin/ranking_detailed_view.dart';
//import '../views/admin/final_activities_view.dart';
import '../views/profile/team_customization_view.dart';
import '../views/admin/loading_admin_view.dart';
import '../views/splash/intro_splash_view.dart';
import '../views/ranking/ranking_view.dart';
import '../views/pontuacao/pontuacao_detalhada_view.dart';
import '../views/checkin/conchas_view.dart';
import '../views/resultados/resultados_finais_view.dart';
import '../views/profile/team_profile_view.dart';
import '../views/admin/scan_and_score_view.dart';
import '../views/admin/pontuacoes_view.dart';
import '../views/admin/participantes_view.dart';
import '../views/admin/generate_qr_view.dart';
import '../views/admin/perguntas_view.dart';
//import '../views/admin/jogos_create_view.dart';
import '../views/admin/checkpoints_list_dialog.dart';
import '../views/admin/register_participant_view.dart';

class AppPages {
  static const initial = '/';

  static final routes = [
    // Splash e Autenticação
    GetPage(name: '/', page: () => const SplashView()),
    GetPage(name: '/loading-admin', page: () => const LoadingAdminView()),
    GetPage(name: '/splash', page: () => const IntroSplashView()),
    GetPage(name: '/login', page: () => const LoginView()),
    GetPage(name: '/register', page: () => const RegisterView()),
    GetPage(name: '/home', page: () => const HomeView()),
    GetPage(name: '/forgot-password', page: () => const ForgotPasswordView()),

    // Administração
    GetPage(name: '/admin', page: () => const AdminView()),
    GetPage(name: '/editions', page: () => const EditionView()),
    GetPage(
      name: '/add-checkpoints',
      page:
          () => Builder(
            builder: (_) {
              final args = Get.arguments;
              if (args == null ||
                  args is! Map ||
                  !args.containsKey('edicaoId') ||
                  !args.containsKey('eventId')) {
                return Scaffold(
                  body: SafeArea(
                    child: Center(
                      child: Text(
                        'Argumentos inválidos ou ausentes para AddCheckpointsView',
                      ),
                    ),
                  ),
                );
              }
              return const AddCheckpointsView();
            },
          ),
    ),
    GetPage(name: '/challenges', page: () => ChallengeView()),
    GetPage(name: '/ranking-detailed', page: () => const RankingDetailedView()),
    // GetPage(name: '/final-activities', page: () => FinalActivitiesView()),
    GetPage(name: '/scan-score', page: () => const ScanAndScoreView()),
    GetPage(name: '/pontuacoes', page: () => const PontuacoesView()),
    GetPage(name: '/participantes', page: () => const ParticipantesView()),
    GetPage(name: '/generate-qr', page: () => const GenerateQrView()),
    GetPage(name: '/perguntas', page: () => const PerguntasView()),
    GetPage(
      name: '/register-participant',
      page: () {
        final userId = Get.arguments as String?;
        return RegisterParticipantView(userId: userId);
      },
    ),

    // Mapas e Percursos
    GetPage(
      name: '/payment',
      page: () {
        final args = Get.arguments;
        if (args == null ||
            args is! Map<String, dynamic> ||
            !args.containsKey('eventId') ||
            !args.containsKey('amount')) {
          return const Scaffold(
            body: Center(child: Text('Dados de pagamento inválidos')),
          );
        }
        return PaymentView(
          eventId: args['eventId'] as String,
          amount: args['amount'] as double,
        );
      },
    ),
    GetPage(
      name: '/route-map',
      page: () {
        final eventId = Get.arguments;
        if (eventId == null || eventId is! String) {
          return const Scaffold(
            body: Center(child: Text('Evento não selecionado')),
          );
        }
        return RouteMapView(eventId: eventId);
      },
    ),
    // GetPage(name: '/event-route', page: () => const EventRouteView()),
    GetPage(
      name: '/route-editor',
      page: () {
        final eventId = Get.arguments;
        if (eventId == null || eventId is! String) {
          return const Scaffold(
            body: Center(child: Text('Evento não selecionado')),
          );
        }
        return RouteEditorView(eventId: eventId);
      },
    ),

    // Check-ins e Pontuação
    GetPage(name: '/checkin', page: () => const CheckinView()),
    GetPage(
      name: '/checkpoint-questions',
      page: () => const CheckpointQuestionsView(),
    ),
    GetPage(
      name: '/pontuacao-detalhada',
      page: () => const PontuacaoDetalhadaView(),
    ),
    GetPage(name: '/conchas', page: () => const ConchasView()),

    // Perfil e Equipa
    GetPage(name: '/profile', page: () => const ProfileView()),
    GetPage(name: '/delete-account', page: () => const DeleteAccountView()),
    GetPage(
      name: '/team-customization',
      page: () => const TeamCustomizationView(),
    ),
    GetPage(name: '/team-profile', page: () => const TeamProfileView()),

    // Ranking e Resultados
    GetPage(name: '/ranking', page: () => const RankingView()),
    GetPage(
      name: '/resultados-finais',
      page: () => const ResultadosFinaisView(),
    ),
    GetPage(name: '/my-events', page: () => const UserEventsView()),
    GetPage(name: '/event-details', page: () => const EventDetailsView()),

    // Configurações e Legais
    GetPage(name: '/terms', page: () => const TermsScreen()),
    GetPage(name: '/privacy', page: () => const PrivacyPolicyScreen()),

    // Componentes Dialog
    GetPage(
      name: '/checkpoints-list',
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return CheckpointsListDialog(
          edicaoId: args['edicaoId'] as String,
          eventId: args['eventId'] as String,
        );
      },
    ),
  ];
}
