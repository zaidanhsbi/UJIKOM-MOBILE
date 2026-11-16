import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_tokens.dart';
import '../../domain/entities/exam_models.dart';
import 'custom_card.dart';
import 'math_rich_text.dart';

/// Kartu yang menampilkan nomor soal, tombol tandai ragu-ragu, teks soal, dan gambar soal.
class QuestionStemCard extends StatelessWidget {
  const QuestionStemCard({
    super.key,
    required this.questionNumber,
    required this.question,
    required this.isFlagged,
    required this.onToggleFlag,
  });

  final int questionNumber;
  final ExamQuestionItem question;
  final bool isFlagged;
  final VoidCallback onToggleFlag;

  /// Membangun tampilan kartu naskah soal.
  /// Membangun tampilan kartu soal beserta nomor, tombol ragu-ragu, teks, dan gambar.
  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spaceSm,
                  vertical: AppTokens.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.softBlue,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
                child: Text(
                  'Nomor $questionNumber',
                  style: const TextStyle(
                    fontSize: AppTokens.textSm,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.navy,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                onTap: onToggleFlag,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceSm,
                    vertical: AppTokens.spaceXs,
                  ),
                  decoration: BoxDecoration(
                    color: isFlagged
                        ? AppTokens.warning.withValues(alpha: 0.15)
                        : AppTokens.background,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(
                      color: isFlagged ? AppTokens.warning : AppTokens.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.flag,
                        size: 24,
                        color: isFlagged
                            ? AppTokens.warning
                            : AppTokens.textSecondary,
                      ),
                      const SizedBox(width: AppTokens.spaceXs),
                      Text(
                        'Ragu-ragu',
                        style: TextStyle(
                          fontSize: AppTokens.textSm,
                          fontWeight: FontWeight.w600,
                          color: isFlagged
                              ? AppTokens.navy
                              : AppTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceLg),
          MathRichText(
            text: question.text,
            fontSize: AppTokens.textQuestion,
            color: AppTokens.text,
          ),
          if (question.image != null && question.image!.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spaceLg),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              child: CachedNetworkImage(
                imageUrl: ApiConfig.resolveImageUrl(question.image!),
                memCacheWidth: 800,
                placeholder: (_, _) => const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, _, _) => Container(
                  height: 100,
                  color: AppTokens.background,
                  alignment: Alignment.center,
                  child: const Text(
                    'Gambar gagal dimuat',
                    style: TextStyle(color: AppTokens.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Komponen input jawaban yang menyesuaikan tampilan berdasarkan tipe soal (PG, PGK, BS, JD, UR).
class QuestionAnswerSection extends StatelessWidget {
  const QuestionAnswerSection({
    super.key,
    required this.question,
    required this.currentAnswer,
    required this.essayController,
    required this.onAnswerChanged,
  });

  final ExamQuestionItem question;
  final dynamic currentAnswer;
  final TextEditingController essayController;
  final ValueChanged<dynamic> onAnswerChanged;

  /// Memilih tampilan input yang sesuai dengan tipe soal aktif.
  /// Memilih widget input jawaban yang sesuai dengan tipe soal aktif.
  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case 'pg':
        return _buildSingleChoiceOptions();
      case 'pgk':
        return _buildMultipleChoiceOptions();
      case 'bs':
        return _buildTrueFalseOptions();
      case 'jd':
        return _buildMatchingOptions();
      case 'ur':
        return _buildOrderingOptions();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Membangun daftar pilihan untuk soal Pilihan Ganda tunggal (PG).
  /// Membangun daftar opsi jawaban untuk soal pilihan ganda tunggal.
  Widget _buildSingleChoiceOptions() {
    final selected = currentAnswer?.toString();
    return Column(
      children: question.options.map((opt) {
        final isSelected = selected == opt.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.spaceSm),
          child: CustomCard(
            onTap: () => onAnswerChanged(opt.key),
            backgroundColor:
                isSelected ? AppTokens.softBlue : AppTokens.surface,
            borderColor: isSelected ? AppTokens.primary : AppTokens.border,
            borderWidth: isSelected ? 2 : 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppTokens.primary : AppTokens.background,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(color: AppTokens.border),
                  ),
                  child: Text(
                    opt.key,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppTokens.white : AppTokens.navy,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (opt.text.isNotEmpty)
                        MathRichText(
                          text: opt.text,
                          fontSize: AppTokens.textMd,
                          color: AppTokens.text,
                        ),
                      if (opt.image != null && opt.image!.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.spaceSm),
                        CachedNetworkImage(
                          imageUrl: ApiConfig.resolveImageUrl(opt.image!),
                          height: 120,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Membangun daftar kotak centang untuk soal Pilihan Ganda Kompleks (PGK).
  /// Membangun daftar opsi jawaban untuk soal pilihan ganda kompleks.
  Widget _buildMultipleChoiceOptions() {
    final selectedList = currentAnswer is List
        ? (currentAnswer as List).map((e) => e.toString()).toList()
        : <String>[];

    return Column(
      children: question.options.map((opt) {
        final isSelected = selectedList.contains(opt.key);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.spaceSm),
          child: CustomCard(
            onTap: () {
              final next = List<String>.from(selectedList);
              if (isSelected) {
                next.remove(opt.key);
              } else {
                next.add(opt.key);
              }
              onAnswerChanged(next);
            },
            backgroundColor:
                isSelected ? AppTokens.softBlue : AppTokens.surface,
            borderColor: isSelected ? AppTokens.primary : AppTokens.border,
            borderWidth: isSelected ? 2 : 1,
            child: Row(
              children: [
                Icon(
                  isSelected ? LucideIcons.checkSquare : LucideIcons.square,
                  size: 24,
                  color:
                      isSelected ? AppTokens.primary : AppTokens.textSecondary,
                ),
                const SizedBox(width: AppTokens.spaceMd),
                Expanded(
                  child: MathRichText(
                    text: '${opt.key}. ${opt.text}',
                    fontSize: AppTokens.textMd,
                    color: AppTokens.text,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Membangun opsi Benar dan Salah untuk soal tipe BS.
  /// Membangun opsi jawaban Benar/Salah.
  Widget _buildTrueFalseOptions() {
    final selected = currentAnswer?.toString();
    return Column(
      children: ['Benar', 'Salah'].map((choice) {
        final isSelected = selected == choice;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.spaceSm),
          child: CustomCard(
            onTap: () => onAnswerChanged(choice),
            backgroundColor:
                isSelected ? AppTokens.softBlue : AppTokens.surface,
            borderColor: isSelected ? AppTokens.primary : AppTokens.border,
            borderWidth: isSelected ? 2 : 1,
            child: Row(
              children: [
                Icon(
                  isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  size: 24,
                  color:
                      isSelected ? AppTokens.primary : AppTokens.textSecondary,
                ),
                const SizedBox(width: AppTokens.spaceMd),
                Text(
                  choice,
                  style: const TextStyle(
                    fontSize: AppTokens.textMd,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.text,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Membangun pasangan dropdown untuk soal Menjodohkan (JD).
  /// Membangun dropdown pasangan untuk soal menjodohkan.
  Widget _buildMatchingOptions() {
    final currentMap = currentAnswer is Map
        ? Map<String, String>.from(
            (currentAnswer as Map).map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ),
          )
        : <String, String>{};

    return Column(
      children: question.leftItems.map((left) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.spaceSm),
          child: CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MathRichText(
                  text: left,
                  fontSize: AppTokens.textMd,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.navy,
                ),
                const SizedBox(height: AppTokens.spaceSm),
                DropdownButtonFormField<String>(
                  initialValue: question.rightItems.contains(currentMap[left])
                      ? currentMap[left]
                      : null,
                  hint: const Text('Pilih pasangan'),
                  items: question.rightItems
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    final next = Map<String, String>.from(currentMap)
                      ..[left] = val;
                    onAnswerChanged(next);
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Membangun daftar kartu item yang dapat diurutkan naik/turun untuk soal Urutan (UR).
  Widget _buildOrderingOptions() {
    final items = (currentAnswer is List && (currentAnswer as List).isNotEmpty)
        ? (currentAnswer as List).map((e) => e.toString()).toList()
        : List<String>.from(question.orderItems);

    if (items.isEmpty) {
      return const Text(
        'Belum ada daftar item untuk diurutkan.',
        style: TextStyle(color: AppTokens.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: AppTokens.spaceSm),
          child: Text(
            'Urutkan item dari atas ke bawah menggunakan tombol panah:',
            style: TextStyle(
              fontSize: AppTokens.textSm,
              fontWeight: FontWeight.w600,
              color: AppTokens.textSecondary,
            ),
          ),
        ),
        ...List.generate(items.length, (index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.spaceSm),
            child: CustomCard(
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTokens.softBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: AppTokens.textSm,
                        fontWeight: FontWeight.bold,
                        color: AppTokens.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.spaceMd),
                  Expanded(
                    child: MathRichText(
                      text: item,
                      fontSize: AppTokens.textMd,
                      color: AppTokens.text,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.arrowUp, size: 20),
                    color: index > 0 ? AppTokens.primary : AppTokens.textDisabled,
                    onPressed: index > 0
                        ? () {
                            final next = List<String>.from(items);
                            final tmp = next[index - 1];
                            next[index - 1] = next[index];
                            next[index] = tmp;
                            onAnswerChanged(next);
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.arrowDown, size: 20),
                    color: index < items.length - 1
                        ? AppTokens.primary
                        : AppTokens.textDisabled,
                    onPressed: index < items.length - 1
                        ? () {
                            final next = List<String>.from(items);
                            final tmp = next[index + 1];
                            next[index + 1] = next[index];
                            next[index] = tmp;
                            onAnswerChanged(next);
                          }
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
