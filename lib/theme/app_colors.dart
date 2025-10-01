import 'package:flutter/material.dart';

class AppColors {
  // Cores principais da marca
  static const Color primary = Color(0xFFFF6600); // Mano Orange
  static const Color primaryDark = Color(0xFFCC5200); // Mano Orange Dark
  static const Color secondary = Color(0xFF000000); // Preto
  static const Color secondaryDark = Color(0xFF121212); // Preto profundo
  static const Color accent = Color(0xFFFF7A33); // Mano Orange Light

  // Fundo e superfícies
  static const Color background = Color(0xFF000000); // Preto
  static const Color surface = Color(0xFF121212); // Superfície escura
  static const Color surfaceSecondary = Color(
    0xFF1E1E1E,
  ); // Superfície escura secundária

  // Texto (usado sobre fundo e surface amarelo claro)
  static const Color textPrimary = Color(0xFFFFFFFF); // Branco total
  static const Color textSecondary = Color(
    0xFFE6E6E6,
  ); // Cinza claro para contraste

  // Campos de input
  static const Color inputBackground = Color(0xFF1E1E1E); // Campo em dark
  static const Color inputText = Color(0xFFFFFFFF); // Texto em dark
  static const Color inputBorder = Color(0xFF2A2A2A); // borda discreta em dark

  // Outros
  static const Color error = Color(0xFFD32F2F); // erro
  static const Color success = Color(0xFF4CAF50); // sucesso
  static const Color warning = Color(0xFFFFA000); // aviso

  // Estilo padrão para ElevatedButton (exemplo de uso)
  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.black,
    textStyle: const TextStyle(fontWeight: FontWeight.bold),
  );

  static ButtonStyle cancelButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: surfaceSecondary,
    foregroundColor: textSecondary,
    textStyle: const TextStyle(fontWeight: FontWeight.bold),
  );

  static ButtonStyle dialogButtonStyle = TextButton.styleFrom(
    foregroundColor: textPrimary,
    textStyle: const TextStyle(fontWeight: FontWeight.normal),
  );
}
