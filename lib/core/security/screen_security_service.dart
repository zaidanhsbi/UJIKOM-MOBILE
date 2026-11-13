import 'package:flutter/services.dart';

/// Layanan proteksi layar OS (FLAG_SECURE di Android) serta konstanta
/// MethodChannel bersama untuk fitur keamanan perangkat BinoExam.
class ScreenSecurityService {
  ScreenSecurityService._();

  static const String channelName = 'com.binoexam.app/security';
  static const MethodChannel channel = MethodChannel(channelName);

  /// Mengaktifkan FLAG_SECURE untuk memblokir screenshot dan perekaman layar.
  static Future<void> enableSecureScreen() async {
    try {
      await channel.invokeMethod('enableSecureScreen');
    } on PlatformException {
      // Abaikan pada platform non-Android
    } on MissingPluginException {
      // Abaikan saat pengujian tanpa engine native
    }
  }

  /// Menonaktifkan FLAG_SECURE setelah siswa keluar dari ruang ujian.
  static Future<void> disableSecureScreen() async {
    try {
      await channel.invokeMethod('disableSecureScreen');
    } on PlatformException {
      // Abaikan pada platform non-Android
    } on MissingPluginException {
      // Abaikan saat pengujian tanpa engine native
    }
  }
}
