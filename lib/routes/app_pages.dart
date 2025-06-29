import 'package:get/get.dart';

// Views Dashboard
import '../views/dashboard/home_view.dart';

// Views Auth
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/auth/forgot_password_view.dart';
import '../views/auth/criar_conta_view.dart';
// Removido: closed_registration_view

// Views Splash
import '../views/splash/intro_splash_view.dart';

// Views Profile
import '../views/profile/profile_view.dart';
import '../views/profile/delete_account_view.dart';
import '../views/profile/team_customization_view.dart';
import '../views/profile/team_profile_view.dart';

// Views Staff
import '../views/staff/staff_jogos_view.dart';
import '../views/staff/checkin_staff_view.dart';
import '../views/staff/staff_profile.dart';

// Views Admin
import '../views/admin/admin_view.dart';
import '../views/admin/edition_view.dart';
import '../views/admin/challenge_view.dart';
import '../views/admin/ranking_detailed_view.dart';
import '../views/admin/loading_admin_view.dart';
import '../views/admin/scan_and_score_view.dart';
import '../views/admin/pontuacoes_view.dart';
import '../views/admin/participantes_view.dart';
import '../views/admin/generate_qr_view.dart';
import '../views/admin/perguntas_view.dart';
import '../views/admin/create_user_view.dart';
import '../views/admin/report_geral_view.dart';

// Views Check-in
import '../views/checkin/checkin_view.dart';
import '../views/checkin/checkpoint_questions_view.dart';
import '../views/checkin/conchas_view.dart';

// Views Events
import '../views/events/user_events_view.dart';
import '../views/events/event_details_view.dart';

// Views Ranking
import '../views/ranking/ranking_view.dart';

// Views Pontuacao
import '../views/pontuacao/pontuacao_detalhada_view.dart';

// Views Resultados
import '../views/resultados/resultados_finais_view.dart';

// Views Terms
import '../views/terms/terms_screen.dart';
import '../views/privacy/privacy_policy_screen.dart';

// Views Error
import '../views/error/not_found_page.dart';

// Utils
import '../utils/route_helpers.dart';

class AppPages {
  static const initial = '/splash';

