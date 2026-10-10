import 'package:flutter/material.dart';

import '../utils/constants.dart';

class BrandTheme {
  static const fontFamily = 'PlusJakartaSans';
  static BoxDecoration get card => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.line, width: AppConstants.thinBorderWidth),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C111827),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      );

  static TextStyle sans({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static ThemeData get data {
    final buttonLabel = sans(fontWeight: FontWeight.w700, fontSize: AppType.title.fontSize);
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppConstants.paper,
      colorScheme: const ColorScheme.light(
        primary: AppConstants.signal,
        onPrimary: Colors.white,
        secondary: AppConstants.signal,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: AppConstants.ink,
      ),
    );
    final pill = FilledButton.styleFrom(
      backgroundColor: AppConstants.signal,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFBFDBFE),
      disabledForegroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      shape: const StadiumBorder(),
      textStyle: buttonLabel,
    );
    final textTheme = base.textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ).copyWith(
      displayLarge: AppType.display,
      displayMedium: AppType.display,
      displaySmall: AppType.display,
      headlineLarge: AppType.display,
      headlineMedium: AppType.display,
      headlineSmall: AppType.title,
      titleLarge: AppType.title,
      titleMedium: AppType.title,
      titleSmall: AppType.caption,
      bodyLarge: AppType.body,
      bodyMedium: AppType.body,
      bodySmall: AppType.caption,
      labelLarge: AppType.body,
      labelMedium: AppType.caption,
      labelSmall: AppType.caption,
    );
    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.paper,
        foregroundColor: AppConstants.ink,
        surfaceTintColor: AppConstants.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppConstants.ink, size: AppConstants.iconSize),
        titleTextStyle: AppType.title,
      ),
      iconTheme: const IconThemeData(color: AppConstants.signal, size: AppConstants.iconSize),
      dividerColor: AppConstants.line,
      dividerTheme: const DividerThemeData(color: AppConstants.line, thickness: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppConstants.signal),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppConstants.ink,
        contentTextStyle: sans(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: StadiumBorder(),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppConstants.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: pill),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.signal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFBFDBFE),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: buttonLabel,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.signal,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppConstants.signal, width: 1.4),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: buttonLabel,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.signal,
          textStyle: sans(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: AppType.label,
        labelStyle: AppType.label,
        prefixIconColor: AppConstants.signal,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppConstants.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppConstants.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppConstants.signal, width: 1.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        selectedColor: AppConstants.well,
        labelStyle: sans(color: AppConstants.ink, fontWeight: FontWeight.w600),
        secondaryLabelStyle: sans(color: AppConstants.ink, fontWeight: FontWeight.w600),
        side: const BorderSide(color: AppConstants.line),
        shape: const StadiumBorder(side: BorderSide(color: AppConstants.line)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppConstants.signal;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppConstants.well;
          return AppConstants.line;
        }),
      ),
    );
  }
}

class BrandIconWell extends StatelessWidget {
  const BrandIconWell({
    super.key,
    required this.icon,
    this.box = 40,
    this.iconSize = AppConstants.iconSize,
    this.color,
  });

  final IconData icon;
  final double box;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: box,
      height: box,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppConstants.well,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: iconSize, color: color ?? AppConstants.signal),
    );
  }
}

class AppType {
  static final TextStyle display = BrandTheme.sans(
    color: Colors.black,
    fontSize: 26,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  static final TextStyle title = BrandTheme.sans(
    color: Colors.black,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static final TextStyle item = BrandTheme.sans(
    color: Colors.black,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  static final TextStyle body = BrandTheme.sans(
    color: Colors.black,
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w300,
  );

  static final TextStyle label = BrandTheme.sans(
    color: Colors.black,
    fontSize: 12,
    height: 1.25,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle caption = label;
}

class BrandPhoto extends StatelessWidget {
  const BrandPhoto({
    super.key,
    required this.asset,
    this.height = 180,
  });

  final String asset;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
          asset,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
