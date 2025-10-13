import 'package:get/get.dart';

// Views Admin (as mesmas que estavam no app_pages.dart)
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
import '../views/admin/report_geral_view.dart';
import '../views/admin/donation_pagali_view.dart';
import '../views/admin/user_management_view.dart';
import '../views/admin/participantes_por_evento_view.dart';

// Utils usados por algumas rotas admin
import '../utils/route_helpers.dart';

/// Se preferir aplicar guards aqui, pode definir um middleware simples local.
/// Ter o mesmo nome em libs diferentes não é problema.
class AdminMiddleware extends GetMiddleware {
  @override
  redirect(String? route) => null;
}

final adminRoutes = <GetPage<dynamic>>[
  GetPage(
    name: '/loading-admin',
    page: () => const LoadingAdminView(),
    transition: Transition.fadeIn,
  ),
  GetPage(
    name: '/admin',
    page: () => const AdminView(),
    transition: Transition.fadeIn,
    middlewares: [AdminMiddleware()],
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
    page: () => const UserManagementView(),
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
    name: '/participantesPorEvento',
    page: () => const ParticipantesPorEventoView(),
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
  GetPage(
    name: '/user_management',
    page: () => const UserManagementView(),
    transition: Transition.rightToLeft,
    middlewares: [AdminMiddleware()],
  ),
  GetPage(
    name: '/donations',
    page: () => const DonationShellScreen(),
    transition: Transition.rightToLeft,
    middlewares: [AdminMiddleware()],
  ),
];
