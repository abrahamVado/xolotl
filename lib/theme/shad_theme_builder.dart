import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

///1.- ShadThemeBuilder sincroniza los esquemas Material con el sistema de shadcn.
class ShadThemeBuilder {
  const ShadThemeBuilder._();

  ///2.- fromMaterial genera ThemeData de shadcn respetando el modo solicitado.
  static shad.ThemeData fromMaterial({
    required ColorScheme lightScheme,
    required ColorScheme darkScheme,
    required ThemeMode mode,
    double lightSurfaceOpacity = 0.08,
    double darkSurfaceOpacity = 0.18,
    double surfaceBlur = 24,
  }) {
    final brightness = _resolveBrightness(mode);
    final scheme = brightness == Brightness.dark ? darkScheme : lightScheme;
    final surfaceOpacity =
        brightness == Brightness.dark ? darkSurfaceOpacity : lightSurfaceOpacity;
    return _createTheme(
      scheme: scheme,
      surfaceOpacity: surfaceOpacity,
      surfaceBlur: surfaceBlur,
    );
  }

  ///3.- _resolveBrightness consulta el modo y, si aplica, el brillo del sistema.
  static Brightness _resolveBrightness(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  ///4.- _createTheme construye ThemeData considerando la luminosidad activa.
  static shad.ThemeData _createTheme({
    required ColorScheme scheme,
    required double surfaceOpacity,
    required double surfaceBlur,
  }) {
    final mappedScheme = _mapScheme(scheme);
    if (scheme.brightness == Brightness.dark) {
      return shad.ThemeData.dark(
        colorScheme: mappedScheme,
        surfaceOpacity: surfaceOpacity,
        surfaceBlur: surfaceBlur,
      );
    }
    return shad.ThemeData(
      colorScheme: mappedScheme,
      surfaceOpacity: surfaceOpacity,
      surfaceBlur: surfaceBlur,
    );
  }

  ///5.- _mapScheme traduce los roles de ColorScheme de Material a shadcn.
  static shad.ColorScheme _mapScheme(ColorScheme scheme) {
    return shad.ColorScheme(
      brightness: scheme.brightness,
      background: scheme.background,
      foreground: scheme.onBackground,
      card: scheme.surface,
      cardForeground: scheme.onSurface,
      popover: scheme.surfaceVariant,
      popoverForeground: scheme.onSurfaceVariant,
      primary: scheme.primary,
      primaryForeground: scheme.onPrimary,
      secondary: scheme.secondaryContainer,
      secondaryForeground: scheme.onSecondaryContainer,
      muted: scheme.surfaceVariant,
      mutedForeground: scheme.onSurfaceVariant.withOpacity(0.8),
      accent: scheme.tertiaryContainer,
      accentForeground: scheme.onTertiaryContainer,
      destructive: scheme.error,
      destructiveForeground: scheme.onError,
      border: scheme.outline,
      input: scheme.outlineVariant,
      ring: scheme.primary,
      chart1: scheme.primary,
      chart2: scheme.secondary,
      chart3: scheme.tertiary,
      chart4: scheme.primaryContainer,
      chart5: scheme.secondaryContainer,
      sidebar: scheme.surface,
      sidebarForeground: scheme.onSurface,
      sidebarPrimary: scheme.primary,
      sidebarPrimaryForeground: scheme.onPrimary,
      sidebarAccent: scheme.surfaceVariant,
      sidebarAccentForeground: scheme.onSurfaceVariant,
      sidebarBorder: scheme.outlineVariant,
      sidebarRing: scheme.primary,
    );
  }
}
