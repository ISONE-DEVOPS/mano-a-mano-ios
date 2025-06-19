import 'package:flutter/material.dart';

class AppColors {
  // Cores principais da marca
  static const Color primary = Color(0xFFDD1D21); // Shell Red 500
  static const Color primaryDark = Color(0xFF990000); // Shell Red 700
  static const Color secondary = Color(0xFFFFC600); // Shell Yellow 200
  static const Color secondaryDark = Color(0xFF956F00); // Shell Yellow 500
  static const Color accent = Color(0xFFED8A00); // Sunrise 300

  // Fundo e superfícies
  static const Color background = Color(0xFFFFFBE6); // Amarelo bem clarinho
  static const Color surface = Color(0xFFFFFBE6); // Amarelo bem clarinho
  static const Color surfaceSecondary = Color(
    0xFFFFFBE6,
  ); // Amarelo bem clarinho

  // Texto (usado sobre fundo e surface amarelo claro)
  static const Color textPrimary = Color(0xFF000000); // Preto total
  static const Color textSecondary = Color(
    0xFF333333,
  ); // Cinza escuro para contraste

  // Campos de input
  static const Color inputBackground = Color(0xFFF5F5F5); // Shell Grey 50
  static const Color inputText = Color(0xFF000000); // Texto primário
  static const Color inputBorder = Color(0xFFDDDDDD); // cinza claro para borda

  // Outros
  static const Color error = Color(0xFFD32F2F); // vermelho de erro
  static const Color success = Color(0xFF4CAF50); // verde de sucesso
  static const Color warning = Color(0xFFFFA000); // amarelo de aviso

  // Estilo padrão para ElevatedButton (exemplo de uso)
  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: secondary,
    foregroundColor: textPrimary,
    textStyle: const TextStyle(fontWeight: FontWeight.bold),
  );

  static ButtonStyle cancelButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    textStyle: const TextStyle(fontWeight: FontWeight.bold),
  );

  static ButtonStyle dialogButtonStyle = TextButton.styleFrom(
    foregroundColor: textPrimary,
    textStyle: const TextStyle(fontWeight: FontWeight.normal),
  );
}
