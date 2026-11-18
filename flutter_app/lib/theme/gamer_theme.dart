import 'package:material_ui/material_ui.dart';

/// Centralized gamer-themed color palette and styling constants.
/// Calm, flat Material 3 surfaces with soft accent colors (dark mode uses
/// pastel accents instead of neon).
class GamerColors {
  // Primary neon accents
  static const neonGreen = Color(0xFF5EE0A0);
  static const neonCyan = Color(0xFF5CCBE6);
  static const neonPurple = Color(0xFFB39DFA);
  static const neonPink = Color(0xFFFF7BAE);
  static const neonOrange = Color(0xFFFFA05A);
  static const neonYellow = Color(0xFFF2D14B);

  // Surface colors (dark mode)
  static const darkBg = Color(0xFF0E1311);
  static const darkSurface = Color(0xFF151B18);
  static const darkCard = Color(0xFF1B2320);
  static const darkCardAlt = Color(0xFF243029);

  // Surface colors (light mode)
  // Intentional elevation hierarchy (lightest sits on top):
  //   lightBg (scaffold) < lightCard (cards) < lightSurface (inputs/headers).
  static const lightBg = Color(0xFFF4F6F3);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);

  // Ore-specific neon colors
  static const diamondNeon = Color(0xFF4FD8EB);
  static const goldNeon = Color(0xFFF5C842);
  static const netheriteNeon = Color(0xFFD58BF5);
  static const ironNeon = Color(0xFFB0BEC5);
  static const redstoneNeon = Color(0xFFFF6B6B);
  static const coalNeon = Color(0xFF90A4AE);
  static const lapisNeon = Color(0xFF6C9BFF);

  // Light-mode-safe accent colors (darker variants for readable text on white).
  // Every value below is tuned to meet WCAG AA (>=4.5:1 for normal text)
  // against the worst-case light surface (lightBg #F0F2F5), so they stay
  // readable on cards (#F8F9FC) and inputs (#FFFFFF) too. Hues match their
  // neon counterparts so the palette stays cohesive across themes.
  // lightDiamond and lightCyan are kept as distinct teals: diamond ore skews
  // bluer (#00698C) while the generic cyan accent is greener (#00727F),
  // mirroring diamondNeon vs neonCyan in dark mode.
  static const lightGreen = Color(0xFF007A37);
  static const lightCyan = Color(0xFF00727F);
  static const lightPurple = Color(0xFF7B2FA0);
  static const lightOrange = Color(0xFFB84A00);
  static const lightYellow = Color(0xFF7A6600);
  static const lightDiamond = Color(0xFF00698C);
  static const lightGold = Color(0xFF7E6A00);
  static const lightNetherite = Color(0xFF9C27B0);
  static const lightIron = Color(0xFF4B636E);
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
  static Color netheriteText(bool isDark) =>
      isDark ? netheriteNeon : lightNetherite;
  static Color ironText(bool isDark) => isDark ? ironNeon : lightIron;
  static Color redstoneText(bool isDark) =>
      isDark ? redstoneNeon : lightRedstone;
  static Color coalText(bool isDark) => isDark ? coalNeon : lightCoal;
  static Color lapisText(bool isDark) => isDark ? lapisNeon : lightLapis;

  /// Maps a dark-mode neon accent to its readable light-mode variant.
  /// Use this anywhere a neon constant is applied to light-mode text, icons,
  /// card borders, or section bars so accents stay consistent and legible.
  /// In dark mode the original neon is returned unchanged.
  static Color adaptiveAccent(Color neon, bool isDark) {
    if (isDark) return neon;
    if (neon == neonGreen) return lightGreen;
    if (neon == neonCyan) return lightCyan;
    if (neon == neonPurple) return lightPurple;
    if (neon == neonOrange) return lightOrange;
    if (neon == neonYellow) return lightYellow;
    if (neon == goldNeon) return lightGold;
    if (neon == diamondNeon) return lightDiamond;
    if (neon == netheriteNeon) return lightNetherite;
    if (neon == ironNeon) return lightIron;
    if (neon == redstoneNeon) return lightRedstone;
    if (neon == coalNeon) return lightCoal;
    if (neon == lapisNeon) return lightLapis;
    return neon;
  }

  /// Muted/secondary foreground text that routes through the theme's
  /// onSurface color so it stays legible in both light and dark mode.
  /// Prefer this over hardcoded `Colors.grey[*]` for light-mode labels.
  static Color mutedText(BuildContext context, {double alpha = 0.70}) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: alpha);

  /// De-emphasized icon color. Same theme-driven basis as [mutedText].
  static Color mutedIcon(BuildContext context, {double alpha = 0.70}) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: alpha);

  // Glow helpers are kept for source compatibility but return no shadows: the
  // UI is flat, and depth comes from surface tone and a hairline outline.
  static List<BoxShadow> neonGlow(
    Color color, {
    double blur = 12,
    double spread = 0,
  }) => const [];

  static List<BoxShadow> subtleGlow(Color color) => const [];
}

