import 'package:flutter/material.dart';

/// Design tokens untuk BinoExam Siswa (Flutter)
/// Mengacu 100% pada DESIGN-SYSTEM.md
class AppTokens {
  AppTokens._();

  // ---------- COLORS ----------
  static const Color navy = Color(0xFF1E3A8A);
  static const Color primary = Color(0xFF1D4ED8);
  static const Color blue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFF93C5FD);
  static const Color softBlue = Color(0xFFDBEAFE);

  static const Color yellow = Color(0xFFFBBF24);
  static const Color mint = Color(0xFF34D399);
  static const Color coral = Color(0xFFFB7185);

  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color text = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textDisabled = Color(0xFF94A3B8);

  // ---------- SEMANTIC ----------
  static const Color success = mint;
  static const Color warning = yellow;
  static const Color error = coral;
  static const Color info = blue;

  // ---------- STATUS SOAL & SINKRONISASI ----------
  static const Color questionAnswered = primary;
  static const Color questionUnanswered = softBlue;
  static const Color questionFlagged = yellow;
  static const Color questionCurrent = navy;
  static const Color syncPending = yellow;
  static const Color syncDone = mint;
  static const Color syncFailed = coral;

  // ---------- TYPOGRAPHY SIZE ----------
  static const double textXs = 12.0;
  static const double textSm = 14.0;
  static const double textMd = 16.0; // Ukuran teks isi minimal
  static const double textLg = 18.0;
  static const double textXl = 22.0;
  static const double textXxl = 28.0;
  static const double textXxxl = 36.0;
  static const double textQuestion = 18.0;

  // ---------- CORNER RADIUS ----------
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusPill = 999.0;

  // ---------- SPACING ----------
  static const double spaceXxs = 2.0;
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;
  static const double spaceXxl = 32.0;
  static const double spaceXxxl = 48.0;
}

