import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brand colours. Most values switch between the dark and light palettes
/// (see [AppColors.light]); after a switch the app rebuilds every widget.
class AppColors {
  static bool light = false;

  static Color _pick(int dark, int lightValue) =>
      Color(light ? lightValue : dark);

  static Color get bg => _pick(0xFF0B0B10, 0xFFF6F6F9);
  static Color get surface => _pick(0xFF15151E, 0xFFFFFFFF);
  static Color get surface2 => _pick(0xFF1E1E2A, 0xFFEFEFF4);
  static Color get border => _pick(0xFF2A2A3A, 0xFFE1E1EA);
  static Color get shimmer => _pick(0xFF34344A, 0xFFFFFFFF);
  static Color get gold => _pick(0xFFF5B942, 0xFFC98700);
  static Color get platinum => _pick(0xFFB9C6E4, 0xFF5E73A8);
  static Color get text => _pick(0xFFF4F4F6, 0xFF14141B);
  static Color get textSoft => _pick(0xFFCFCFDB, 0xFF3C3C4A);
  static Color get muted => _pick(0xFF9A9AAE, 0xFF6B6B7E);
  static Color get success => _pick(0xFF2ECC71, 0xFF1F9D57);
  static Color get warning => _pick(0xFFFFA726, 0xFFE07B00);

  /// Soft brand-tinted backgrounds for highlight cards.
  static Color get tint => _pick(0xFF241018, 0xFFFDEBEE);
  static Color get tintStrong => _pick(0xFF3A0D16, 0xFFFAD9DE);
  static Color get goldTint => _pick(0xFF3B2A06, 0xFFFFF2D6);

  // Brand red is the same in both themes.
  static const primary = Color(0xFFE0243A);
  static const primaryDark = Color(0xFF9E1428);
  static const primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

const appFont = 'Poppins';
const appFontFallback = ['NotoNaskhArabic'];

/// Every explicit TextStyle in the theme goes through this, so nothing
/// silently falls back to the system font.
TextStyle appTextStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
}) => TextStyle(
  fontFamily: appFont,
  fontFamilyFallback: appFontFallback,
  color: color,
  fontSize: fontSize,
  fontWeight: fontWeight,
);

ThemeData buildTheme() {
  final light = AppColors.light;
  final brightness = light ? Brightness.light : Brightness.dark;
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Poppins',
    fontFamilyFallback: const ['NotoNaskhArabic'],
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      secondary: AppColors.gold,
      surface: AppColors.surface,
    ),
  );
  final radius14 = BorderRadius.circular(14);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      titleTextStyle: appTextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    iconTheme: IconThemeData(color: AppColors.text),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: AppColors.muted,
      textColor: AppColors.text,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => appTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.muted,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: appTextStyle(color: AppColors.muted),
      labelStyle: appTextStyle(color: AppColors.muted),
      prefixIconColor: AppColors.muted,
      border: OutlineInputBorder(
        borderRadius: radius14,
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius14,
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius14,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 52),
        textStyle: appTextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: radius14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        minimumSize: const Size(64, 48),
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: radius14),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surface2,
      selectedColor: AppColors.primary,
      side: BorderSide(color: AppColors.border),
      labelStyle: appTextStyle(color: AppColors.text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: light ? const Color(0xFF1E1E2A) : AppColors.surface2,
      contentTextStyle: appTextStyle(color: const Color(0xFFF4F4F6)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(color: AppColors.border),
  );
}
