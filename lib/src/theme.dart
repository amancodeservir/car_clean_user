import 'package:flutter/material.dart';

class AppColors {
  static const yellow = Color(0xFFFFC917);
  static const yellowDeep = Color(0xFFF2B600);
  static const yellowSoft = Color(0xFFFFF4C4);
  static const yellowWash = Color(0xFFFFFBEA);

  static const ink = Color(0xFF111827);
  static const inkSoft = Color(0xFF374151);
  static const mute = Color(0xFF6B7280);
  static const faint = Color(0xFF9CA3AF);
  static const line = Color(0xFFE8E8E3);
  static const paper = Color(0xFFF7F7F4);
  static const surface = Colors.white;

  static const navy = Color(0xFF1E3A8A);
  static const green = Color(0xFF15803D);
  static const greenSoft = Color(0xFFE7F6EC);
  static const red = Color(0xFFDC2626);
  static const redSoft = Color(0xFFFDECEC);
  static const blueSoft = Color(0xFFE8EEFF);
  static const orange = Color(0xFFC2410C);
  static const orangeSoft = Color(0xFFFFF1E6);

  /// The pale yellow wash used behind headers, as in the store screenshots.
  static const headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFE680), Color(0xFFFFF6CC), paper],
    stops: [0, 0.55, 1],
  );
}

/// Text styles. The bundled Plus Jakarta Sans is a variable font, so each
/// style sets the weight axis as well as [FontWeight].
class AppText {
  static const family = 'PlusJakartaSans';

  static TextStyle style(double size, FontWeight weight, {Color color = AppColors.ink, double? height}) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
      height: height,
      letterSpacing: size >= 22 ? -0.4 : (size >= 16 ? -0.2 : 0),
    );
  }

  static final hero = style(30, FontWeight.w800, height: 1.08);
  static final h1 = style(24, FontWeight.w800, height: 1.12);
  static final h2 = style(19, FontWeight.w700, height: 1.2);
  static final h3 = style(16, FontWeight.w700, height: 1.25);
  static final title = style(15, FontWeight.w700, height: 1.25);
  static final body = style(14, FontWeight.w500, color: AppColors.inkSoft, height: 1.4);
  static final bodyStrong = style(14, FontWeight.w700, height: 1.35);
  static final small = style(12.5, FontWeight.w500, color: AppColors.mute, height: 1.35);
  static final smallStrong = style(12.5, FontWeight.w700, height: 1.3);
  static final tiny = style(11, FontWeight.w600, color: AppColors.mute, height: 1.25);
  static final button = style(15, FontWeight.w700, height: 1.1);
}

class AppTheme {
  static const radius = 14.0;

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: AppText.family,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.yellow,
        onPrimary: AppColors.ink,
        secondary: AppColors.ink,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: AppColors.ink,
        error: AppColors.red,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    final textTheme = base.textTheme.copyWith(
      displayLarge: AppText.hero,
      displayMedium: AppText.hero,
      displaySmall: AppText.h1,
      headlineLarge: AppText.h1,
      headlineMedium: AppText.h1,
      headlineSmall: AppText.h2,
      titleLarge: AppText.h2,
      titleMedium: AppText.h3,
      titleSmall: AppText.title,
      bodyLarge: AppText.body,
      bodyMedium: AppText.body,
      bodySmall: AppText.small,
      labelLarge: AppText.button,
      labelMedium: AppText.smallStrong,
      labelSmall: AppText.tiny,
    );
    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: AppText.h3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.yellow,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: const Color(0xFFF3E6B0),
          disabledForegroundColor: AppColors.mute,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: shape,
          textStyle: AppText.button,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: const BorderSide(color: AppColors.line, width: 1.2),
          shape: shape,
          textStyle: AppText.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: AppText.smallStrong.copyWith(fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        hintStyle: AppText.body.copyWith(color: AppColors.faint),
        labelStyle: AppText.body.copyWith(color: AppColors.mute),
        floatingLabelStyle: AppText.small.copyWith(color: AppColors.ink),
        prefixIconColor: AppColors.mute,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.ink, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        selectedColor: AppColors.yellowSoft,
        labelStyle: AppText.smallStrong,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        showCheckmark: false,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.ink : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.yellow : AppColors.line,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.ink : Colors.white,
        ),
        checkColor: WidgetStateProperty.all(AppColors.yellow),
        side: const BorderSide(color: AppColors.faint, width: 1.4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.body.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: AppText.h3,
        contentTextStyle: AppText.body,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.line,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.ink),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.ink,
        unselectedLabelColor: AppColors.mute,
        labelStyle: AppText.smallStrong.copyWith(fontSize: 14),
        unselectedLabelStyle: AppText.small.copyWith(fontSize: 14),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.yellow,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
