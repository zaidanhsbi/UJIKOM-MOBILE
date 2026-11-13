import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/device_status_service.dart';
import '../../core/theme/app_tokens.dart';

class DeviceStatusBar extends StatefulWidget {
  const DeviceStatusBar({super.key});

  /// Membuat state untuk bilah status perangkat.
  @override
  State<DeviceStatusBar> createState() => _DeviceStatusBarState();
}

class _DeviceStatusBarState extends State<DeviceStatusBar> {
  final DeviceStatusService _service = DeviceStatusService();
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _batteryTimer;

  bool _isOnline = true;
  BatteryStatusInfo _battery = const BatteryStatusInfo(level: -1, isCharging: false);
  double _brightness = 0.6;

  /// Menginisialisasi listener jaringan, pembacaan baterai berkala, dan nilai kecerahan awal.
  /// Menginisialisasi pemantauan konektivitas, baterai, dan kecerahan layar.
  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _refreshBattery();
    _loadBrightness();
    _batteryTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshBattery(),
    );
  }

  /// Memeriksa status koneksi awal dan mendengarkan perubahan jaringan secara real-time.
  /// Memeriksa status jaringan awal dan memantau perubahannya.
  Future<void> _initConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (!mounted) return;
    setState(() {
      _isOnline = results.any((r) => r != ConnectivityResult.none);
    });

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(() {
        _isOnline = results.any((r) => r != ConnectivityResult.none);
      });
    });
  }

  /// Mengambil persentase dan status pengisian daya baterai terbaru dari perangkat.
  /// Memperbarui informasi persentase dan pengisian baterai perangkat.
  Future<void> _refreshBattery() async {
    final info = await _service.getBatteryInfo();
    if (!mounted) return;
    setState(() {
      _battery = info;
    });
  }

  /// Membaca tingkat kecerahan layar saat ini dari sistem Android.
  /// Memuat tingkat kecerahan layar saat ini.
  Future<void> _loadBrightness() async {
    final value = await _service.getBrightness();
    if (!mounted) return;
    setState(() {
      _brightness = value;
    });
  }

  /// Membuka dialog slider untuk mengatur kecerahan layar dengan batas minimum 15%.
  /// Membuka dialog slider untuk mengatur kecerahan layar.
  Future<void> _openBrightnessDialog() async {
    double tempValue = _brightness.clamp(
      DeviceStatusService.minBrightness,
      DeviceStatusService.maxBrightness,
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final percent = (tempValue * 100).round();
          return AlertDialog(
            backgroundColor: AppTokens.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            ),
            title: const Row(
              children: [
                Icon(
                  LucideIcons.sun,
                  size: 22,
                  color: AppTokens.primary,
                ),
                SizedBox(width: AppTokens.spaceSm),
                Text(
                  'Atur Kecerahan Layar',
                  style: TextStyle(
                    fontSize: AppTokens.textLg,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.navy,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.navy,
                  ),
                ),
                const SizedBox(height: AppTokens.spaceSm),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.sunDim,
                      size: 18,
                      color: AppTokens.textSecondary,
                    ),
                    Expanded(
                      child: Slider(
                        value: tempValue,
                        min: DeviceStatusService.minBrightness,
                        max: DeviceStatusService.maxBrightness,
                        divisions: 17,
                        activeColor: AppTokens.primary,
                        onChanged: (val) {
                          final clamped = val.clamp(
                            DeviceStatusService.minBrightness,
                            DeviceStatusService.maxBrightness,
                          );
                          setDialogState(() => tempValue = clamped);
                          setState(() => _brightness = clamped);
                          _service.setBrightness(clamped);
                        },
                      ),
                    ),
                    const Icon(
                      LucideIcons.sun,
                      size: 20,
                      color: AppTokens.primary,
                    ),
                  ],
                ),
                const Text(
                  'Minimal 15% agar layar tetap terlihat selama ujian.',
                  style: TextStyle(
                    fontSize: AppTokens.textXs,
                    color: AppTokens.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Membersihkan subscription koneksi dan timer baterai saat widget dihancurkan.
  /// Membersihkan timer pemantauan baterai dan langganan konektivitas.
  @override
  void dispose() {
    _connSub?.cancel();
    _batteryTimer?.cancel();
    super.dispose();
  }

  /// Membangun baris status ONLINE/OFFLINE, baterai, dan tombol pengatur kecerahan.
  /// Membangun bilah status perangkat yang menampilkan jaringan, baterai, dan kontrol kecerahan.
  @override
  Widget build(BuildContext context) {
    final batteryColor = _battery.isCharging
        ? AppTokens.success
        : (_battery.level >= 0 && _battery.level <= 20)
            ? AppTokens.error
            : AppTokens.navy;

    final batteryText = _battery.level >= 0 ? '${_battery.level}%' : '--%';
    final brightnessPercent = (_brightness * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceLg,
        vertical: 8,
      ),
      decoration: const BoxDecoration(
        color: AppTokens.surface,
        border: Border(
          bottom: BorderSide(color: AppTokens.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isOnline
                  ? AppTokens.success.withValues(alpha: 0.12)
                  : AppTokens.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isOnline ? LucideIcons.wifi : LucideIcons.wifiOff,
                  size: 14,
                  color: _isOnline ? AppTokens.success : AppTokens.error,
                ),
                const SizedBox(width: 5),
                Text(
                  _isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: AppTokens.textXs,
                    fontWeight: FontWeight.w700,
                    color: _isOnline ? AppTokens.success : AppTokens.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTokens.background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTokens.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _battery.isCharging
                      ? LucideIcons.batteryCharging
                      : LucideIcons.battery,
                  size: 14,
                  color: batteryColor,
                ),
                const SizedBox(width: 5),
                Text(
                  batteryText,
                  style: TextStyle(
                    fontSize: AppTokens.textXs,
                    fontWeight: FontWeight.w700,
                    color: batteryColor,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: _openBrightnessDialog,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTokens.softBlue,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.sun,
                    size: 14,
                    color: AppTokens.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Kecerahan $brightnessPercent%',
                    style: const TextStyle(
                      fontSize: AppTokens.textXs,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
