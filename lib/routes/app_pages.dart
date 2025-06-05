import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/splash/splash_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/profile/profile_view.dart';
import '../views/checkin/checkin_view.dart';
import '../views/main/main_view.dart';
import '../views/admin/admin_view.dart';
import '../views/admin/edition_view.dart';
import '../views/payment/payment_view.dart';
import '../views/map/route_map_view.dart';
import '../views/map/event_route_view.dart';
import '../views/admin/route_editor_view.dart';
import '../views/events/user_events_view.dart';
import '../views/auth/forgot_password_view.dart';
import '../views/admin/add_checkpoints_view.dart';
import '../views/terms/terms_screen.dart';
import '../views/privacy/privacy_policy_screen.dart';
import '../views/admin/challenge_view.dart';
import '../views/checkin/checkpoint_questions_view.dart';
import '../views/admin/ranking_detailed_view.dart';
import '../views/admin/final_activities_view.dart';
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
import '../views/admin/manage_users_view.dart';
import '../views/admin/generate_qr_view.dart';
import '../views/admin/perguntas_view.dart';

class AppPages {
  static const initial = '/';

  static final routes = [
    GetPage(name: '/', page: () => const SplashView()),
    GetPage(name: '/loading-admin', page: () => const LoadingAdminView()),
    GetPage(name: '/splash', page: () => const IntroSplashView()),
    GetPage(name: '/login', page: () => const LoginView()),
    GetPage(name: '/register', page: () => const RegisterView()),
    // GetPage(name: '/home', page: () => const HomeView()),
    GetPage(name: '/profile', page: () => const ProfileView()),
    GetPage(name: '/checkin', page: () => const CheckinView()),
    GetPage(name: '/main', page: () => const MainView()),
    GetPage(name: '/admin', page: () => const AdminView()),
    GetPage(name: '/editions', page: () => const EditionView()),
    GetPage(
      name: '/payment',
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
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
    GetPage(name: '/event-route', page: () => const EventRouteView()),
    GetPage(
      name: '/route-editor',
      page: () {
        final eventId = Get.arguments as String;
        return RouteEditorView(eventId: eventId);
      },
    ),
    GetPage(name: '/my-events', page: () => const UserEventsView()),
    GetPage(name: '/forgot-password', page: () => const ForgotPasswordView()),
    GetPage(
      name: '/add-checkpoints',
      page: () => AddCheckpointsView(eventId: Get.arguments),
    ),
    GetPage(name: '/terms', page: () => const TermsScreen()),
    GetPage(name: '/privacy', page: () => const PrivacyPolicyScreen()),
    GetPage(name: '/challenges', page: () => ChallengeView()),
    GetPage(
      name: '/checkpoint-questions',
      page: () => const CheckpointQuestionsView(),
    ),
    GetPage(name: '/ranking-detailed', page: () => const RankingDetailedView()),
    GetPage(name: '/final-activities', page: () => FinalActivitiesView()),
    GetPage(
      name: '/team-customization',
      page: () => const TeamCustomizationView(),
    ),
    GetPage(name: '/ranking', page: () => const RankingView()),
    GetPage(
      name: '/pontuacao-detalhada',
      page: () => const PontuacaoDetalhadaView(),
    ),
    GetPage(name: '/conchas', page: () => const ConchasView()),
    GetPage(
      name: '/resultados-finais',
      page: () => const ResultadosFinaisView(),
    ),
    GetPage(name: '/team-profile', page: () => const TeamProfileView()),
    GetPage(name: '/scan-score', page: () => const ScanAndScoreView()),
    GetPage(name: '/pontuacoes', page: () => const PontuacoesView()),
    GetPage(name: '/manage-users', page: () => ManageUsersView()),
    GetPage(name: '/generate-qr', page: () => const GenerateQrView()),
    GetPage(name: '/perguntas', page: () => const PerguntasView()),
  ];
}
