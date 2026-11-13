import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/exam_models.dart';

/// Penyimpanan lokal berbasis Hive untuk ujian semi-offline (0ms write per ketukan).
class ExamLocalStorage {
  static const String packageBoxName = 'exam_package_box';
  static const String answersBoxName = 'exam_answers_box';
  static const String pendingSyncBoxName = 'pending_sync_box';
  static const String violationsBoxName = 'violation_logs_box';

  /// Menginisialisasi Hive dan membuka seluruh box lokal ujian.
  static Future<void> initHive() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<String>(packageBoxName),
      Hive.openBox<String>(answersBoxName),
      Hive.openBox<String>(pendingSyncBoxName),
      Hive.openBox<String>(violationsBoxName),
    ]);
  }

  Box<String> get _packageBox => Hive.box<String>(packageBoxName);
  Box<String> get _answersBox => Hive.box<String>(answersBoxName);
  Box<String> get _pendingBox => Hive.box<String>(pendingSyncBoxName);
  Box<String> get _violationsBox => Hive.box<String>(violationsBoxName);

  // ---------------- PAKET SOAL ----------------

  /// Menyimpan paket soal ujian ke box lokal dan menandainya sebagai ujian aktif.
  Future<void> saveExamPackage(ExamPackageData pkg) async {
    await _packageBox.put('exam_${pkg.examId}', jsonEncode(pkg.toJson()));
    await _packageBox.put('active_exam_id', pkg.examId.toString());
  }

  /// Mengambil paket soal ujian dari penyimpanan lokal berdasarkan [examId].
  ExamPackageData? getExamPackage(int examId) {
    final raw = _packageBox.get('exam_$examId');
    if (raw == null || raw.isEmpty) return null;
    try {
      return ExamPackageData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Mengambil ID ujian yang terakhir kali aktif di perangkat.
  int? getActiveExamId() {
    final raw = _packageBox.get('active_exam_id');
    return raw != null ? int.tryParse(raw) : null;
  }

  // ---------------- JAWABAN PER SOAL ----------------

  String _answerKey(int examId, int questionId) => '${examId}_$questionId';

  /// Menyimpan atau memperbarui jawaban satu soal pada [examId] ke box lokal.
  Future<void> saveAnswer(int examId, ExamAnswerEntry entry) async {
    await _answersBox.put(
      _answerKey(examId, entry.questionId),
      jsonEncode(entry.toJson()),
    );
  }

  /// Mengambil seluruh jawaban tersimpan untuk [examId] yang dipetakan oleh ID soal.
  Map<int, ExamAnswerEntry> getAnswersForExam(int examId) {
    final prefix = '${examId}_';
    final result = <int, ExamAnswerEntry>{};

    for (final key in _answersBox.keys) {
      final k = key.toString();
      if (!k.startsWith(prefix)) continue;
      final raw = _answersBox.get(k);
      if (raw == null) continue;
      try {
        final entry = ExamAnswerEntry.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        result[entry.questionId] = entry;
      } catch (_) {}
    }

    return result;
  }

  // ---------------- LOG PELANGGARAN ----------------

  /// Menambahkan catatan pelanggaran baru ke daftar pelanggaran [examId].
  Future<void> addViolation(int examId, ViolationLog log) async {
    final list = getViolations(examId)..add(log);
    await _violationsBox.put(
      'exam_$examId',
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  /// Mengambil daftar catatan pelanggaran yang tersimpan untuk [examId].
  List<ViolationLog> getViolations(int examId) {
    final raw = _violationsBox.get('exam_$examId');
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ViolationLog.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ---------------- PENDING SYNC QUEUE ----------------

  /// Menandai payload pengumpulan [examId] ke antrean sinkronisasi tertunda.
  Future<void> markPendingSync(int examId, Map<String, dynamic> payload) async {
    await _pendingBox.put('exam_$examId', jsonEncode(payload));
  }

  /// Mengambil seluruh payload pengumpulan ujian yang masih menunggu sinkronisasi.
  Map<int, Map<String, dynamic>> getAllPendingSync() {
    final result = <int, Map<String, dynamic>>{};
    for (final key in _pendingBox.keys) {
      final k = key.toString();
      if (!k.startsWith('exam_')) continue;
      final examId = int.tryParse(k.replaceFirst('exam_', ''));
      final raw = _pendingBox.get(k);
      if (examId == null || raw == null) continue;
      try {
        result[examId] = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    return result;
  }

  /// Memeriksa apakah [examId] memiliki data pengumpulan yang belum tersinkronisasi.
  bool hasPendingSync(int examId) => _pendingBox.containsKey('exam_$examId');

  // ---------------- CLEANUP SETELAH 200 OK ----------------

  /// Menghapus seluruh data soal, jawaban, log pelanggaran, dan antrean sync
  /// untuk ujian tertentu segera setelah server merespons 200 OK.
  Future<void> clearExamData(int examId) async {
    await _packageBox.delete('exam_$examId');
    if (_packageBox.get('active_exam_id') == examId.toString()) {
      await _packageBox.delete('active_exam_id');
    }

    final prefix = '${examId}_';
    final answerKeys = _answersBox.keys
        .where((k) => k.toString().startsWith(prefix))
        .toList();
    if (answerKeys.isNotEmpty) {
      await _answersBox.deleteAll(answerKeys);
    }

    await _violationsBox.delete('exam_$examId');
    await _pendingBox.delete('exam_$examId');
  }
}
