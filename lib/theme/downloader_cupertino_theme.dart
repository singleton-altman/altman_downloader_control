import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:altman_downloader_control/widget/downloader_app_bar_back_button.dart';

class DownloaderCupertinoTheme {
  const DownloaderCupertinoTheme._();

  static const String fontFamily = 'DownloaderSans';
  static const List<String> fontFallback = [
    'PingFang SC',
    'SF Pro Text',
    'Noto Sans CJK SC',
    'Microsoft YaHei',
    'Roboto',
    'Arial',
  ];

  static const Color ink = Color(0xFF15171A);
  static const Color mutedInk = Color(0xFF5D6570);
  static const Color canvas = Color(0xFFF4F6F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFEFF3F7);
  static const Color surfaceMuted = Color(0xFFE6EBF0);
  static const Color darkInk = Color(0xFFF4F7FA);
  static const Color darkMutedInk = Color(0xFFB5BDC7);
  static const Color darkCanvas = Color(0xFF0D1014);
  static const Color darkSurface = Color(0xFF181C22);
  static const Color darkSurfaceSoft = Color(0xFF20262E);
  static const Color darkSurfaceMuted = Color(0xFF2A313B);
  static const Color primaryBlue = Color(0xFF0A84FF);
  static const Color signalTeal = Color(0xFF30B0C7);
  static const Color ratioGold = Color(0xFFD4AF37);
  static const Color dangerRed = Color(0xFFFF453A);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningOrange = Color(0xFFFF9F0A);

