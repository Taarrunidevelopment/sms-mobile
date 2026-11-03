import 'package:flutter/material.dart';

class ParentColorGrade {
  final Color screenBg;
  final Color cardBg;
  final Color cardBorder;
  final Color subtleBg;
  final Color innerCardBg;
  final Color accentText;
  final Color accentBg;
  final Color textMain;
  final Color textMuted;
  final List<Color> heroGradientColors;

  const ParentColorGrade({
    required this.screenBg,
    required this.cardBg,
    required this.cardBorder,
    required this.subtleBg,
    required this.innerCardBg,
    required this.accentText,
    required this.accentBg,
    required this.textMain,
    required this.textMuted,
    required this.heroGradientColors,
  });
}

ParentColorGrade getParentColorGrade(int childIndex) {
  final gradeIndex = childIndex % 4;
  if (gradeIndex == 0) {
    return const ParentColorGrade(
      screenBg: Color(0xFFEEF4FF),
      cardBg: Color(0xFFD6E4FF),
      cardBorder: Color(0xFFADC8FF),
      subtleBg: Color(0xFFBFD7FF),
      innerCardBg: Color(0xFFEBF2FF),
      accentText: Color(0xFF1D4ED8),
      accentBg: Color(0xFF2563EB),
      textMain: Color(0xFF0F294A),
      textMuted: Color(0xFF335C8D),
      heroGradientColors: [Color(0xFF1E3A8A), Color(0xFF312E81), Color(0xFF0F172A)],
    );
  } else if (gradeIndex == 2) {
    return const ParentColorGrade(
      screenBg: Color(0xFFFFF7ED),
      cardBg: Color(0xFFFFE6C7),
      cardBorder: Color(0xFFF7C995),
      subtleBg: Color(0xFFFFD7A8),
      innerCardBg: Color(0xFFFFF1DF),
      accentText: Color(0xFFB45309),
      accentBg: Color(0xFFD97706),
      textMain: Color(0xFF542B0A),
      textMuted: Color(0xFF8A4B16),
      heroGradientColors: [Color(0xFF92400E), Color(0xFFB45309), Color(0xFF431407)],
    );
  } else if (gradeIndex == 3) {
    return const ParentColorGrade(
      screenBg: Color(0xFFFFF1F2),
      cardBg: Color(0xFFFFDCE2),
      cardBorder: Color(0xFFF8B9C4),
      subtleBg: Color(0xFFFFC8D2),
      innerCardBg: Color(0xFFFFEAEE),
      accentText: Color(0xFFBE123C),
      accentBg: Color(0xFFE11D48),
      textMain: Color(0xFF4C0519),
      textMuted: Color(0xFF881337),
      heroGradientColors: [Color(0xFF9F1239), Color(0xFFBE123C), Color(0xFF500724)],
    );
  } else {
    return const ParentColorGrade(
      screenBg: Color(0xFFECFDF5),
      cardBg: Color(0xFFD1FAE5),
      cardBorder: Color(0xFFA7F3D0),
      subtleBg: Color(0xFFA7F3D0),
      innerCardBg: Color(0xFFE6F9F0),
      accentText: Color(0xFF047857),
      accentBg: Color(0xFF059669),
      textMain: Color(0xFF022C22),
      textMuted: Color(0xFF065F46),
      heroGradientColors: [Color(0xFF064E3B), Color(0xFF0F766E), Color(0xFF0F172A)],
    );
  }
}
