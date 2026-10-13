import 'package:flutter/material.dart';

/// "Ruhig & warm": gedämpftes Rosé, Salbeigrün, cremiger Hintergrund, weiche Rundungen.
class LotusColors {
  static const rose = Color(0xFFB8677A);
  static const roseLight = Color(0xFFF3DDE2);
  static const sage = Color(0xFF7E9C83);
  static const sageLight = Color(0xFFE1EBE2);
  static const cream = Color(0xFFFBF7F2);
  static const sand = Color(0xFFF1EAE1);
  static const ink = Color(0xFF2F2A28);
  static const inkSoft = Color(0xFF6E6560);
  static const warning = Color(0xFFB7791F);
  static const warningLight = Color(0xFFFBF0DC);

  static const night = Color(0xFF1C1918);
  static const nightSurface = Color(0xFF292423);
  static const roseNight = Color(0xFFE19AAB);
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: LotusColors.rose, brightness: Brightness.light).copyWith(
    primary: LotusColors.rose,
    onPrimary: Colors.white,
    primaryContainer: LotusColors.roseLight,
    onPrimaryContainer: LotusColors.ink,
    secondary: LotusColors.sage,
    onSecondary: Colors.white,
    secondaryContainer: LotusColors.sageLight,
    onSecondaryContainer: LotusColors.ink,
    surface: LotusColors.cream,
    onSurface: LotusColors.ink,
    onSurfaceVariant: LotusColors.inkSoft,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFF7F1EA),
    surfaceContainer: LotusColors.sand,
    surfaceContainerHigh: const Color(0xFFEBE2D7),
    outlineVariant: const Color(0xFFE2D8CC),
  );
  return _base(scheme);
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: LotusColors.rose, brightness: Brightness.dark).copyWith(
    primary: LotusColors.roseNight,
    onPrimary: LotusColors.night,
    secondary: const Color(0xFFA8C3AC),
    surface: LotusColors.night,
    surfaceContainerLowest: const Color(0xFF161312),
    surfaceContainer: LotusColors.nightSurface,
  );
  return _base(scheme);
}

ThemeData _base(ColorScheme scheme) {
  const radius = BorderRadius.all(Radius.circular(20));
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLowest,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52), shape: const StadiumBorder()),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.primaryContainer,
      elevation: 0,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
