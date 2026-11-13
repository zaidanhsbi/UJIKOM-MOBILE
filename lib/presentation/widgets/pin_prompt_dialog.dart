import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_tokens.dart';
import 'custom_button.dart';

/// Dialog konfirmasi yang meminta persetujuan siswa untuk mengaktifkan Screen Pinning.
class PinPromptDialog extends StatelessWidget {
  const PinPromptDialog({super.key});

  /// Menampilkan dialog persetujuan Screen Pinning dan mengembalikan `true` jika disetujui.
  /// Membangun dialog instruksi untuk mengaktifkan Screen Pinning.
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTokens.softBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                LucideIcons.shieldCheck,
                size: 28,
                color: AppTokens.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aktifkan Screen Pinning',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTokens.text,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aplikasi harus dikunci menggunakan Screen Pinning sebelum ujian dimulai agar Anda tetap berada di dalam aplikasi selama ujian berlangsung.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTokens.textSm,
                color: AppTokens.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppTokens.softBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(
                    LucideIcons.shieldCheck,
                    size: 20,
                    color: AppTokens.primary,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTokens.text,
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(text: 'Jangan pilih '),
                          TextSpan(
                            text: 'Batal',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: ' pada dialog Screen Pinning dari Android.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Tolak',
                    variant: CustomButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    label: 'Setuju',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
