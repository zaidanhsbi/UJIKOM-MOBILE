import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../domain/entities/exam_models.dart';
import 'custom_button.dart';
import 'custom_card.dart';

/// Kartu informasi satu jadwal ujian siswa beserta tombol aksi mulai pengerjaan.
class ExamCardWidget extends StatelessWidget {
  const ExamCardWidget({
    super.key,
    required this.exam,
    required this.onStart,
  });

  final StudentExamItem exam;
  final VoidCallback? onStart;

  /// Membangun tampilan kartu ujian dengan status berlangsung atau selesai.
  @override
  Widget build(BuildContext context) {
    final canStart = !exam.alreadySubmitted && exam.status == 'ongoing';

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exam.name,
                  style: const TextStyle(
                    fontSize: AppTokens.textLg,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.navy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spaceSm,
                  vertical: AppTokens.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: exam.alreadySubmitted
                      ? AppTokens.success.withValues(alpha: 0.15)
                      : canStart
                          ? AppTokens.softBlue
                          : AppTokens.background,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
                child: Text(
                  exam.alreadySubmitted
                      ? 'Selesai'
                      : canStart
                          ? 'Berlangsung'
                          : exam.status,
                  style: TextStyle(
                    fontSize: AppTokens.textXs,
                    fontWeight: FontWeight.w600,
                    color: exam.alreadySubmitted
                        ? AppTokens.success
                        : AppTokens.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceSm),
          Row(
            children: [
              const Icon(
                LucideIcons.bookOpen,
                size: 24,
                color: AppTokens.textSecondary,
              ),
              const SizedBox(width: AppTokens.spaceXs),
              Expanded(
                child: Text(
                  exam.subjectName,
                  style: const TextStyle(
                    fontSize: AppTokens.textSm,
                    color: AppTokens.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceXs),
          Row(
            children: [
              const Icon(
                LucideIcons.clock,
                size: 24,
                color: AppTokens.textSecondary,
              ),
              const SizedBox(width: AppTokens.spaceXs),
              Text(
                '${exam.durationMinutes} menit • ${exam.questionsCount} soal',
                style: const TextStyle(
                  fontSize: AppTokens.textSm,
                  color: AppTokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceLg),
          if (exam.alreadySubmitted)
            const CustomButton(
              label: 'Sudah Dikumpulkan',
              icon: LucideIcons.checkCircle,
              variant: CustomButtonVariant.secondary,
              onPressed: null,
            )
          else
            CustomButton(
              label: canStart ? 'Kerjakan Ujian' : 'Belum Dibuka',
              icon: LucideIcons.fileEdit,
              onPressed: canStart ? onStart : null,
            ),
        ],
      ),
    );
  }
}

/// Kartu banner untuk melanjutkan sesi ujian yang masih tersimpan di memori lokal perangkat.
class LocalSessionBannerCard extends StatelessWidget {
  const LocalSessionBannerCard({super.key, required this.onResume});

  final VoidCallback onResume;

  /// Membangun tampilan kartu pemberitahuan sesi ujian lokal.
  @override
  Widget build(BuildContext context) {
    return CustomCard(
      backgroundColor: AppTokens.softBlue,
      borderColor: AppTokens.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.hardDrive, size: 24, color: AppTokens.navy),
              SizedBox(width: AppTokens.spaceSm),
              Expanded(
                child: Text(
                  'Ada Sesi Ujian Tersimpan Lokal',
                  style: TextStyle(
                    fontSize: AppTokens.textMd,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceSm),
          const Text(
            'Jawaban Anda sebelumnya masih tersimpan aman di perangkat ini.',
            style: TextStyle(
              fontSize: AppTokens.textSm,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.spaceMd),
          CustomButton(
            label: 'Lanjutkan Ujian Lokal',
            icon: LucideIcons.arrowRight,
            onPressed: onResume,
          ),
        ],
      ),
    );
  }
}

/// Kartu banner untuk menampilkan jumlah ujian yang menunggu sinkronisasi ke server.
class PendingSyncBannerCard extends StatelessWidget {
  const PendingSyncBannerCard({
    super.key,
    required this.pendingCount,
    required this.onSyncNow,
  });

  final int pendingCount;
  final VoidCallback onSyncNow;

  /// Membangun tampilan kartu antrean Pending Sync.
  @override
  Widget build(BuildContext context) {
    return CustomCard(
      backgroundColor: AppTokens.warning.withValues(alpha: 0.15),
      borderColor: AppTokens.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.wifiOff, size: 24, color: AppTokens.warning),
              const SizedBox(width: AppTokens.spaceSm),
              Expanded(
                child: Text(
                  '$pendingCount Ujian Pending Sync',
                  style: const TextStyle(
                    fontSize: AppTokens.textMd,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceXs),
          const Text(
            'Jawaban disimpan lokal dan akan dikirim otomatis saat koneksi pulih.',
            style: TextStyle(
              fontSize: AppTokens.textSm,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.spaceMd),
          CustomButton(
            label: 'Sinkronkan Sekarang',
            icon: LucideIcons.uploadCloud,
            compact: true,
            onPressed: onSyncNow,
          ),
        ],
      ),
    );
  }
}

/// Kartu banner di Dashboard untuk melepas Screen Pinning secara manual setelah sinkronisasi selesai.
class UnpinBannerCard extends StatelessWidget {
  const UnpinBannerCard({super.key, required this.onUnpin});

  final VoidCallback onUnpin;

  /// Membangun tampilan kartu pelepasan Screen Pinning.
  @override
  Widget build(BuildContext context) {
    return CustomCard(
      backgroundColor: AppTokens.success.withValues(alpha: 0.12),
      borderColor: AppTokens.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.shieldCheck, size: 22, color: AppTokens.success),
              SizedBox(width: AppTokens.spaceSm),
              Expanded(
                child: Text(
                  'Screen Pinning Aktif',
                  style: TextStyle(
                    fontSize: AppTokens.textMd,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceXs),
          const Text(
            'Ujian sudah selesai dan tersinkronkan. Tekan tombol di bawah jika Anda ingin melepas kunci layar.',
            style: TextStyle(
              fontSize: AppTokens.textSm,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.spaceMd),
          CustomButton(
            label: 'Lepas Screen Pinning',
            icon: LucideIcons.unlock,
            compact: true,
            onPressed: onUnpin,
          ),
        ],
      ),
    );
  }
}
