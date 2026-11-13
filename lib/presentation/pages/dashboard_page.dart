import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../domain/entities/exam_models.dart';
import '../providers/auth_provider.dart';
import '../providers/exam_provider.dart';
import '../providers/exam_security_provider.dart';
import '../widgets/custom_card.dart';
import '../widgets/device_status_bar.dart';
import '../widgets/exam_card_widget.dart';
import '../widgets/exam_token_dialog.dart';
import '../widgets/pin_prompt_dialog.dart';

/// Halaman utama siswa untuk melihat daftar jadwal ujian dan mengelola sesi pengerjaan.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  /// Membuat state untuk halaman dashboard siswa.
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  /// Memuat daftar jadwal ujian dari server saat halaman pertama kali dibuka.
  /// Memuat daftar ujian saat halaman dashboard pertama kali dibuka.
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(examListProvider.notifier).loadExams();
    });
  }

  /// Memastikan Screen Pinning sudah aktif sebelum mengizinkan siswa memulai ujian.
  /// Memastikan perangkat berada dalam mode Screen Pinning sebelum memulai ujian.
  Future<bool> _ensureScreenPinned() async {
    await ref.read(examSecurityProvider.notifier).checkPinStatus();
    if (ref.read(examSecurityProvider)) {
      return true;
    }
    if (!mounted) return false;

    final agreed = await showDialog<bool>(
      context: context,
      builder: (_) => const PinPromptDialog(),
    );

    if (agreed != true || !mounted) {
      return false;
    }

    final pinned = await ref
        .read(examSecurityProvider.notifier)
        .requestPinScreen();
    if (!mounted) return false;

    if (!pinned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Screen Pinning belum aktif atau dibatalkan. Ujian tidak dapat dimulai.',
          ),
          backgroundColor: AppTokens.error,
          action: SnackBarAction(
            label: 'Pengaturan',
            textColor: AppTokens.white,
            onPressed: () {
              ref.read(examSecurityProvider.notifier).openSecuritySettings();
            },
          ),
        ),
      );
      return false;
    }

    return true;
  }

  /// Menangani klik tombol mulai ujian dengan membuka dialog token terlebih dahulu.
  /// Menangani ketukan tombol mulai ujian dengan memeriksa status Screen Pinning terlebih dahulu.
  Future<void> _handleExamStartTap(StudentExamItem exam) async {
    await _showTokenDialog(exam);
  }

  /// Melanjutkan sesi ujian yang tersimpan di lokal setelah memastikan Screen Pinning aktif.
  /// Melanjutkan ujian yang tersimpan secara lokal setelah memastikan Screen Pinning aktif.
  Future<void> _resumeLocalExam(int examId) async {
    final pinned = await _ensureScreenPinned();
    if (!pinned || !mounted) return;
    ref.read(activeExamProvider.notifier).resumeFromLocal(examId);
    context.go('/exam/$examId');
  }

  /// Menampilkan dialog token ujian, meminta aktivasi Screen Pinning, lalu mengunduh soal.
  /// Menampilkan dialog input token ujian dan memulai sesi ujian jika token valid.
  Future<void> _showTokenDialog(StudentExamItem exam) async {
    final confirmedToken = await showDialog<String>(
      context: context,
      builder: (_) => ExamTokenDialog(exam: exam),
    );

    if (confirmedToken == null || !mounted) return;

    final pinned = await _ensureScreenPinned();
    if (!pinned || !mounted) return;

    final ok = await ref
        .read(activeExamProvider.notifier)
        .startOrResumeExam(exam.id, confirmedToken);

    if (!mounted) return;

    if (ok) {
      context.go('/exam/${exam.id}');
    } else {
      final err = ref.read(activeExamProvider).error ?? 'Gagal memulai ujian.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppTokens.error,
        ),
      );
    }
  }

  /// Membangun tampilan daftar ujian beserta kartu status sinkronisasi lokal.
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final examState = ref.watch(examListProvider);
    final isPinned = ref.watch(examSecurityProvider);
    final activeCachedId = ref.watch(examRepositoryProvider).getActiveExamId();

    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        backgroundColor: AppTokens.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Ujian',
              style: TextStyle(
                fontSize: AppTokens.textLg,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Text(
              user?.name ?? 'Siswa',
              style: const TextStyle(
                fontSize: AppTokens.textXs,
                color: AppTokens.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat Ulang',
            onPressed: () => ref.read(examListProvider.notifier).loadExams(),
            icon: const Icon(LucideIcons.refreshCw, size: 24, color: Colors.black),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(LucideIcons.logOut, size: 24, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          const DeviceStatusBar(),
          if (isPinned && examState.pendingSyncCount == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.spaceLg,
                AppTokens.spaceMd,
                AppTokens.spaceLg,
                0,
              ),
              child: UnpinBannerCard(
                onUnpin: () =>
                    ref.read(examSecurityProvider.notifier).stopPinScreen(),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(examListProvider.notifier).loadExams(),
              child: ListView(
                padding: const EdgeInsets.all(AppTokens.spaceLg),
                children: [
                  if (activeCachedId != null) ...[
                    LocalSessionBannerCard(
                      onResume: () => _resumeLocalExam(activeCachedId),
                    ),
                    const SizedBox(height: AppTokens.spaceLg),
                  ],
                  if (examState.pendingSyncCount > 0) ...[
                    PendingSyncBannerCard(
                      pendingCount: examState.pendingSyncCount,
                      onSyncNow: () =>
                          ref.read(examListProvider.notifier).syncPendingNow(),
                    ),
                    const SizedBox(height: AppTokens.spaceLg),
                  ],
                  if (examState.syncNotice != null) ...[
                    _StatusNoticeCard(
                      message: examState.syncNotice!,
                      icon: LucideIcons.checkCircle2,
                      color: AppTokens.success,
                      textColor: AppTokens.navy,
                    ),
                    const SizedBox(height: AppTokens.spaceLg),
                  ],
                  if (examState.error != null) ...[
                    _StatusNoticeCard(
                      message: examState.error!,
                      icon: LucideIcons.alertTriangle,
                      color: AppTokens.error,
                      textColor: AppTokens.error,
                    ),
                    const SizedBox(height: AppTokens.spaceLg),
                  ],
                  if (examState.loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppTokens.spaceXxl),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (examState.exams.isEmpty)
                    const CustomCard(
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.clipboardList,
                            size: 24,
                            color: AppTokens.textDisabled,
                          ),
                          SizedBox(height: AppTokens.spaceSm),
                          Text(
                            'Belum ada jadwal ujian aktif saat ini.',
                            style: TextStyle(
                              fontSize: AppTokens.textMd,
                              color: AppTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...examState.exams.map(
                      (exam) => Padding(
                        padding: const EdgeInsets.only(bottom: AppTokens.spaceMd),
                        child: ExamCardWidget(
                          exam: exam,
                          onStart: () => _handleExamStartTap(exam),
                        ),
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

/// Kartu notifikasi ringkas untuk menampilkan pesan sukses sinkronisasi atau error.
class _StatusNoticeCard extends StatelessWidget {
  const _StatusNoticeCard({
    required this.message,
    required this.icon,
    required this.color,
    required this.textColor,
  });

  final String message;
  final IconData icon;
  final Color color;
  final Color textColor;

  /// Membangun tampilan kartu pesan status.
  @override
  Widget build(BuildContext context) {
    return CustomCard(
      backgroundColor: color.withValues(alpha: 0.14),
      borderColor: color,
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: AppTokens.spaceSm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: AppTokens.textSm,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
