import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/security/screen_security_service.dart';
import '../../core/theme/app_tokens.dart';
import '../providers/exam_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/device_status_bar.dart';
import '../widgets/exam_dialogs.dart';
import '../widgets/question_answer_section.dart';
import '../widgets/question_grid_sheet.dart';

/// Halaman ruang pengerjaan ujian dengan proteksi layar dan penyimpanan jawaban lokal (offline-first).
class ExamRoomPage extends ConsumerStatefulWidget {
  const ExamRoomPage({super.key, required this.examId});

  final int examId;

  /// Membuat state untuk halaman ruang ujian.
  @override
  ConsumerState<ExamRoomPage> createState() => _ExamRoomPageState();
}

class _ExamRoomPageState extends ConsumerState<ExamRoomPage>
    with WidgetsBindingObserver {
  static const int _lowTimeWarningSeconds = 300;
  final TextEditingController _essayController = TextEditingController();
  bool _autoSubmitted = false;

  /// Mengaktifkan observer lifecycle serta proteksi screenshot saat memasuki ruang ujian.
  /// Mengaktifkan pengaman layar, observer lifecycle, dan memulihkan sesi ujian lokal.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ScreenSecurityService.enableSecureScreen();

    Future.microtask(() {
      final current = ref.read(activeExamProvider);
      if (current.package?.examId != widget.examId) {
        ref.read(activeExamProvider.notifier).resumeFromLocal(widget.examId);
      }
      _syncEssayController();
    });
  }

  /// Menonaktifkan proteksi screenshot dan membersihkan resource saat halaman ditutup.
  /// Melepas observer lifecycle, controller uraian, dan proteksi layar saat keluar.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ScreenSecurityService.disableSecureScreen();
    _essayController.dispose();
    super.dispose();
  }

  /// Mencatat pelanggaran apabila aplikasi kehilangan fokus atau masuk ke background selama ujian.
  /// Mencatat pelanggaran jika siswa meninggalkan atau meminimalkan aplikasi saat ujian berlangsung.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(activeExamProvider.notifier).recordLifecycleViolation(
            'Terdeteksi berpindah aplikasi atau membuka split-screen ($state)',
          );
    }
  }

  /// Menyinkronkan isi TextField uraian ketika siswa berpindah ke soal bertipe uraian.
  /// Menyelaraskan teks pada controller uraian dengan jawaban soal yang sedang aktif.
  void _syncEssayController() {
    final examState = ref.read(activeExamProvider);
    final pkg = examState.package;
    if (pkg == null || pkg.questions.isEmpty) return;
    final question = pkg.questions[examState.currentIndex];
    if (question.type == 'ur') {
      final ans = examState.answers[question.id]?.answer?.toString() ?? '';
      if (_essayController.text != ans) {
        _essayController.text = ans;
      }
    }
  }

  /// Memformat sisa waktu detik menjadi string jam:menit:detik (`HH:MM:SS` atau `MM:SS`).
  /// Memformat sisa waktu ujian dalam detik menjadi string `HH:MM:SS` atau `MM:SS`.
  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;
    final mm = mins.toString().padLeft(2, '0');
    final ss = secs.toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$mm:$ss';
    }
    return '$mm:$ss';
  }

  /// Membuka bottom sheet navigasi nomor soal.
  /// Membuka bottom sheet navigasi nomor soal beserta status jawabannya.
  void _openQuestionGridSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusLg),
        ),
      ),
      builder: (_) => QuestionGridSheet(
        onQuestionSelected: (index) {
          ref.read(activeExamProvider.notifier).goToQuestion(index);
          _syncEssayController();
        },
      ),
    );
  }

  /// Menampilkan konfirmasi pengumpulan ujian, mengirim jawaban, lalu kembali ke Dashboard.
  /// Menampilkan dialog konfirmasi lalu mengirimkan jawaban ujian ke server.
  Future<void> _confirmAndSubmit() async {
    final examState = ref.read(activeExamProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => SubmitExamConfirmDialog(
        unansweredCount: examState.unansweredCount,
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await ref.read(activeExamProvider.notifier).submitExam();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.synced ? AppTokens.success : AppTokens.warning,
      ),
    );

    await ref.read(examListProvider.notifier).loadExams();
    if (mounted) {
      context.go('/dashboard');
    }
  }

  /// Menampilkan dialog wajib sinkronisasi ketika waktu pengerjaan ujian telah habis.
  /// Mengirimkan jawaban otomatis ketika waktu ujian habis dan menampilkan hasil sinkronisasi.
  Future<void> _showTimeoutSyncDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TimeoutSyncDialog(
        onSyncAttempt: () => ref.read(activeExamProvider.notifier).submitExam(),
        onSyncSuccess: (result) async {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppTokens.success,
            ),
          );
          await ref.read(examListProvider.notifier).loadExams();
          if (mounted) {
            context.go('/dashboard');
          }
        },
      ),
    );
  }

  /// Membangun tampilan halaman ruang ujian beserta navigasi soal dan overlay keamanan.
  /// Membangun tampilan ruang ujian lengkap dengan header timer, soal, navigasi, dan overlay keamanan.
  @override
  Widget build(BuildContext context) {
    final examState = ref.watch(activeExamProvider);
    final pkg = examState.package;

    ref.listen<int>(
      activeExamProvider.select((s) => s.remainingSeconds),
      (prev, next) {
        if (!_autoSubmitted && prev != null && prev > 0 && next == 0) {
          _autoSubmitted = true;
          _showTimeoutSyncDialog();
        }
      },
    );

    if (pkg == null || pkg.questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppTokens.background,
        appBar: AppBar(title: const Text('Ruang Ujian')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceXl),
            child: CustomCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Paket soal belum dimuat atau kosong.',
                    style: TextStyle(fontSize: AppTokens.textMd),
                  ),
                  const SizedBox(height: AppTokens.spaceLg),
                  CustomButton(
                    label: 'Kembali ke Dashboard',
                    onPressed: () => context.go('/dashboard'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final currentQuestion = pkg.questions[examState.currentIndex];
    final answerEntry = examState.answers[currentQuestion.id];
    final isLowTime = examState.remainingSeconds <= _lowTimeWarningSeconds;
    final isLast = examState.currentIndex == pkg.questions.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gunakan tombol Selesai untuk mengakhiri ujian.'),
            ),
          );
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppTokens.background,
            appBar: AppBar(
              backgroundColor: AppTokens.surface,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pkg.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppTokens.textMd,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.navy,
                    ),
                  ),
                  Text(
                    'Soal ${examState.currentIndex + 1} dari ${pkg.questions.length}',
                    style: const TextStyle(
                      fontSize: AppTokens.textXs,
                      color: AppTokens.textSecondary,
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: AppTokens.spaceSm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceMd,
                    vertical: AppTokens.spaceXs,
                  ),
                  decoration: BoxDecoration(
                    color: isLowTime
                        ? AppTokens.error.withValues(alpha: 0.12)
                        : AppTokens.softBlue,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.timer,
                        size: 24,
                        color: isLowTime ? AppTokens.error : AppTokens.navy,
                      ),
                      const SizedBox(width: AppTokens.spaceXs),
                      Text(
                        _formatDuration(examState.remainingSeconds),
                        style: TextStyle(
                          fontSize: AppTokens.textMd,
                          fontWeight: FontWeight.w700,
                          color: isLowTime ? AppTokens.error : AppTokens.navy,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Daftar Soal',
                  onPressed: _openQuestionGridSheet,
                  icon: const Icon(
                    LucideIcons.layoutGrid,
                    size: 24,
                    color: AppTokens.navy,
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                const DeviceStatusBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTokens.spaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        QuestionStemCard(
                          questionNumber: examState.currentIndex + 1,
                          question: currentQuestion,
                          isFlagged: answerEntry?.flagged == true,
                          onToggleFlag: () => ref
                              .read(activeExamProvider.notifier)
                              .toggleFlag(currentQuestion.id),
                        ),
                        const SizedBox(height: AppTokens.spaceLg),
                        QuestionAnswerSection(
                          question: currentQuestion,
                          currentAnswer: answerEntry?.answer,
                          essayController: _essayController,
                          onAnswerChanged: (val) {
                            ref
                                .read(activeExamProvider.notifier)
                                .setAnswer(currentQuestion.id, val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppTokens.spaceMd),
                  decoration: const BoxDecoration(
                    color: AppTokens.surface,
                    border: Border(top: BorderSide(color: AppTokens.border)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            label: 'Sebelumnya',
                            icon: LucideIcons.chevronLeft,
                            variant: CustomButtonVariant.secondary,
                            compact: true,
                            onPressed: examState.currentIndex > 0
                                ? () {
                                    ref
                                        .read(activeExamProvider.notifier)
                                        .goToQuestion(
                                          examState.currentIndex - 1,
                                        );
                                    _syncEssayController();
                                  }
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppTokens.spaceSm),
                        if (isLast)
                          Expanded(
                            child: CustomButton(
                              label: 'Selesai',
                              icon: LucideIcons.checkCircle2,
                              variant: CustomButtonVariant.danger,
                              compact: true,
                              loading: examState.submitting,
                              onPressed: _confirmAndSubmit,
                            ),
                          )
                        else
                          Expanded(
                            child: CustomButton(
                              label: 'Selanjutnya',
                              icon: LucideIcons.chevronRight,
                              compact: true,
                              onPressed: () {
                                ref
                                    .read(activeExamProvider.notifier)
                                    .goToQuestion(examState.currentIndex + 1);
                                _syncEssayController();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (examState.showViolationOverlay)
            ExamViolationOverlay(
              violationCount: examState.violationCount,
              onDismiss: () => ref
                  .read(activeExamProvider.notifier)
                  .dismissViolationOverlay(),
            ),
        ],
      ),
    );
  }
}
