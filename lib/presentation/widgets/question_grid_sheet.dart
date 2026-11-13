import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_tokens.dart';
import '../providers/exam_provider.dart';

/// Bottom sheet untuk menampilkan grid nomor soal beserta status terjawab/ragu-ragu.
class QuestionGridSheet extends ConsumerWidget {
  const QuestionGridSheet({
    super.key,
    required this.onQuestionSelected,
  });

  final ValueChanged<int> onQuestionSelected;

  /// Membangun tampilan grid nomor soal dan legenda warna status soal.
  /// Membangun bottom sheet berisi kisi nomor soal dan legenda statusnya.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeExamProvider);
    final questions = state.package?.questions ?? [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Navigasi Nomor Soal',
                  style: TextStyle(
                    fontSize: AppTokens.textLg,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.navy,
                  ),
                ),
                Text(
                  '${state.answeredCount}/${state.totalQuestions} Terjawab',
                  style: const TextStyle(
                    fontSize: AppTokens.textSm,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spaceMd),
            const Row(
              children: [
                _LegendChip(color: AppTokens.mint, label: 'Terjawab'),
                SizedBox(width: AppTokens.spaceMd),
                _LegendChip(
                  color: AppTokens.white,
                  label: 'Kosong',
                  hasBorder: true,
                ),
                SizedBox(width: AppTokens.spaceMd),
                _LegendChip(color: AppTokens.yellow, label: 'Ragu'),
              ],
            ),
            const SizedBox(height: AppTokens.spaceLg),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: AppTokens.spaceSm,
                  mainAxisSpacing: AppTokens.spaceSm,
                ),
                itemCount: questions.length,
                itemBuilder: (_, index) {
                  final q = questions[index];
                  final entry = state.answers[q.id];
                  final isCurrent = index == state.currentIndex;
                  final isAnswered = entry?.hasAnswer == true;
                  final isFlagged = entry?.flagged == true;

                  Color bgColor = AppTokens.white;
                  if (isFlagged) {
                    bgColor = AppTokens.yellow;
                  } else if (isAnswered) {
                    bgColor = AppTokens.mint;
                  }

                  return Material(
                    color: bgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      side: BorderSide(
                        color: isCurrent ? AppTokens.navy : AppTokens.border,
                        width: isCurrent ? 2.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        onQuestionSelected(index);
                        Navigator.of(context).pop();
                      },
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: AppTokens.textMd,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.navy,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indikator warna legenda pada sheet navigasi nomor soal.
class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
    this.hasBorder = false,
  });

  final Color color;
  final String label;
  final bool hasBorder;

  /// Membangun tampilan chip legenda warna.
  /// Membangun item legenda warna status soal.
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder ? Border.all(color: AppTokens.border) : null,
          ),
        ),
        const SizedBox(width: AppTokens.spaceXs),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppTokens.textXs,
            color: AppTokens.textSecondary,
          ),
        ),
      ],
    );
  }
}
