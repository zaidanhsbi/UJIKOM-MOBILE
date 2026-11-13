import 'dart:io';
import 'package:flutter/services.dart';
import '../security/screen_security_service.dart';

/// Model informasi kapasitas dan status pengisian daya baterai perangkat.
class BatteryStatusInfo {
  const BatteryStatusInfo({
    required this.level,
    required this.isCharging,
  });

  final int level;
  final bool isCharging;
}

/// Layanan untuk membaca informasi baterai serta mengatur kecerahan layar dengan batas aman minimum.
class DeviceStatusService {
  static const MethodChannel _channel = ScreenSecurityService.channel;
  static const double minBrightness = 0.15;
  static const double maxBrightness = 1.0;
  static const double defaultBrightness = 0.5;

  /// Mengambil persentase baterai dan status pengisian daya dari sistem Android.
  Future<BatteryStatusInfo> getBatteryInfo() async {
    if (!Platform.isAndroid) {
      return const BatteryStatusInfo(level: -1, isCharging: false);
    }

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getBatteryInfo');
      if (result == null) {
        return const BatteryStatusInfo(level: -1, isCharging: false);
      }
      final level = (result['level'] as num?)?.toInt() ?? -1;
      final isCharging = result['isCharging'] as bool? ?? false;
      return BatteryStatusInfo(level: level, isCharging: isCharging);
    } on PlatformException {
      return const BatteryStatusInfo(level: -1, isCharging: false);
    } on MissingPluginException {
      return const BatteryStatusInfo(level: -1, isCharging: false);
    }
  }

  /// Mengambil nilai kecerahan layar saat ini dalam rentang [minBrightness] hingga [maxBrightness].
  Future<double> getBrightness() async {
    if (!Platform.isAndroid) {
      return 0.7;
    }

    try {
      final result = await _channel.invokeMethod<double>('getBrightness');
      return (result ?? defaultBrightness).clamp(minBrightness, maxBrightness);
    } on PlatformException {
      return defaultBrightness;
    } on MissingPluginException {
      return defaultBrightness;
    }
  }

  /// Mengatur kecerahan layar aplikasi dengan pembatasan minimum 15% agar layar tidak gelap total.
  Future<void> setBrightness(double level) async {
    if (!Platform.isAndroid) return;
    final clamped = level.clamp(minBrightness, maxBrightness);
    try {
      await _channel.invokeMethod<bool>('setBrightness', {'level': clamped});
    } on PlatformException {
      // ignore
    } on MissingPluginException {
      // ignore
    }
  }
}
