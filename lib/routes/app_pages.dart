import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/splash/splash_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/dashboard/home_view.dart';
import '../views/profile/profile_view.dart';
import '../views/checkin/checkin_view.dart';
import '../views/main/main_view.dart';
import '../views/admin/admin_view.dart';
import '../views/payment/payment_view.dart';
import '../views/map/route_map_view.dart';
import '../views/map/event_route_view.dart';
import '../views/admin/route_editor_view.dart';
import '../views/events/user_events_view.dart';
import '../views/auth/forgot_password_view.dart';
import '../views/admin/add_checkpoints_view.dart';
import '../views/terms/terms_screen.dart';
import '../views/privacy/privacy_policy_screen.dart';

class AppPages {
  static const initial = '/';

  static final routes = [
    GetPage(name: '/', page: () => const SplashView()),
    GetPage(name: '/login', page: () => const LoginView()),
    GetPage(name: '/register', page: () => const RegisterView()),
    GetPage(name: '/home', page: () => const HomeView()),
    GetPage(name: '/profile', page: () => const ProfileView()),
    GetPage(name: '/checkin', page: () => const CheckinView()),
    GetPage(name: '/main', page: () => const MainView()),
    GetPage(name: '/admin', page: () => const AdminView()),
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
  ];
}
