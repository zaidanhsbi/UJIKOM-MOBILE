import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/device_status_service.dart';
import 'package:app/domain/entities/exam_models.dart';
import 'package:app/presentation/providers/exam_provider.dart';
import 'package:app/presentation/widgets/pin_prompt_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ExamPackageData parses sanitized package without answer key', () {
    final pkg = ExamPackageData.fromJson({
      'exam_id': 1,
      'name': 'Ujian Matematika',
      'duration_minutes': 60,
      'remaining_seconds': 3600,
      'server_time_epoch_ms': 1700000000000,
      'questions': [
        {
          'id': 10,
          'type': 'pg',
          'weight': 10,
          'content': {
            'text': r'Hitung $$2 + 2$$',
            'options': {
              'A': {'text': '3'},
              'B': {'text': '4'},
            },
          },
        },
      ],
    });

    expect(pkg.examId, 1);
    expect(pkg.questions.length, 1);
    expect(pkg.questions.first.options.length, 2);
  });

  test('DeviceStatusService enforces minimum brightness of 15%', () async {
    double? lastSentLevel;
    const channel = MethodChannel('com.binoexam.app/security');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setBrightness') {
        final args = call.arguments as Map<dynamic, dynamic>;
        lastSentLevel = (args['level'] as num).toDouble();
        return true;
      }
      return null;
    });

    expect(DeviceStatusService.minBrightness, 0.15);
    expect(0.0.clamp(DeviceStatusService.minBrightness, DeviceStatusService.maxBrightness), 0.15);
    expect(lastSentLevel, isNull);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('ActiveExamState computes answered and unanswered counts accurately', () {
    final pkg = ExamPackageData.fromJson({
      'exam_id': 2,
      'name': 'Ujian Fisika',
      'duration_minutes': 45,
      'remaining_seconds': 2700,
      'server_time_epoch_ms': 1700000000000,
      'questions': [
        {
          'id': 1,
          'type': 'pg',
          'weight': 50,
          'content': {'text': 'Soal 1', 'options': {'A': {'text': '1'}}},
        },
        {
          'id': 2,
          'type': 'pg',
          'weight': 50,
          'content': {'text': 'Soal 2', 'options': {'A': {'text': '2'}}},
        },
      ],
    });

    final state = ActiveExamState(
      package: pkg,
      answers: {
        1: const ExamAnswerEntry(questionId: 1, answer: 'A', ver: 1),
      },
    );

    expect(state.totalQuestions, 2);
    expect(state.answeredCount, 1);
    expect(state.unansweredCount, 1);
  });

  testWidgets('PinPromptDialog returns false on Tolak and true on Setuju', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (_) => const PinPromptDialog(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Aktifkan Screen Pinning'), findsOneWidget);
    await tester.tap(find.text('Tolak'));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Setuju'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
