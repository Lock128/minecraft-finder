import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/ore_location.dart';
import '../theme/gamer_theme.dart';

/// A lightweight, additive "Quick Start" affordance shown near the top of the
/// search form. It lets a new user start a search in one tap by prefilling
/// sensible defaults (world spawn center, a reasonable radius) and selecting a
/// common target set, then surfaces short inline hints to reduce confusion.
///
/// It is purely additive: it writes into the existing controllers and calls the
/// existing state setters owned by the parent. No control is removed and no new
/// state-management library is introduced.
class QuickStartCard extends StatelessWidget {
  final TextEditingController xController;
  final TextEditingController yController;
  final TextEditingController zController;
  final TextEditingController radiusController;
  final bool isDarkMode;

  /// Enables/disables ore searching (wired to the existing setter).
  final Function(bool) onIncludeOresChanged;

  /// Replaces the selected ore set (wired to the existing setter).
  final Function(Set<OreType>) onOreTypesChanged;

  const QuickStartCard({
    super.key,
    required this.xController,
    required this.yController,
    required this.zController,
    required this.radiusController,
    required this.onIncludeOresChanged,
    required this.onOreTypesChanged,
    this.isDarkMode = false,
  });

  /// Applies the "Diamonds near spawn" preset: center the search on world
  /// spawn (0, 0), clear the optional Y coordinate, use a generous radius, and
  /// select diamonds with ore searching enabled.
  void _applyDiamondsNearSpawn() {
    xController.text = '0';
    zController.text = '0';
    yController.text = '';
    radiusController.text = '1000';
    onIncludeOresChanged(true);
    onOreTypesChanged({OreType.diamond});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GamerCard(
      isDarkMode: isDarkMode,
      accentColor: GamerColors.neonYellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GamerSectionHeader(
            emoji: '\u26A1',
            title: l10n.quickStartTitle,
            isDarkMode: isDarkMode,
            accentColor: GamerColors.neonYellow,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.quickStartHint,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDarkMode ? Colors.white70 : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const Text('\u{1F48E}', style: TextStyle(fontSize: 14)),
              label: Text(l10n.quickStartDiamondsNearSpawn),
              onPressed: _applyDiamondsNearSpawn,
              backgroundColor:
                  isDarkMode ? GamerColors.darkSurface : Colors.white,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: GamerColors.cyanText(isDarkMode),
              ),
              side: BorderSide(
                color: GamerColors.neonCyan
                    .withValues(alpha: isDarkMode ? 0.4 : 0.3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildTip(context, '\u{1F331}', l10n.quickStartSeedTip),
          const SizedBox(height: 8),
          _buildTip(context, '\u{1F4CD}', l10n.quickStartSpawnTip),
        ],
      ),
    );
  }

  Widget _buildTip(BuildContext context, String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: isDarkMode ? Colors.white54 : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}
