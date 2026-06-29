import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DownloaderCupertinoTheme {
  const DownloaderCupertinoTheme._();

  static const Color ink = Color(0xFF171717);
  static const Color canvas = Color(0xFFF5F5F7);
  static const Color darkCanvas = Color(0xFF101014);
  static const Color primaryBlue = Color(0xFF0A84FF);
  static const Color signalTeal = Color(0xFF30B0C7);
  static const Color ratioGold = Color(0xFFD4AF37);
  static const Color dangerRed = Color(0xFFFF453A);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primaryBlue,
          brightness: brightness,
        ).copyWith(
          primary: primaryBlue,
          secondary: signalTeal,
          tertiary: ratioGold,
          error: dangerRed,
          surface: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          onSurface: isDark ? const Color(0xFFF5F5F7) : ink,
          onSurfaceVariant: isDark
              ? const Color(0xFFB7B7BE)
              : const Color(0xFF5F6368),
          outline: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6),
          outlineVariant: isDark
              ? const Color(0xFF2C2C2E)
              : const Color(0xFFE5E5EA),
        );

    final base = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? darkCanvas : canvas,
      useMaterial3: true,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: (isDark ? darkCanvas : canvas).withValues(alpha: 0.92),
        foregroundColor: scheme.onSurface,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: isDark ? 0.36 : 0.7),
            width: 0.6,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.28 : 0.68,
        ),
        selectedColor: primaryBlue.withValues(alpha: isDark ? 0.24 : 0.12),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.55),
        ),
        labelStyle: base.textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.72),
        thickness: 0.6,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          minimumSize: const Size.square(44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: base.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
          letterSpacing: 0,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.45 : 0.72,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: isDark ? darkCanvas : canvas,
        barBackgroundColor: (isDark ? darkCanvas : canvas).withValues(
          alpha: 0.84,
        ),
        textTheme: CupertinoTextThemeData(
          primaryColor: scheme.onSurface,
          textStyle: TextStyle(color: scheme.onSurface, letterSpacing: 0),
          navTitleTextStyle: TextStyle(
            color: scheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          navLargeTitleTextStyle: TextStyle(
            color: scheme.onSurface,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
