import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../core/theme/app_tokens.dart';

/// Merender teks soal/opsi yang mengandung rumus LaTeX ($$...$$, \[...\], atau $...$)
/// secara visual menggunakan flutter_math_fork.
class MathRichText extends StatelessWidget {
  const MathRichText({
    super.key,
    required this.text,
    this.fontSize = AppTokens.textQuestion,
    this.color = AppTokens.text,
    this.fontWeight = FontWeight.w400,
  });

  final String text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;

  static final RegExp _latexRegex = RegExp(
    r'(\$\$[\s\S]+?\$\$|\\\[[\s\S]+?\\\]|\$[^\$]+?\$)',
  );

  /// Merender teks campuran biasa dan formula matematika LaTeX.
  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final matches = _latexRegex.allMatches(text).toList();
    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: 1.5,
        ),
      );
    }

    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
          ),
        );
      }

      final rawToken = match.group(0)!;
      String formula = rawToken;
      bool isDisplay = false;

      if (rawToken.startsWith(r'$$') && rawToken.endsWith(r'$$')) {
        formula = rawToken.substring(2, rawToken.length - 2).trim();
        isDisplay = true;
      } else if (rawToken.startsWith(r'\[') && rawToken.endsWith(r'\]')) {
        formula = rawToken.substring(2, rawToken.length - 2).trim();
        isDisplay = true;
      } else if (rawToken.startsWith(r'$') && rawToken.endsWith(r'$')) {
        formula = rawToken.substring(1, rawToken.length - 1).trim();
      }

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 2,
              vertical: isDisplay ? 4 : 0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                formula,
                mathStyle: isDisplay ? MathStyle.display : MathStyle.text,
                textStyle: TextStyle(
                  fontSize: fontSize,
                  color: color,
                ),
                onErrorFallback: (err) => Text(
                  rawToken,
                  style: TextStyle(fontSize: fontSize, color: AppTokens.error),
                ),
              ),
            ),
          ),
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }
}
