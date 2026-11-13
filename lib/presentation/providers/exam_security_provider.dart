import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/screen_pinning_service.dart';

final screenPinningServiceProvider = Provider<ScreenPinningService>((ref) {
  return ScreenPinningService();
});

/// StateNotifier yang memantau dan mengelola status aktif Screen Pinning secara berkala.
class ExamSecurityNotifier extends StateNotifier<bool> with WidgetsBindingObserver {
  ExamSecurityNotifier(this._service) : super(false) {
    WidgetsBinding.instance.addObserver(this);
    checkPinStatus();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      checkPinStatus();
    });
  }

  final ScreenPinningService _service;
  Timer? _timer;

  /// Memperbarui state berdasarkan status terkini Screen Pinning dari sistem Android.
  Future<void> checkPinStatus() async {
    final pinned = await _service.isScreenPinned();
    if (mounted && pinned != state) {
      state = pinned;
    }
  }

  /// Meminta aktivasi Screen Pinning dan memverifikasi bahwa aplikasi benar-benar sudah terkunci.
  Future<bool> requestPinScreen() async {
    final ok = await _service.requestPinScreen();
    await checkPinStatus();
    return ok && state;
  }

  /// Melepas mode Screen Pinning dan memperbarui status state.
  Future<bool> stopPinScreen() async {
    final ok = await _service.stopPinScreen();
    await checkPinStatus();
    return ok;
  }

  /// Membuka pengaturan keamanan perangkat jika Screen Pinning belum diaktifkan di sistem.
  Future<void> openSecuritySettings() async {
    await _service.openSecuritySettings();
  }

  /// Memeriksa ulang status Screen Pinning saat aplikasi kembali ke foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkPinStatus();
    }
  }

  /// Membersihkan observer lifecycle dan timer periodik saat notifier dihancurkan.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}

final examSecurityProvider = StateNotifierProvider<ExamSecurityNotifier, bool>((ref) {
  return ExamSecurityNotifier(ref.watch(screenPinningServiceProvider));
});
