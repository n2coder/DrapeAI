import 'package:flutter/material.dart';

enum AppThemeMode {
  blanc('Blanc', 'Clean & Minimal'),
  obsidian('Obsidian', 'Luxury Dark'),
  neonPulse('Neon Pulse', 'Vibrant Gen-Z'),
  vogue('Vogue', 'Editorial');

  const AppThemeMode(this.label, this.description);
  final String label;
  final String description;
}

/// Extra per-theme colors accessible anywhere via Theme.of(context).extension<AppColors>()!
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.accent,
    required this.accentLight,
    required this.gradientStart,
    required this.gradientEnd,
    required this.cardBorder,
    required this.navBackground,
    required this.tagBackground,
    required this.tagText,
  });

  final Color accent;
  final Color accentLight;
  final Color gradientStart;
  final Color gradientEnd;
  final Color cardBorder;
  final Color navBackground;
  final Color tagBackground;
  final Color tagText;

  LinearGradient get gradient => LinearGradient(
        colors: [gradientStart, gradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  AppColors copyWith({
    Color? accent,
    Color? accentLight,
    Color? gradientStart,
    Color? gradientEnd,
    Color? cardBorder,
    Color? navBackground,
    Color? tagBackground,
    Color? tagText,
  }) =>
      AppColors(
        accent: accent ?? this.accent,
        accentLight: accentLight ?? this.accentLight,
        gradientStart: gradientStart ?? this.gradientStart,
        gradientEnd: gradientEnd ?? this.gradientEnd,
        cardBorder: cardBorder ?? this.cardBorder,
        navBackground: navBackground ?? this.navBackground,
        tagBackground: tagBackground ?? this.tagBackground,
        tagText: tagText ?? this.tagText,
      );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      tagBackground: Color.lerp(tagBackground, other.tagBackground, t)!,
      tagText: Color.lerp(tagText, other.tagText, t)!,
    );
  }
}
