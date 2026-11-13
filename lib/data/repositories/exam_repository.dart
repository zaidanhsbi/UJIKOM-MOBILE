import 'package:dio/dio.dart';
import '../../domain/entities/exam_models.dart';
import '../datasources/api_client.dart';
import '../datasources/exam_local_storage.dart';

class ExamSubmitResult {
  const ExamSubmitResult({
    required this.synced,
    required this.message,
  });

  final bool synced;
  final String message;
}

class ExamRepository {
  ExamRepository(this._apiClient, this._localStorage);

  final ApiClient _apiClient;
  final ExamLocalStorage _localStorage;

  /// Mengambil daftar ujian yang tersedia untuk siswa dari server.
  Future<List<StudentExamItem>> fetchExams() async {
    final response = await _apiClient.dio.get('/siswa/exams');
    final data = response.data as Map<String, dynamic>;
    final rawList = (data['exams'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(StudentExamItem.fromJson)
        .toList();
    return rawList;
  }

  /// Memulai ujian dengan [token] dan mengunduh paket soal ke penyimpanan lokal.
  Future<ExamPackageData> startAndDownloadExam(int examId, String token) async {
    try {
      final response = await _apiClient.dio.post(
        '/siswa/exams/$examId/start',
        data: {'token': token.trim().toUpperCase()},
      );
      final pkg = ExamPackageData.fromJson(response.data as Map<String, dynamic>);
      await _localStorage.saveExamPackage(pkg);
      return pkg;
    } on DioException catch (e) {
      // Jika jaringan terputus tapi paket sudah pernah diunduh lokal, gunakan lokal
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        final cached = _localStorage.getExamPackage(examId);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  /// Mengambil paket soal yang sudah tersimpan di cache lokal berdasarkan [examId].
  ExamPackageData? getCachedPackage(int examId) =>
      _localStorage.getExamPackage(examId);

  /// Mengambil ID ujian aktif yang terakhir disimpan secara lokal.
  int? getActiveExamId() => _localStorage.getActiveExamId();

  /// Mengambil peta jawaban lokal siswa untuk [examId].
  Map<int, ExamAnswerEntry> getLocalAnswers(int examId) =>
      _localStorage.getAnswersForExam(examId);

  /// Menyimpan satu jawaban soal ke penyimpanan lokal.
  Future<void> saveAnswerLocal(int examId, ExamAnswerEntry entry) =>
      _localStorage.saveAnswer(examId, entry);

  /// Mencatat pelanggaran baru untuk [examId] ke penyimpanan lokal.
  Future<void> logViolation(int examId, ViolationLog log) =>
      _localStorage.addViolation(examId, log);

  /// Mengambil daftar pelanggaran yang tercatat untuk [examId].
  List<ViolationLog> getViolations(int examId) =>
      _localStorage.getViolations(examId);

  /// Mengambil seluruh antrean pengumpulan ujian yang belum tersinkronisasi.
  Map<int, Map<String, dynamic>> getPendingSyncs() =>
      _localStorage.getAllPendingSync();

  /// Mengirimkan jawaban dan log pelanggaran ujian ke server atau menyimpannya sebagai Pending Sync.
  Future<ExamSubmitResult> submitExam({
    required int examId,
    required int durationSeconds,
  }) async {
    final answersMap = _localStorage.getAnswersForExam(examId);
    final violations = _localStorage.getViolations(examId);

    final payload = <String, dynamic>{
      'duration_seconds': durationSeconds,
      'answers': answersMap.values
          .map((e) => {
                'question_id': e.questionId,
                'answer': e.answer,
                'ver': e.ver,
              })
          .toList(),
      'violations': violations.map((v) => v.toJson()).toList(),
    };

    try {
      final response = await _apiClient.dio.post(
        '/siswa/exams/$examId/submit',
        data: payload,
      );
      if (response.statusCode == 200) {
        await _localStorage.clearExamData(examId);
        return const ExamSubmitResult(
          synced: true,
          message: 'Jawaban berhasil dikirim dan disinkronkan ke server.',
        );
      }
      await _localStorage.markPendingSync(examId, payload);
      return const ExamSubmitResult(
        synced: false,
        message: 'Server belum mengonfirmasi. Jawaban disimpan sebagai Pending Sync.',
      );
    } on DioException {
      await _localStorage.markPendingSync(examId, payload);
      return const ExamSubmitResult(
        synced: false,
        message: 'Koneksi terputus. Jawaban disimpan lokal (Pending Sync) dan akan dikirim otomatis saat online.',
      );
    }
  }

  /// Auto-retry mengirim seluruh ujian berstatus Pending Sync di background.
  Future<int> retryPendingSyncs() async {
    final pending = _localStorage.getAllPendingSync();
    if (pending.isEmpty) return 0;

    int syncedCount = 0;
    for (final entry in pending.entries) {
      final examId = entry.key;
      final payload = entry.value;
      try {
        final response = await _apiClient.dio.post(
          '/siswa/exams/$examId/submit',
          data: payload,
        );
        if (response.statusCode == 200) {
          await _localStorage.clearExamData(examId);
          syncedCount++;
        }
      } catch (_) {
        // Tetap simpan di Pending Sync untuk dicoba lagi saat koneksi stabil
      }
    }
    return syncedCount;
  }
}
