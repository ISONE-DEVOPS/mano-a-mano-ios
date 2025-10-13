// lib/routes/app_pages_web.dart
import 'package:flutter/material.dart';
import '../views/dashboard/home_view.dart';
import 'package:mano_mano_dashboard/views/admin/admin_view.dart';
// Aqui pode ter imports que (indiretamente) puxam package:web

final webRoutes = <String, WidgetBuilder>{
  '/': (_) => const HomeView(),
  '/admin': (_) => const AdminView(),
  // … rotas web/admin
};
