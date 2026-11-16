import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/api_client.dart';
import '../../data/repositories/exam_repository.dart';
import '../../domain/entities/exam_models.dart';
import 'auth_provider.dart';

class ExamListState {
  const ExamListState({
    this.loading = false,
    this.exams = const [],
    this.pendingSyncCount = 0,
    this.error,
    this.syncNotice,
  });

  final bool loading;
  final List<StudentExamItem> exams;
  final int pendingSyncCount;
  final String? error;
  final String? syncNotice;

  /// Membuat salinan [ExamListState] dengan nilai field yang diperbarui.
  ExamListState copyWith({
    bool? loading,
    List<StudentExamItem>? exams,
    int? pendingSyncCount,
    String? error,
    bool clearError = false,
    String? syncNotice,
    bool clearSyncNotice = false,
  }) {
    return ExamListState(
      loading: loading ?? this.loading,
      exams: exams ?? this.exams,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      error: clearError ? null : (error ?? this.error),
      syncNotice: clearSyncNotice ? null : (syncNotice ?? this.syncNotice),
    );
  }
}

class ExamListNotifier extends StateNotifier<ExamListState> {
  ExamListNotifier(this._repo) : super(const ExamListState()) {
    _listenConnectivity();
  }

  final ExamRepository _repo;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  /// Memantau perubahan konektivitas untuk otomatis menyinkronkan antrean tertunda.
  void _listenConnectivity() {
    _connSub = Connectivity().onConnectivityChanged.listen((results) async {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork && _repo.getPendingSyncs().isNotEmpty) {
        await syncPendingNow();
      }
    });
  }

  /// Memuat daftar ujian dari server dan memicu sinkronisasi jika ada antrean tertunda.
  Future<void> loadExams() async {
    state = state.copyWith(loading: true, clearError: true);
    final pendingCount = _repo.getPendingSyncs().length;

    try {
      final exams = await _repo.fetchExams();
      state = state.copyWith(
        loading: false,
        exams: exams,
        pendingSyncCount: pendingCount,
      );
      if (pendingCount > 0) {
        await syncPendingNow();
      }
    } catch (e) {
      state = state.copyWith(
        loading: false,
        pendingSyncCount: pendingCount,
        error: ApiClient.extractErrorMessage(
          e,
          fallback: 'Gagal memuat daftar ujian.',
        ),
      );
    }
  }

  /// Menutup notifikasi sinkronisasi.
  void dismissSyncNotice() {
    state = state.copyWith(clearSyncNotice: true);
  }

  /// Menutup pesan error.
  void dismissError() {
    state = state.copyWith(clearError: true);
  }

  /// Mengirimkan ulang seluruh ujian berstatus Pending Sync ke server.
  Future<void> syncPendingNow() async {
    state = state.copyWith(clearError: true, clearSyncNotice: true);
    try {
      final synced = await _repo.retryPendingSyncs();
      final remaining = _repo.getPendingSyncs().length;
      if (synced > 0) {
        state = state.copyWith(
          pendingSyncCount: remaining,
          syncNotice: '$synced ujian Pending Sync berhasil dikirim ke server.',
        );
        await loadExams();
      } else if (remaining > 0) {
        state = state.copyWith(
          pendingSyncCount: remaining,
          error: 'Gagal sinkronisasi ke server. Pastikan koneksi aktif lalu coba lagi.',
        );
      } else {
        state = state.copyWith(
          pendingSyncCount: 0,
          syncNotice: 'Antrean sinkronisasi sudah dibersihkan.',
        );
        await loadExams();
      }
    } catch (e) {
      final remaining = _repo.getPendingSyncs().length;
      state = state.copyWith(
        pendingSyncCount: remaining,
        error: ApiClient.extractErrorMessage(
          e,
          fallback: 'Gagal sinkronisasi ke server. Pastikan koneksi aktif lalu coba lagi.',
        ),
      );
    }
  }

  /// Membatalkan langganan listener konektivitas saat notifier dihancurkan.
  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }
}

final examListProvider =
    StateNotifierProvider<ExamListNotifier, ExamListState>((ref) {
  return ExamListNotifier(ref.watch(examRepositoryProvider));
});

// =============================================================================
// ACTIVE EXAM SESSION STATE (RUANG UJIAN)
// =============================================================================

class ActiveExamState {
  const ActiveExamState({
    this.package,
    this.answers = const {},
    this.currentIndex = 0,
    this.remainingSeconds = 0,
    this.violationCount = 0,
    this.showViolationOverlay = false,
    this.submitting = false,
    this.error,
  });

  final ExamPackageData? package;
  final Map<int, ExamAnswerEntry> answers;
  final int currentIndex;
  final int remainingSeconds;
  final int violationCount;
  final bool showViolationOverlay;
  final bool submitting;
  final String? error;

  /// Mengembalikan jumlah total soal pada paket ujian aktif.
  int get totalQuestions => package?.questions.length ?? 0;

  /// Mengembalikan jumlah soal yang sudah memiliki jawaban.
  int get answeredCount =>
      answers.values.where((entry) => entry.hasAnswer).length;

  /// Mengembalikan jumlah soal yang belum dijawab.
  int get unansweredCount => (totalQuestions - answeredCount).clamp(0, totalQuestions);

