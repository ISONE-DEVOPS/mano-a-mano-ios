// lib/routes/app_pages_mobile.dart
import 'package:flutter/material.dart';
import '../views/dashboard/home_view.dart';
// !! NÃO importe nada de views/admin nem package:web aqui !!

final appRoutes = <String, WidgetBuilder>{
  '/': (_) => const HomeView(),
  // … outras rotas mobile
};
