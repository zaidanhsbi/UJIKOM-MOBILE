import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../domain/entities/exam_models.dart';
import 'custom_button.dart';
import 'custom_text_field.dart';

/// Dialog input token ujian sebelum siswa mengunduh soal dan masuk ke ruang ujian.
class ExamTokenDialog extends StatefulWidget {
  const ExamTokenDialog({super.key, required this.exam});

  final StudentExamItem exam;

  /// Membuat state untuk dialog input token ujian.
  @override
  State<ExamTokenDialog> createState() => _ExamTokenDialogState();
}

class _ExamTokenDialogState extends State<ExamTokenDialog> {
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Membersihkan controller input token saat dialog ditutup.
  /// Membersihkan controller input token saat dialog ditutup.
  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  /// Memvalidasi input token dan menutup dialog dengan mengembalikan nilai token.
  /// Memvalidasi dan mengembalikan token ujian yang dimasukkan siswa.
  void _submitToken() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_tokenController.text.trim());
    }
  }

  /// Membangun tampilan form input token ujian.
  /// Membangun dialog input token ujian.
  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;

    return AlertDialog(
      backgroundColor: AppTokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      ),
      title: Text(
        'Mulai ${exam.name}',
        style: const TextStyle(
          fontSize: AppTokens.textLg,
          fontWeight: FontWeight.w700,
          color: AppTokens.navy,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mata Pelajaran: ${exam.subjectName}\nDurasi: ${exam.durationMinutes} menit (${exam.questionsCount} soal)',
              style: const TextStyle(
                fontSize: AppTokens.textSm,
                color: AppTokens.textSecondary,
              ),
            ),
            const SizedBox(height: AppTokens.spaceLg),
            CustomTextField(
              controller: _tokenController,
              label: 'Token Ujian',
              hint: 'Masukkan 6 karakter token dari pengawas',
              prefixIcon: LucideIcons.keyRound,
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Token ujian wajib diisi';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        CustomButton(
          label: 'Batal',
          variant: CustomButtonVariant.secondary,
          fullWidth: false,
          compact: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        CustomButton(
          label: 'Mulai Ujian',
          icon: LucideIcons.play,
          fullWidth: false,
          compact: true,
          onPressed: _submitToken,
        ),
      ],
    );
  }
}
