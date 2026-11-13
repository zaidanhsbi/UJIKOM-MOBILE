import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';

enum CustomButtonVariant { primary, secondary, danger }

/// Tombol reusable dengan efek InkWell ripple & token DESIGN-SYSTEM.md
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CustomButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final bool compact;

  /// Membangun tombol kustom sesuai varian, ukuran, dan status loading.
  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;

    Color bgColor;
    Color fgColor;
    Color borderColor;

    switch (variant) {
      case CustomButtonVariant.primary:
        bgColor = isDisabled ? AppTokens.textDisabled : AppTokens.navy;
        fgColor = AppTokens.white;
        borderColor = Colors.transparent;
        break;
      case CustomButtonVariant.secondary:
        bgColor = AppTokens.surface;
        fgColor = isDisabled ? AppTokens.textDisabled : AppTokens.navy;
        borderColor = AppTokens.border;
        break;
      case CustomButtonVariant.danger:
        bgColor = isDisabled ? AppTokens.textDisabled : AppTokens.error;
        fgColor = AppTokens.white;
        borderColor = Colors.transparent;
        break;
    }

    final child = Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        side: BorderSide(color: borderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        child: Container(
          constraints: BoxConstraints(
            minHeight: compact ? 40 : 48,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppTokens.spaceMd : AppTokens.spaceLg,
            vertical: AppTokens.spaceSm,
          ),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                  ),
                ),
                const SizedBox(width: AppTokens.spaceSm),
              ] else if (icon != null) ...[
                Icon(icon, size: 20, color: fgColor),
                const SizedBox(width: AppTokens.spaceSm),
              ],
              Flexible(
                child: Text(
                  loading ? 'Memproses...' : label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? AppTokens.textSm : AppTokens.textMd,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: child) : child;
  }
}