class GamerTheme {
  static ThemeData buildLight() => _build(
    ColorScheme.fromSeed(
      seedColor: GamerColors.lightGreen,
      brightness: Brightness.light,
    ).copyWith(
      primary: GamerColors.lightGreen,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD7F0E0),
      onPrimaryContainer: const Color(0xFF00391A),
      secondary: GamerColors.lightCyan,
      secondaryContainer: const Color(0xFFDDEBEC),
      onSecondaryContainer: const Color(0xFF002F35),
      surface: GamerColors.lightBg,
      onSurface: const Color(0xFF171C19),
      onSurfaceVariant: const Color(0xFF45504A),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFFFFFFF),
      surfaceContainer: const Color(0xFFEEF2EE),
      surfaceContainerHigh: const Color(0xFFE7ECE7),
      surfaceContainerHighest: const Color(0xFFE0E6E0),
      outline: const Color(0xFF727D76),
      outlineVariant: const Color(0xFFDCE3DC),
    ),
    scaffold: GamerColors.lightBg,
  );

  static ThemeData buildDark() => _build(
    ColorScheme.fromSeed(
      seedColor: GamerColors.neonGreen,
      brightness: Brightness.dark,
    ).copyWith(
      primary: GamerColors.neonGreen,
      onPrimary: const Color(0xFF00391F),
      primaryContainer: const Color(0xFF1F4A35),
      onPrimaryContainer: const Color(0xFFC4F5DA),
      secondaryContainer: const Color(0xFF1E414A),
      onSecondaryContainer: const Color(0xFFCDEFF7),
      surface: GamerColors.darkBg,
      onSurface: const Color(0xFFE6EBE8),
      onSurfaceVariant: const Color(0xFFB0BBB5),
      surfaceContainerLowest: const Color(0xFF0A0E0C),
      surfaceContainerLow: GamerColors.darkCard,
      surfaceContainer: GamerColors.darkSurface,
      surfaceContainerHigh: GamerColors.darkCardAlt,
      surfaceContainerHighest: const Color(0xFF2C3A33),
      outline: const Color(0xFF7D8A83),
      outlineVariant: const Color(0xFF2A3630),
      secondary: GamerColors.neonCyan,
    ),
    scaffold: GamerColors.darkBg,
  );

  static ThemeData _build(ColorScheme scheme, {required Color scaffold}) {
    final isDark = scheme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(12);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      visualDensity: VisualDensity.standard,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        labelType: NavigationRailLabelType.all,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: TextStyle(
          color: scheme.onPrimaryContainer,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primaryContainer
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.5)
            : scheme.surfaceContainerLowest,
        border: border(scheme.outlineVariant),
        enabledBorder: border(scheme.outlineVariant),
        focusedBorder: border(scheme.primary, 2),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Flat surface used for every section on the screen: tonal fill with a
/// hairline outline, no glow and no shadow.
class GamerCard extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;

  /// Kept for source compatibility. Sections no longer draw accent borders.
  final Color accentColor;
  final EdgeInsetsGeometry padding;

  const GamerCard({
    super.key,
    required this.child,
    required this.isDarkMode,
    this.accentColor = GamerColors.neonGreen,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Material (not a decorated Container) so ListTile children can paint
    // their ink and splashes on the card surface.
    return Material(
      color: isDarkMode ? GamerColors.darkCard : GamerColors.lightCard,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Plain section title. Shows an optional Material [icon] or legacy [emoji]
/// before the text.
class GamerSectionHeader extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final String title;
  final bool isDarkMode;

  /// Kept for source compatibility. The header no longer draws an accent bar.
  final Color accentColor;

  const GamerSectionHeader({
    super.key,
    this.emoji,
    this.icon,
    required this.title,
    required this.isDarkMode,
    this.accentColor = GamerColors.neonGreen,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
        ] else if (emoji != null) ...[
          Text(emoji!, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
