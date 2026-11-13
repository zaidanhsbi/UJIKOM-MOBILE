import 'dart:io';
import 'package:flutter/services.dart';
import '../security/screen_security_service.dart';

/// Layanan komunikasi MethodChannel untuk mengelola Screen Pinning (Lock Task) di Android.
class ScreenPinningService {
  static const MethodChannel _channel = ScreenSecurityService.channel;

  /// Memeriksa apakah aplikasi saat ini sedang berada dalam mode Screen Pinning.
  Future<bool> isScreenPinned() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('isScreenPinned');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Meminta sistem Android mengaktifkan Screen Pinning dan menunggu verifikasi statusnya.
  Future<bool> requestPinScreen() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('startLockTask');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Melepas mode Screen Pinning setelah ujian selesai dan tersinkronisasi.
  Future<bool> stopPinScreen() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('stopLockTask');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Membuka halaman Pengaturan Keamanan Android agar pengguna dapat mengaktifkan fitur Sematkan Layar.
  Future<void> openSecuritySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('openSecuritySettings');
    } on PlatformException {
      // ignore
    } on MissingPluginException {
      // ignore
    }
  }
}
