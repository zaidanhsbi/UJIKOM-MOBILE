import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';

/// Kartu reusable dengan efek InkWell ripple & border sesuai DESIGN-SYSTEM.md
class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppTokens.spaceLg),
    this.backgroundColor = AppTokens.surface,
    this.borderColor = AppTokens.border,
    this.borderWidth = 1,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;

  /// Membangun kartu kontainer dengan border, radius, dan aksi ketukan opsional.
  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
