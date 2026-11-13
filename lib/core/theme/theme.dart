import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_tokens.dart';

class AppTheme {
  AppTheme._();

  /// Mengembalikan konfigurasi tema terang utama aplikasi.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: AppTokens.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTokens.primary,
          primary: AppTokens.primary,
          secondary: AppTokens.blue,
          error: AppTokens.error,
          surface: AppTokens.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTokens.surface,
          foregroundColor: AppTokens.navy,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shape: Border(
            bottom: BorderSide(color: AppTokens.border, width: 1),
          ),
        ),
        dividerColor: AppTokens.border,
      );
}
