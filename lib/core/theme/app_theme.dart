import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme_mode.dart';

class AppTheme {
  AppTheme._();

  // Legacy statics used in a few existing widgets — kept for compat
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFFFF6584);
  static const Color accentColor = Color(0xFF43E97B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);

  // ── Entry point ──────────────────────────────────────────────────────────────

  static ThemeData of(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.blanc:
        return _blanc();
      case AppThemeMode.obsidian:
        return _obsidian();
      case AppThemeMode.neonPulse:
        return _neonPulse();
      case AppThemeMode.vogue:
        return _vogue();
    }
  }

  // ── BLANC — Clean Minimal ─────────────────────────────────────────────────

  static ThemeData _blanc() {
    const accent = Color(0xFFE8735A);
    const accentLight = Color(0xFFFDF1EE);
    const bg = Color(0xFFFAFAFA);
    const surface = Color(0xFFFFFFFF);
    const textPrimary = Color(0xFF111111);
    const textSecondary = Color(0xFF888888);
    const border = Color(0xFFF0F0F0);

    final text = _dmSansTextTheme(textPrimary, textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: accent,
        surface: surface,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: bg,
      cardColor: surface,
      dividerColor: border,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSerifDisplay(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accent, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: errorColor)),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: accent.withOpacity(0.15),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      extensions: const [
        AppColors(
          accent: accent,
          accentLight: accentLight,
          gradientStart: accent,
          gradientEnd: Color(0xFFFF9A85),
          cardBorder: border,
          navBackground: surface,
          tagBackground: accentLight,
          tagText: accent,
        ),
      ],
    );
  }

  // ── OBSIDIAN — Luxury Dark ────────────────────────────────────────────────

  static ThemeData _obsidian() {
    const accent = Color(0xFFC9A84C);
    const accentLight = Color(0x14C9A84C);
    const bg = Color(0xFF0A0A0A);
    const surface = Color(0xFF161616);
    const textPrimary = Color(0xFFFFFFFF);
    const textSecondary = Color(0xFF888888);
    const border = Color(0xFF232323);

    final text = _interTextTheme(textPrimary, textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: surface,
        error: errorColor,
        onPrimary: Color(0xFF0A0A0A),
        onSecondary: Color(0xFF0A0A0A),
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: bg,
      cardColor: surface,
      dividerColor: border,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cormorantGaramond(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: const Color(0xFF0A0A0A),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accent, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: errorColor)),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: accentLight,
        labelStyle: const TextStyle(color: textPrimary, fontSize: 14),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0D0D0D),
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      extensions: const [
        AppColors(
          accent: accent,
          accentLight: accentLight,
          gradientStart: accent,
          gradientEnd: Color(0xFF8B6914),
          cardBorder: border,
          navBackground: Color(0xFF0D0D0D),
          tagBackground: accentLight,
          tagText: accent,
        ),
      ],
    );
  }

  // ── NEON PULSE — Vibrant Gen-Z ────────────────────────────────────────────

  static ThemeData _neonPulse() {
    const accentPurple = Color(0xFF9B5DE5);
    const accentPink = Color(0xFFF72585);
    const accentLight = Color(0x209B5DE5);
    const bg = Color(0xFF0A0A18);
    const surface = Color(0xFF12122A);
    const textPrimary = Color(0xFFFFFFFF);
    const textSecondary = Color(0xFF8888AA);
    const border = Color(0x12FFFFFF);

    final text = _spaceGroteskTextTheme(textPrimary, textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: accentPurple,
        secondary: accentPink,
        surface: surface,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: bg,
      cardColor: surface,
      dividerColor: border,
      textTheme: text,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentPurple,
          side: const BorderSide(color: accentPurple, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentPurple, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: errorColor)),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: accentLight,
        labelStyle: const TextStyle(color: textPrimary, fontSize: 14),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0D0D20),
        selectedItemColor: accentPurple,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      extensions: const [
        AppColors(
          accent: accentPurple,
          accentLight: accentLight,
          gradientStart: accentPurple,
          gradientEnd: accentPink,
          cardBorder: border,
          navBackground: Color(0xFF0D0D20),
          tagBackground: accentLight,
          tagText: accentPurple,
        ),
      ],
    );
  }

  // ── VOGUE — Editorial Magazine ────────────────────────────────────────────

  static ThemeData _vogue() {
    const accent = Color(0xFFC8102E);
    const accentLight = Color(0x14C8102E);
    const bg = Color(0xFFF8F5F0);
    const surface = Color(0xFFFFFFFF);
    const textPrimary = Color(0xFF0A0A0A);
    const textSecondary = Color(0xFF888888);
    const border = Color(0xFFE8E0D8);

    final text = _manropeTextTheme(textPrimary, textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: textPrimary,
        surface: surface,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: bg,
      cardColor: surface,
      dividerColor: border,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          minimumSize: const Size(double.infinity, 56),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: accent, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: errorColor)),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: accentLight,
        labelStyle: const TextStyle(color: textPrimary, fontSize: 13, letterSpacing: 0.5),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0A0A0A),
        selectedItemColor: accent,
        unselectedItemColor: Color(0x66FFFFFF),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5),
        unselectedLabelStyle: TextStyle(fontSize: 9, letterSpacing: 1.5),
      ),
      extensions: const [
        AppColors(
          accent: accent,
          accentLight: accentLight,
          gradientStart: accent,
          gradientEnd: Color(0xFF8B0A1E),
          cardBorder: border,
          navBackground: Color(0xFF0A0A0A),
          tagBackground: accentLight,
          tagText: accent,
        ),
      ],
    );
  }

  // ── Text themes ───────────────────────────────────────────────────────────

  static TextTheme _dmSansTextTheme(Color primary, Color secondary) => TextTheme(
        displayLarge: GoogleFonts.dmSerifDisplay(fontSize: 57, fontWeight: FontWeight.w400, color: primary),
        displayMedium: GoogleFonts.dmSerifDisplay(fontSize: 45, fontWeight: FontWeight.w400, color: primary),
        displaySmall: GoogleFonts.dmSerifDisplay(fontSize: 36, fontWeight: FontWeight.w400, color: primary),
        headlineLarge: GoogleFonts.dmSerifDisplay(fontSize: 32, fontWeight: FontWeight.w400, color: primary),
        headlineMedium: GoogleFonts.dmSans(fontSize: 26, fontWeight: FontWeight.w700, color: primary),
        headlineSmall: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w600, color: primary),
        titleLarge: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w600, color: primary),
        titleMedium: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
        titleSmall: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
        bodyLarge: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w400, color: primary),
        bodyMedium: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, color: primary),
        bodySmall: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
        labelLarge: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: primary),
        labelMedium: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: primary),
        labelSmall: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w500, color: secondary),
      );

  static TextTheme _interTextTheme(Color primary, Color secondary) => TextTheme(
        displayLarge: GoogleFonts.cormorantGaramond(fontSize: 57, fontWeight: FontWeight.w300, color: primary),
        displayMedium: GoogleFonts.cormorantGaramond(fontSize: 45, fontWeight: FontWeight.w300, color: primary),
        displaySmall: GoogleFonts.cormorantGaramond(fontSize: 36, fontWeight: FontWeight.w300, color: primary),
        headlineLarge: GoogleFonts.cormorantGaramond(fontSize: 32, fontWeight: FontWeight.w400, color: primary),
        headlineMedium: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w600, color: primary),
        headlineSmall: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: primary),
        titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: primary),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: primary),
        titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: primary),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: primary),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: primary),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: primary, letterSpacing: 1),
        labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: primary, letterSpacing: 0.5),
        labelSmall: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: secondary, letterSpacing: 1),
      );

  static TextTheme _spaceGroteskTextTheme(Color primary, Color secondary) => TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(fontSize: 57, fontWeight: FontWeight.w700, color: primary),
        displayMedium: GoogleFonts.spaceGrotesk(fontSize: 45, fontWeight: FontWeight.w700, color: primary),
        displaySmall: GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w700, color: primary),
        headlineLarge: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w700, color: primary),
        headlineMedium: GoogleFonts.spaceGrotesk(fontSize: 26, fontWeight: FontWeight.w600, color: primary),
        headlineSmall: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600, color: primary),
        titleLarge: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600, color: primary),
        titleMedium: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
        titleSmall: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: primary),
        bodyLarge: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w400, color: primary),
        bodyMedium: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w400, color: primary),
        bodySmall: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
        labelLarge: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: primary),
        labelMedium: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
        labelSmall: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w500, color: secondary),
      );

  static TextTheme _manropeTextTheme(Color primary, Color secondary) => TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(fontSize: 57, fontWeight: FontWeight.w700, color: primary),
        displayMedium: GoogleFonts.playfairDisplay(fontSize: 45, fontWeight: FontWeight.w700, color: primary),
        displaySmall: GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.w700, color: primary),
        headlineLarge: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w700, color: primary, fontStyle: FontStyle.italic),
        headlineMedium: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.w600, color: primary),
        headlineSmall: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w600, color: primary),
        titleLarge: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w600, color: primary),
        titleMedium: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
        titleSmall: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: primary),
        bodyLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w400, color: primary),
        bodyMedium: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w400, color: primary),
        bodySmall: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
        labelLarge: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: primary, letterSpacing: 1.5),
        labelMedium: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: primary, letterSpacing: 1),
        labelSmall: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w600, color: secondary, letterSpacing: 1.5),
      );
}