  static final routes = [
    // =================== SPLASH E AUTENTICAÇÃO ===================
    GetPage(
      name: '/',
      page: () => const LoginView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: '/splash',
      page: () => const IntroSplashView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: '/login',
      page: () => const LoginView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/register',
      page: () => const RegisterView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/criar-conta',
      page: () => const CriarContaView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/forgot-password',
      page: () => const ForgotPasswordView(),
      transition: Transition.rightToLeft,
    ),
    // Removido: rota '/closed'

    // =================== DASHBOARD ===================
    GetPage(
      name: '/home',
      page: () => const HomeView(),
      transition: Transition.fadeIn,
    ),

    // =================== ADMINISTRAÇÃO ===================
    GetPage(
      name: '/loading-admin',
      page: () => const LoadingAdminView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: '/admin',
      page: () => const AdminView(),
      transition: Transition.fadeIn,
      middlewares: [AdminMiddleware()], // Adicionar middleware para proteção
    ),
    GetPage(
      name: '/editions',
      page: () => const EditionView(),
      transition: Transition.rightToLeft,
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: '/add-checkpoints',
      page: () => RouteHelpers.buildAddCheckpointsView(),
      transition: Transition.rightToLeft,
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: '/challenges',
      page: () => ChallengeView(),
      transition: Transition.rightToLeft,
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: '/jogos',
      page: () => ChallengeView(),
      transition: Transition.rightToLeft,
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: '/ranking-detailed',
      page: () => const RankingDetailedView(),
      transition: Transition.rightToLeft,
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: '/gestao-utilizadores',
      page: () => const CreateUserView(),
      transition: Transition.rightToLeft,
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: '/gestao-reports',
      page: () => const ReportsView(),
      transition: Transition.rightToLeft,
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: '/gestao-participantes',
      page: () => const ParticipantesView(),
      transition: Transition.rightToLeft,
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: '/pontuacoes',
      page: () => const PontuacoesView(),
      transition: Transition.rightToLeft,
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: '/participantes',
      page: () => const ParticipantesView(),
      transition: Transition.rightToLeft,
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: '/generate-qr',
      page: () => const GenerateQrView(),
      transition: Transition.rightToLeft,
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: '/perguntas',
      page: () => const PerguntasView(),
      transition: Transition.rightToLeft,
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: '/register-participant',
      page: () => RouteHelpers.buildRegisterParticipantView(),
      transition: Transition.rightToLeft,
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: '/admin/scan-score',
      page: () => const ScanAndScoreView(),
      transition: Transition.rightToLeft,
      middlewares: [AdminMiddleware()],
    ),

    // =================== STAFF ===================
    GetPage(
      name: '/staff',
      page: () => const StaffJogosView(),
      transition: Transition.fadeIn,
      middlewares: [StaffMiddleware()],
    ),
    GetPage(
      name: '/staff/jogos',
      page: () => const StaffJogosView(),
      transition: Transition.rightToLeft,
      middlewares: [StaffMiddleware()],
    ),
    GetPage(
      name: '/staff/profile',
      page: () => const StaffProfileView(),
      transition: Transition.rightToLeft,
      middlewares: [StaffMiddleware()],
    ),
    GetPage(
      name: '/staff/checkin',
      page: () => StaffScoreInputView(),
      transition: Transition.rightToLeft,
      middlewares: [StaffMiddleware()],
    ),
    GetPage(
      name: '/scan-score',
      page: () => const StaffScoreInputView(),
      transition: Transition.rightToLeft,
      middlewares: [StaffMiddleware()],
    ),

    // =================== PAGAMENTO ===================
    GetPage(
      name: '/payment',
      page: () => RouteHelpers.buildPaymentView(),
      transition: Transition.rightToLeft,
    ),

    // =================== MAPAS E PERCURSOS ===================
    GetPage(
      name: '/route-map',
      page: () => RouteHelpers.buildRouteMapView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/route-editor',
      page: () => RouteHelpers.buildRouteEditorView(),
      transition: Transition.rightToLeft,
      middlewares: [AdminMiddleware()],
    ),

    // =================== CHECK-INS E PONTUAÇÃO ===================
    GetPage(
      name: '/checkin',
      page: () => const CheckinView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/checkpoint-questions',
      page: () => const CheckpointQuestionsView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/pontuacao-detalhada',
      page: () => const PontuacaoDetalhadaView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/conchas',
      page: () => const ConchasView(),
      transition: Transition.rightToLeft,
    ),

    // =================== PERFIL E EQUIPA ===================
    GetPage(
      name: '/profile',
      page: () => const ProfileView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/delete-account',
      page: () => const DeleteAccountView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/team-customization',
      page: () => const TeamCustomizationView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/team-profile',
      page: () => const TeamProfileView(),
      transition: Transition.rightToLeft,
    ),

    // =================== RANKING E RESULTADOS ===================
    GetPage(
      name: '/ranking',
      page: () => const RankingView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/resultados-finais',
      page: () => const ResultadosFinaisView(),
      transition: Transition.rightToLeft,
    ),

    // =================== EVENTOS ===================
    GetPage(
      name: '/my-events',
      page: () => const UserEventsView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/event-details',
      page: () => const EventDetailsView(),
      transition: Transition.rightToLeft,
    ),

    // =================== CONFIGURAÇÕES E LEGAIS ===================
    GetPage(
      name: '/terms',
      page: () => const TermsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: '/privacy',
      page: () => const PrivacyPolicyScreen(),
      transition: Transition.rightToLeft,
    ),

    // =================== DIALOGS E COMPONENTES ===================
    GetPage(
      name: '/checkpoints-list',
      page: () => RouteHelpers.buildCheckpointsListDialog(),
      transition: Transition.fadeIn,
    ),

    // =================== PÁGINA 404 ===================
    GetPage(
      name: '/not-found',
      page: () => const NotFoundPage(),
      transition: Transition.fadeIn,
    ),
  ];
}

// Middleware para proteção de rotas admin
class AdminMiddleware extends GetMiddleware {
  @override
  redirect(String? route) {
    // Implementar verificação de permissão admin
    // Por enquanto, retorna null para permitir acesso
    return null;
  }
}

// Middleware para proteção de rotas staff
class StaffMiddleware extends GetMiddleware {
  @override
  redirect(String? route) {
    // Implementar verificação de permissão staff
    // Por enquanto, retorna null para permitir acesso
    return null;
  }
}
