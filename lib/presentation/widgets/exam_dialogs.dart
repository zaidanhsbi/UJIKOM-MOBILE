import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/repositories/exam_repository.dart';
import 'custom_button.dart';

/// Dialog konfirmasi saat siswa menekan tombol selesai sebelum waktu habis.
class SubmitExamConfirmDialog extends StatelessWidget {
  const SubmitExamConfirmDialog({
    super.key,
    required this.unansweredCount,
  });

  final int unansweredCount;

  /// Membangun tampilan dialog konfirmasi pengumpulan jawaban.
  /// Membangun dialog konfirmasi pengumpulan jawaban ujian.
  @override
  Widget build(BuildContext context) {
    final hasUnanswered = unansweredCount > 0;

    return AlertDialog(
      backgroundColor: AppTokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      ),
      title: const Row(
        children: [
          Icon(LucideIcons.helpCircle, size: 24, color: AppTokens.navy),
          SizedBox(width: AppTokens.spaceSm),
          Expanded(
            child: Text(
              'Kumpulkan Ujian?',
              style: TextStyle(
                fontSize: AppTokens.textLg,
                fontWeight: FontWeight.w700,
                color: AppTokens.navy,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        hasUnanswered
            ? 'Masih ada $unansweredCount soal yang belum dijawab! Pastikan Anda sudah memeriksa kembali sebelum mengumpulkan.'
            : 'Semua soal sudah terjawab. Yakin ingin mengakhiri dan mengumpulkan ujian sekarang?',
        style: TextStyle(
          fontSize: AppTokens.textMd,
          color: hasUnanswered ? AppTokens.error : AppTokens.textSecondary,
          fontWeight: hasUnanswered ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      actions: [
        CustomButton(
          label: 'Kembali',
          variant: CustomButtonVariant.secondary,
          fullWidth: false,
          compact: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        CustomButton(
          label: 'Ya, Selesai',
          icon: LucideIcons.send,
          variant: hasUnanswered
              ? CustomButtonVariant.danger
              : CustomButtonVariant.primary,
          fullWidth: false,
          compact: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// Dialog wajib saat waktu ujian habis yang menahan siswa hingga jawaban berhasil disinkronkan.
class TimeoutSyncDialog extends StatefulWidget {
  const TimeoutSyncDialog({
    super.key,
    required this.onSyncAttempt,
    required this.onSyncSuccess,
  });

  final Future<ExamSubmitResult> Function() onSyncAttempt;
  final Future<void> Function(ExamSubmitResult result) onSyncSuccess;

  /// Membuat state untuk dialog sinkronisasi waktu habis.
  @override
  State<TimeoutSyncDialog> createState() => _TimeoutSyncDialogState();
}

class _TimeoutSyncDialogState extends State<TimeoutSyncDialog> {
  bool _syncing = false;
  String? _statusMessage;

  /// Menjalankan percobaan pengiriman dan sinkronisasi jawaban ke server.
  /// Menjalankan proses pengiriman ulang jawaban saat tombol sinkronisasi ditekan.
  Future<void> _handleSync() async {
    setState(() {
      _syncing = true;
    });

    final result = await widget.onSyncAttempt();
    if (!mounted) return;

    if (result.synced) {
      Navigator.of(context).pop();
      await widget.onSyncSuccess(result);
    } else {
      setState(() {
        _syncing = false;
        _statusMessage = result.message;
      });
    }
  }

  /// Membangun tampilan dialog peringatan waktu habis dan tombol sinkronisasi.
  /// Membangun dialog peringatan waktu ujian habis beserta tombol sinkronisasi ulang.
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        ),
        title: const Row(
          children: [
            Icon(LucideIcons.clock, size: 24, color: AppTokens.error),
            SizedBox(width: AppTokens.spaceSm),
            Expanded(
              child: Text(
                'Waktu Ujian Habis',
                style: TextStyle(
                  fontSize: AppTokens.textLg,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.error,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Waktu pengerjaan telah berakhir. Silakan sync dan kumpulkan jawaban Anda terlebih dahulu. Screen Pinning akan tetap aktif hingga jawaban berhasil tersinkronkan.',
              style: TextStyle(
                fontSize: AppTokens.textMd,
                color: AppTokens.textSecondary,
                height: 1.4,
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: AppTokens.spaceMd),
              Container(
                padding: const EdgeInsets.all(AppTokens.spaceMd),
                decoration: BoxDecoration(
                  color: AppTokens.warning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(color: AppTokens.warning),
                ),
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(
                    fontSize: AppTokens.textSm,
                    color: AppTokens.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          CustomButton(
            label: _statusMessage == null
                ? 'Sync & Kumpulkan Jawaban'
                : 'Coba Sync Lagi',
            icon: LucideIcons.uploadCloud,
            loading: _syncing,
            onPressed: _syncing ? null : _handleSync,
          ),
        ],
      ),
    );
  }
}

/// Overlay layar penuh yang muncul ketika terdeteksi pelanggaran perpindahan aplikasi selama ujian.
class ExamViolationOverlay extends StatelessWidget {
  const ExamViolationOverlay({
    super.key,
    required this.violationCount,
    required this.onDismiss,
  });

  final int violationCount;
  final VoidCallback onDismiss;

  /// Membangun tampilan peringatan pelanggaran keamanan ujian.
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: AppTokens.navy.withValues(alpha: 0.96),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceXxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.shieldAlert,
                  size: 24,
                  color: AppTokens.warning,
                ),
                const SizedBox(height: AppTokens.spaceLg),
                const Text(
                  'Peringatan Keamanan Ujian!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTokens.textXxl,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.white,
                  ),
                ),
                const SizedBox(height: AppTokens.spaceMd),
                Text(
                  'Anda terdeteksi meninggalkan layar ujian atau membuka aplikasi lain.\nTotal pelanggaran tercatat: $violationCount kali.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppTokens.textMd,
                    color: AppTokens.white,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppTokens.spaceXxl),
                CustomButton(
                  label: 'Saya Mengerti, Kembali ke Ujian',
                  icon: LucideIcons.shieldCheck,
                  onPressed: onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
