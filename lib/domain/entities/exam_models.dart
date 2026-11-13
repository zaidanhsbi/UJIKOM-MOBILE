class StudentExamItem {
  const StudentExamItem({
    required this.id,
    required this.name,
    required this.subjectName,
    required this.durationMinutes,
    required this.questionsCount,
    required this.status,
    this.startsAt,
    this.endsAt,
    this.alreadySubmitted = false,
  });

  final int id;
  final String name;
  final String subjectName;
  final int durationMinutes;
  final int questionsCount;
  final String status; // draft, scheduled, ongoing, finished
  final String? startsAt;
  final String? endsAt;
  final bool alreadySubmitted;

  /// Mengonversi data JSON item ujian menjadi instance [StudentExamItem].
  factory StudentExamItem.fromJson(Map<String, dynamic> json) {
    final subject = json['subject'] as Map<String, dynamic>?;
    return StudentExamItem(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      subjectName: (subject?['name'] ?? json['subject_name'] ?? '-').toString(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
      questionsCount: (json['questions_count'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'ongoing').toString(),
      startsAt: json['starts_at']?.toString(),
      endsAt: json['ends_at']?.toString(),
      alreadySubmitted: json['already_submitted'] == true,
    );
  }
}

class ExamQuestionOption {
  const ExamQuestionOption({
    required this.key,
    required this.text,
    this.image,
  });

  final String key;
  final String text;
  final String? image;
}

class ExamQuestionItem {
  const ExamQuestionItem({
    required this.id,
    required this.type,
    required this.weight,
    required this.text,
    this.image,
    this.altText,
    this.options = const [],
    this.leftItems = const [],
    this.rightItems = const [],
    this.orderItems = const [],
  });

  final int id;
  final String type; // pg, pgk, bs, jd, ur
  final int weight;
  final String text;
  final String? image;
  final String? altText;
  final List<ExamQuestionOption> options;
  final List<String> leftItems;
  final List<String> rightItems;
  final List<String> orderItems;

  /// Mengonversi data JSON soal menjadi instance [ExamQuestionItem].
  factory ExamQuestionItem.fromJson(Map<String, dynamic> json) {
    final content = (json['content'] as Map<String, dynamic>?) ?? {};
    final rawOptions = content['options'] as Map<String, dynamic>?;
    final parsedOptions = <ExamQuestionOption>[];

    if (rawOptions != null) {
      for (final entry in rawOptions.entries) {
        final val = entry.value;
        if (val is Map<String, dynamic>) {
          final optText = (val['text'] ?? '').toString();
          final optImage = val['image']?.toString();
          if (optText.isNotEmpty || (optImage != null && optImage.isNotEmpty)) {
            parsedOptions.add(
              ExamQuestionOption(key: entry.key, text: optText, image: optImage),
            );
          }
        }
      }
    }

    final left = (content['left_items'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final right = (content['right_items'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final items = (content['items'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return ExamQuestionItem(
      id: (json['id'] as num).toInt(),
      type: (json['type'] ?? 'pg').toString(),
      weight: (json['weight'] as num?)?.toInt() ?? 1,
      text: (content['text'] ?? '').toString(),
      image: content['image']?.toString(),
      altText: content['alt_text']?.toString(),
      options: parsedOptions,
      leftItems: left,
      rightItems: right,
      orderItems: items,
    );
  }

  /// Mengonversi instance [ExamQuestionItem] menjadi peta JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'weight': weight,
        'content': {
          'text': text,
          'image': image,
          'alt_text': altText,
          if (options.isNotEmpty)
            'options': {
              for (final o in options)
                o.key: {'text': o.text, 'image': o.image},
            },
          if (leftItems.isNotEmpty) 'left_items': leftItems,
          if (rightItems.isNotEmpty) 'right_items': rightItems,
          if (orderItems.isNotEmpty) 'items': orderItems,
        },
      };
}

class ExamPackageData {
  const ExamPackageData({
    required this.examId,
    required this.name,
    required this.durationMinutes,
    required this.remainingSeconds,
    required this.serverTimeEpochMs,
    required this.questions,
  });

  final int examId;
  final String name;
  final int durationMinutes;
  final int remainingSeconds;
  final int serverTimeEpochMs;
  final List<ExamQuestionItem> questions;

  /// Mengonversi data JSON paket ujian menjadi instance [ExamPackageData].
  factory ExamPackageData.fromJson(Map<String, dynamic> json) {
    final rawQuestions = (json['questions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ExamQuestionItem.fromJson)
        .toList();

    return ExamPackageData(
      examId: (json['exam_id'] as num).toInt(),
      name: (json['name'] ?? 'Ujian').toString(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
      remainingSeconds: (json['remaining_seconds'] as num?)?.toInt() ??
          ((json['duration_minutes'] as num?)?.toInt() ?? 60) * 60,
      serverTimeEpochMs: (json['server_time_epoch_ms'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      questions: rawQuestions,
    );
  }

  /// Mengonversi instance [ExamPackageData] menjadi peta JSON.
  Map<String, dynamic> toJson() => {
        'exam_id': examId,
        'name': name,
        'duration_minutes': durationMinutes,
        'remaining_seconds': remainingSeconds,
        'server_time_epoch_ms': serverTimeEpochMs,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}

class ExamAnswerEntry {
  const ExamAnswerEntry({
    required this.questionId,
    required this.answer,
    required this.ver,
    this.flagged = false,
  });

  final int questionId;
  final dynamic answer; // String | List<String> | Map<String, String>
  final int ver;
  final bool flagged;

  /// Mengembalikan `true` jika jawaban soal sudah diisi oleh siswa.
  bool get hasAnswer {
    if (answer == null) return false;
    if (answer is String) return answer.trim().isNotEmpty;
    if (answer is List) return answer.isNotEmpty;
    if (answer is Map) return answer.isNotEmpty;
    return false;
  }

  /// Mengonversi data JSON entri jawaban menjadi instance [ExamAnswerEntry].
  factory ExamAnswerEntry.fromJson(Map<String, dynamic> json) {
    return ExamAnswerEntry(
      questionId: (json['question_id'] as num).toInt(),
      answer: json['answer'],
      ver: (json['ver'] as num?)?.toInt() ?? 1,
      flagged: json['flagged'] == true,
    );
  }

  /// Mengonversi instance [ExamAnswerEntry] menjadi peta JSON.
  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'answer': answer,
        'ver': ver,
        'flagged': flagged,
      };
}

class ViolationLog {
  const ViolationLog({
    required this.timestampIso,
    required this.reason,
  });

  final String timestampIso;
  final String reason;

  /// Mengonversi data JSON log pelanggaran menjadi instance [ViolationLog].
  factory ViolationLog.fromJson(Map<String, dynamic> json) {
    return ViolationLog(
      timestampIso: (json['timestamp'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
    );
  }

  /// Mengonversi instance [ViolationLog] menjadi peta JSON.
  Map<String, dynamic> toJson() => {
        'timestamp': timestampIso,
        'reason': reason,
      };
}
