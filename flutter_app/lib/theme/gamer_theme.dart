import 'package:flutter/material.dart';

/// Centralized gamer-themed color palette and styling constants.
/// Neon accents on dark surfaces with sharp, angular aesthetics.
class GamerColors {
  // Primary neon accents
  static const neonGreen = Color(0xFF00FF88);
  static const neonCyan = Color(0xFF00E5FF);
  static const neonPurple = Color(0xFFBB86FC);
  static const neonPink = Color(0xFFFF0080);
  static const neonOrange = Color(0xFFFF6D00);
  static const neonYellow = Color(0xFFFFEA00);

  // Surface colors (dark mode)
  static const darkBg = Color(0xFF0D0D0D);
  static const darkSurface = Color(0xFF1A1A2E);
  static const darkCard = Color(0xFF16213E);
  static const darkCardAlt = Color(0xFF0F3460);

  // Surface colors (light mode)
  static const lightBg = Color(0xFFF0F2F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFF8F9FC);

  // Ore-specific neon colors
  static const diamondNeon = Color(0xFF00E5FF);
  static const goldNeon = Color(0xFFFFD600);
  static const netheriteNeon = Color(0xFFE040FB);
  static const ironNeon = Color(0xFFB0BEC5);
  static const redstoneNeon = Color(0xFFFF1744);
  static const coalNeon = Color(0xFF90A4AE);
  static const lapisNeon = Color(0xFF448AFF);

  // Light-mode-safe accent colors (darker variants for readable text on white)
  static const lightGreen = Color(0xFF00873E);
  static const lightCyan = Color(0xFF0088A3);
  static const lightPurple = Color(0xFF7B2FA0);
  static const lightOrange = Color(0xFFD45A00);
  static const lightYellow = Color(0xFF8A7600);
  static const lightDiamond = Color(0xFF007A8C);
  static const lightGold = Color(0xFF9E8500);
  static const lightNetherite = Color(0xFF9C27B0);
  static const lightIron = Color(0xFF546E7A);
  static const lightRedstone = Color(0xFFC62828);
  static const lightCoal = Color(0xFF455A64);
  static const lightLapis = Color(0xFF1565C0);

  // Adaptive color helpers — neon in dark, readable in light
  static Color greenText(bool isDark) => isDark ? neonGreen : lightGreen;
  static Color cyanText(bool isDark) => isDark ? neonCyan : lightCyan;
  static Color purpleText(bool isDark) => isDark ? neonPurple : lightPurple;
  static Color orangeText(bool isDark) => isDark ? neonOrange : lightOrange;
  static Color yellowText(bool isDark) => isDark ? neonYellow : lightYellow;
  static Color diamondText(bool isDark) => isDark ? diamondNeon : lightDiamond;
  static Color goldText(bool isDark) => isDark ? goldNeon : lightGold;
  static Color netheriteText(bool isDark) => isDark ? netheriteNeon : lightNetherite;
  static Color ironText(bool isDark) => isDark ? ironNeon : lightIron;
  static Color redstoneText(bool isDark) => isDark ? redstoneNeon : lightRedstone;
  static Color coalText(bool isDark) => isDark ? coalNeon : lightCoal;
  static Color lapisText(bool isDark) => isDark ? lapisNeon : lightLapis;

  // Glow shadow helper
  static List<BoxShadow> neonGlow(Color color, {double blur = 12, double spread = 0}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.4),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  static List<BoxShadow> subtleGlow(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.2),
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ];
  }
}

class GamerTheme {
  static ThemeData buildLight() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: null,
      colorScheme: ColorScheme.fromSeed(
        seedColor: GamerColors.neonGreen,
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF00873E),
        secondary: GamerColors.neonCyan,
        surface: GamerColors.lightSurface,
        onSurface: const Color(0xFF1A1A2E),
      ),
      scaffoldBackgroundColor: GamerColors.lightBg,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: GamerColors.lightCard,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00873E), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  static ThemeData buildDark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: null,
      colorScheme: ColorScheme.fromSeed(
        seedColor: GamerColors.neonGreen,
        brightness: Brightness.dark,
      ).copyWith(
        primary: GamerColors.neonGreen,
        secondary: GamerColors.neonCyan,
        surface: GamerColors.darkSurface,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: GamerColors.darkBg,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: GamerColors.darkCard,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GamerColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GamerColors.neonGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}

/// Reusable gamer-styled card wrapper with neon border glow.
class GamerCard extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;
  final Color accentColor;
  final EdgeInsetsGeometry padding;

  const GamerCard({
    super.key,
    required this.child,
    required this.isDarkMode,
    this.accentColor = GamerColors.neonGreen,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDarkMode ? GamerColors.darkCard : GamerColors.lightCard,
        border: Border.all(
          color: accentColor.withValues(alpha: isDarkMode ? 0.5 : 0.3),
          width: 1.5,
        ),
        boxShadow: isDarkMode
            ? GamerColors.subtleGlow(accentColor)
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Section header with neon accent bar.
class GamerSectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final bool isDarkMode;
  final Color accentColor;

  const GamerSectionHeader({
    super.key,
    required this.emoji,
    required this.title,
    required this.isDarkMode,
    this.accentColor = GamerColors.neonGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
            boxShadow: isDarkMode ? GamerColors.subtleGlow(accentColor) : null,
          ),
        ),
        const SizedBox(width: 12),
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