  /// Membuat salinan [ActiveExamState] dengan nilai field yang diperbarui.
  ActiveExamState copyWith({
    ExamPackageData? package,
    Map<int, ExamAnswerEntry>? answers,
    int? currentIndex,
    int? remainingSeconds,
    int? violationCount,
    bool? showViolationOverlay,
    bool? submitting,
    String? error,
    bool clearError = false,
  }) {
    return ActiveExamState(
      package: package ?? this.package,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      violationCount: violationCount ?? this.violationCount,
      showViolationOverlay: showViolationOverlay ?? this.showViolationOverlay,
      submitting: submitting ?? this.submitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ActiveExamNotifier extends StateNotifier<ActiveExamState> {
  ActiveExamNotifier(this._repo) : super(const ActiveExamState());

  final ExamRepository _repo;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  int _initialRemainingSeconds = 0;

  /// Memulai atau melanjutkan sesi ujian menggunakan [token] dan mengunduh paket soal.
  Future<bool> startOrResumeExam(int examId, String token) async {
    state = state.copyWith(clearError: true);
    try {
      final pkg = await _repo.startAndDownloadExam(examId, token);
      final localAnswers = _repo.getLocalAnswers(examId);
      final violations = _repo.getViolations(examId);

      _startPrecisionTimer(pkg.remainingSeconds);

      state = ActiveExamState(
        package: pkg,
        answers: localAnswers,
        currentIndex: 0,
        remainingSeconds: pkg.remainingSeconds,
        violationCount: violations.length,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: ApiClient.extractErrorMessage(
          e,
          fallback: 'Gagal memulai ujian. Periksa token atau koneksi.',
        ),
      );
      return false;
    }
  }

  /// Memulihkan sesi ujian dari cache lokal berdasarkan [examId].
  void resumeFromLocal(int examId) {
    final pkg = _repo.getCachedPackage(examId);
    if (pkg == null) return;
    final localAnswers = _repo.getLocalAnswers(examId);
    final violations = _repo.getViolations(examId);

    _startPrecisionTimer(pkg.remainingSeconds);

    state = ActiveExamState(
      package: pkg,
      answers: localAnswers,
      currentIndex: 0,
      remainingSeconds: pkg.remainingSeconds,
      violationCount: violations.length,
    );
  }

  /// Timer presisi memakai Stopwatch monotonik berbasis sisa waktu dari server,
  /// sehingga tidak terpengaruh perubahan jam perangkat.
  void _startPrecisionTimer(int serverRemainingSeconds) {
    _ticker?.cancel();
    _initialRemainingSeconds = serverRemainingSeconds;
    _stopwatch
      ..reset()
      ..start();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = _stopwatch.elapsed.inSeconds;
      final remaining = (_initialRemainingSeconds - elapsed).clamp(0, 86400);
      state = state.copyWith(remainingSeconds: remaining);
      if (remaining <= 0) {
        _ticker?.cancel();
      }
    });
  }

  /// Berpindah ke soal pada indeks [index].
  void goToQuestion(int index) {
    if (index < 0 || index >= state.totalQuestions) return;
    state = state.copyWith(currentIndex: index);
  }

  /// Menyimpan jawaban siswa untuk [questionId] ke penyimpanan lokal dan state.
  Future<void> setAnswer(int questionId, dynamic answer) async {
    final pkg = state.package;
    if (pkg == null) return;

    final prev = state.answers[questionId];
    final nextEntry = ExamAnswerEntry(
      questionId: questionId,
      answer: answer,
      ver: (prev?.ver ?? 0) + 1,
      flagged: prev?.flagged ?? false,
    );

    // WAJIB simpan ke lokal Hive lebih dulu
    await _repo.saveAnswerLocal(pkg.examId, nextEntry);

    final updated = Map<int, ExamAnswerEntry>.from(state.answers)
      ..[questionId] = nextEntry;
    state = state.copyWith(answers: updated);
  }

  /// Mengubah status tanda ragu-ragu pada [questionId].
  Future<void> toggleFlag(int questionId) async {
    final pkg = state.package;
    if (pkg == null) return;

    final prev = state.answers[questionId];
    final nextEntry = ExamAnswerEntry(
      questionId: questionId,
      answer: prev?.answer,
      ver: prev?.ver ?? 1,
      flagged: !(prev?.flagged ?? false),
    );

    await _repo.saveAnswerLocal(pkg.examId, nextEntry);
    final updated = Map<int, ExamAnswerEntry>.from(state.answers)
      ..[questionId] = nextEntry;
    state = state.copyWith(answers: updated);
  }

  /// Mencatat pelanggaran lifecycle dengan [reason] dan menampilkan overlay peringatan.
  Future<void> recordLifecycleViolation(String reason) async {
    final pkg = state.package;
    if (pkg == null) return;

    await _repo.logViolation(
      pkg.examId,
      ViolationLog(
        timestampIso: DateTime.now().toIso8601String(),
        reason: reason,
      ),
    );

    state = state.copyWith(
      violationCount: state.violationCount + 1,
      showViolationOverlay: true,
    );
  }

  /// Menutup overlay peringatan pelanggaran.
  void dismissViolationOverlay() {
    state = state.copyWith(showViolationOverlay: false);
  }

  /// Menghentikan timer dan mengirimkan jawaban ujian aktif ke server.
  Future<ExamSubmitResult> submitExam() async {
    final pkg = state.package;
    if (pkg == null) {
      return const ExamSubmitResult(synced: false, message: 'Tidak ada ujian aktif.');
    }

    state = state.copyWith(submitting: true);
    _ticker?.cancel();
    _stopwatch.stop();

    final usedSeconds = _stopwatch.elapsed.inSeconds;
    final result = await _repo.submitExam(
      examId: pkg.examId,
      durationSeconds: usedSeconds,
    );

    state = const ActiveExamState();
    return result;
  }

  /// Menghentikan timer dan stopwatch saat notifier dihancurkan.
  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}

final activeExamProvider =
    StateNotifierProvider<ActiveExamNotifier, ActiveExamState>((ref) {
  return ActiveExamNotifier(ref.watch(examRepositoryProvider));
});