  static const double shellTabBarHeight = 50;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ColorScheme _colorScheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? const ColorScheme.dark() : const ColorScheme.light();
    return base.copyWith(
      brightness: brightness,
      primary: primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: isDark
          ? const Color(0xFF123D68)
          : const Color(0xFFD9EBFF),
      onPrimaryContainer: isDark
          ? const Color(0xFFD9EBFF)
          : const Color(0xFF063A68),
      secondary: signalTeal,
      onSecondary: Colors.white,
      secondaryContainer: isDark
          ? const Color(0xFF123F48)
          : const Color(0xFFD6F4F8),
      onSecondaryContainer: isDark
          ? const Color(0xFFD6F4F8)
          : const Color(0xFF073B45),
      tertiary: ratioGold,
      onTertiary: const Color(0xFF2B2100),
      tertiaryContainer: isDark
          ? const Color(0xFF4A3B12)
          : const Color(0xFFFFF0BE),
      onTertiaryContainer: isDark
          ? const Color(0xFFFFF0BE)
          : const Color(0xFF4A3B12),
      error: dangerRed,
      onError: Colors.white,
      errorContainer: isDark
          ? const Color(0xFF5A1717)
          : const Color(0xFFFFDAD6),
      onErrorContainer: isDark
          ? const Color(0xFFFFDAD6)
          : const Color(0xFF5A1717),
      surface: isDark ? darkSurface : surface,
      onSurface: isDark ? darkInk : ink,
      onSurfaceVariant: isDark ? darkMutedInk : mutedInk,
      surfaceContainerLowest: isDark
          ? const Color(0xFF090B0E)
          : const Color(0xFFFFFFFF),
      surfaceContainerLow: isDark ? darkSurface : surface,
      surfaceContainer: isDark ? darkSurfaceSoft : surfaceSoft,
      surfaceContainerHigh: isDark ? darkSurfaceMuted : surfaceMuted,
      surfaceContainerHighest: isDark
          ? const Color(0xFF343C48)
          : const Color(0xFFDCE3EA),
      outline: isDark ? const Color(0xFF46505C) : const Color(0xFFC4CCD6),
      outlineVariant: isDark
          ? const Color(0xFF303844)
          : const Color(0xFFD9E0E8),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark
          ? const Color(0xFFE6EBF0)
          : const Color(0xFF222831),
      onInverseSurface: isDark
          ? const Color(0xFF222831)
          : const Color(0xFFF4F7FA),
      inversePrimary: isDark
          ? const Color(0xFF74B8FF)
          : const Color(0xFF005EA8),
    );
  }

  static TextStyle _textStyle({
    required double size,
    required FontWeight weight,
    double height = 1.25,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: 0,
      color: color,
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    return TextTheme(
      displayLarge: _textStyle(size: 42, weight: FontWeight.w800, height: 1.1),
      displayMedium: _textStyle(size: 36, weight: FontWeight.w800, height: 1.1),
      displaySmall: _textStyle(size: 30, weight: FontWeight.w800, height: 1.12),
      headlineLarge: _textStyle(
        size: 28,
        weight: FontWeight.w800,
        height: 1.15,
      ),
      headlineMedium: _textStyle(
        size: 24,
        weight: FontWeight.w700,
        height: 1.16,
      ),
      headlineSmall: _textStyle(
        size: 21,
        weight: FontWeight.w700,
        height: 1.18,
      ),
      titleLarge: _textStyle(size: 20, weight: FontWeight.w700, height: 1.2),
      titleMedium: _textStyle(size: 17, weight: FontWeight.w700, height: 1.24),
      titleSmall: _textStyle(size: 15, weight: FontWeight.w700, height: 1.24),
      bodyLarge: _textStyle(size: 16, weight: FontWeight.w500, height: 1.42),
      bodyMedium: _textStyle(size: 14, weight: FontWeight.w500, height: 1.4),
      bodySmall: _textStyle(size: 12.5, weight: FontWeight.w500, height: 1.36),
      labelLarge: _textStyle(size: 14, weight: FontWeight.w700, height: 1.18),
      labelMedium: _textStyle(size: 12, weight: FontWeight.w700, height: 1.14),
      labelSmall: _textStyle(size: 11, weight: FontWeight.w700, height: 1.1),
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }

  static CupertinoTextThemeData _cupertinoTextTheme(ColorScheme scheme) {
    return CupertinoTextThemeData(
      primaryColor: scheme.onSurface,
      textStyle: _textStyle(
        size: 16,
        weight: FontWeight.w500,
      ).copyWith(color: scheme.onSurface),
      actionTextStyle: _textStyle(
        size: 16,
        weight: FontWeight.w700,
      ).copyWith(color: scheme.primary),
      navTitleTextStyle: _textStyle(
        size: 17,
        weight: FontWeight.w700,
      ).copyWith(color: scheme.onSurface),
      navLargeTitleTextStyle: _textStyle(
        size: 34,
        weight: FontWeight.w800,
        height: 1.1,
      ).copyWith(color: scheme.onSurface),
      tabLabelTextStyle: _textStyle(
        size: 11,
        weight: FontWeight.w700,
      ).copyWith(color: scheme.onSurfaceVariant),
      pickerTextStyle: _textStyle(
        size: 20,
        weight: FontWeight.w600,
      ).copyWith(color: scheme.onSurface),
      dateTimePickerTextStyle: _textStyle(
        size: 20,
        weight: FontWeight.w600,
      ).copyWith(color: scheme.onSurface),
    );
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = _colorScheme(brightness);
    final textTheme = _textTheme(scheme);

    final base = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? darkCanvas : canvas,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      useMaterial3: true,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: DownloaderAppBarBackButton.leadingWidth,
        backgroundColor: (isDark ? darkCanvas : canvas).withValues(alpha: 0.92),
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
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
        labelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: textTheme.titleLarge?.copyWith(
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
            fontFamily: fontFamily,
            fontFamilyFallback: fontFallback,
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
            fontFamily: fontFamily,
            fontFamilyFallback: fontFallback,
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
        textStyle: textTheme.bodyMedium?.copyWith(
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
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer.withValues(
          alpha: isDark ? 0.52 : 0.7,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.68),
        ),
        errorStyle: textTheme.labelSmall?.copyWith(color: scheme.error),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.8),
            width: 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 1),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: scheme.primary,
        dividerColor: scheme.outlineVariant.withValues(alpha: 0.55),
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: isDark ? darkCanvas : canvas,
        barBackgroundColor: (isDark ? darkCanvas : canvas).withValues(
          alpha: 0.84,
        ),
        textTheme: _cupertinoTextTheme(scheme),
      ),
    );
  }
}
