import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFDD1D21); // Shell Red
  static const Color secondary = Color(0xFFFFC600); // Shell Yellow
  static const Color background = Color(0xFFFFF3E5); // Sunrise 50
  static const Color text = Colors.black87;
}

class AppBackendTheme {
  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: Colors.grey.shade100,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Colors.grey.shade100,
        //error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
        titleLarge: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Color(0xFF1E1E1E),
        // background removed (deprecated, surface is sufficient)
        //error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
        titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.background,
        //error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColors.text,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.text, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.text, fontSize: 14),
        titleLarge: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.all(AppColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        labelStyle: const TextStyle(color: AppColors.text),
        hintStyle: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Color(0xFF1E1E1E),
        //error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
        titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.all(AppColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
    );
  }
}
