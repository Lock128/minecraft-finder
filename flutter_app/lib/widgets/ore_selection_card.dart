import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/game_random.dart';
import '../models/ore_location.dart';
import '../models/structure_location.dart';
import '../models/version_availability.dart';
import '../theme/gamer_theme.dart';
import '../utils/ore_utils.dart';

/// Ore selection card — unified, version-aware ore picker.
///
/// Redesign goals (see modernization pass):
///   * One consistent control for every ore, including Netherite, instead of
///     two emoji-only SegmentedButtons plus a separate Netherite button.
///   * Every ore shows a text label + emoji (accessible, no decoder legend).
///   * Only ores that exist in the selected edition/version era are shown, so
///     a pre-1.18 world no longer offers Netherite/Copper.
///   * "Include Nether gold" is shown as a clearly-scoped sub-option of Gold.
class OreSelectionCard extends StatelessWidget {
  final Set<OreType> selectedOreTypes;
  final bool includeNether;
  final bool includeOres;
  final bool isDarkMode;
  final bool includeStructures;
  final Set<StructureType> selectedStructures;
  final MinecraftEdition selectedEdition;
  final VersionEra selectedVersionEra;
  final Function(Set<OreType>) onOreTypesChanged;
  final Function(bool) onIncludeNetherChanged;
  final Function(bool) onIncludeOresChanged;

  const OreSelectionCard({
    super.key,
    required this.selectedOreTypes,
    required this.includeNether,
    required this.includeOres,
    required this.isDarkMode,
    required this.includeStructures,
    required this.selectedStructures,
    required this.selectedEdition,
    required this.selectedVersionEra,
    required this.onOreTypesChanged,
    required this.onIncludeNetherChanged,
    required this.onIncludeOresChanged,
  });

  /// Ores available in the selected era/edition, in canonical order.
  List<OreType> get _availableOres => VersionAvailability.availableOres(
        era: selectedVersionEra,
        edition: selectedEdition,
      );

  /// How many ores are hidden because they don't exist in this version.
  int get _hiddenOreCount => OreType.values.length - _availableOres.length;

  String _oreLabel(AppLocalizations l10n, OreType ore) {
    switch (ore) {
      case OreType.diamond:
        return l10n.filterDiamonds;
      case OreType.gold:
        return l10n.filterGold;
      case OreType.iron:
        return l10n.filterIron;
      case OreType.redstone:
        return l10n.filterRedstone;
      case OreType.coal:
        return l10n.filterCoal;
      case OreType.lapis:
        return l10n.filterLapis;
      case OreType.netherite:
        return l10n.filterNetherite;
      case OreType.copper:
        return l10n.filterCopper;
      case OreType.emerald:
        return l10n.filterEmerald;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GamerCard(
      isDarkMode: isDarkMode,
      accentColor: GamerColors.neonPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GamerSectionHeader(
            emoji: '💎',
            title: l10n.oreTypeTitle,
            isDarkMode: isDarkMode,
            accentColor: GamerColors.neonPurple,
          ),
          const SizedBox(height: 16),
          _buildToggleButton(
            active: includeOres,
            label: l10n.includeOresInSearch,
            emoji: '💎',
            activeGradient: [GamerColors.neonGreen, const Color(0xFF00C853)],
            onTap: () => onIncludeOresChanged(!includeOres),
          ),
          if (includeOres) ...[
            const SizedBox(height: 16),
            _buildOreChips(context, l10n),
            if (_hiddenOreCount > 0) ...[
              const SizedBox(height: 8),
              _buildUnavailableNotice(
                  l10n.oreUnavailableInVersion(_hiddenOreCount)),
            ],
            const SizedBox(height: 8),
            Text(
              OreUtils.getSearchDescription(selectedOreTypes, includeOres,
                  includeStructures, selectedStructures),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            // Nether gold is a sub-option of Gold, shown only when Gold is
            // selected AND gold exists in this version. The label makes clear
            // it only affects the gold search.
            if (selectedOreTypes.contains(OreType.gold) &&
                _availableOres.contains(OreType.gold)) ...[
              const SizedBox(height: 12),
              _buildNetherGoldOption(context, l10n),
            ],
          ],
        ],
      ),
    );
  }

  /// A single uniform chip grid for all available ores, with text labels.
  Widget _buildOreChips(BuildContext context, AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableOres.map((ore) {
        final selected = selectedOreTypes.contains(ore);
        // Netherite keeps its distinctive purple/pink accent; everything else
        // uses the green ore accent so the grid reads as one coherent control.
        final accent =
            ore == OreType.netherite ? GamerColors.neonPurple : GamerColors.neonGreen;
        return FilterChip(
          label: Text(_oreLabel(l10n, ore),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          selected: selected,
          onSelected: (value) {
            final updated = Set<OreType>.from(selectedOreTypes);
            if (value) {
              updated.add(ore);
            } else {
              updated.remove(ore);
            }
            // Never allow an empty ore set while ores are enabled; fall back to
            // the first available ore (keeps the search valid).
            if (updated.isEmpty) updated.add(_availableOres.first);
            onOreTypesChanged(updated);
          },
          showCheckmark: true,
          checkmarkColor: accent,
          selectedColor: accent.withValues(alpha: isDarkMode ? 0.28 : 0.14),
          backgroundColor:
              isDarkMode ? GamerColors.darkSurface : Colors.grey.shade50,
          labelStyle: TextStyle(
            color: selected
                ? (isDarkMode ? Colors.white : const Color(0xFF1A1A2E))
                : (isDarkMode ? Colors.white70 : Colors.grey[800]),
          ),
          side: BorderSide(
            color: selected
                ? accent.withValues(alpha: 0.6)
                : (isDarkMode ? Colors.white12 : Colors.grey.shade300),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );
      }).toList(),
    );
  }

  Widget _buildUnavailableNotice(String text) {
    final color =
        isDarkMode ? GamerColors.neonOrange : GamerColors.lightOrange;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required bool active,
    required String label,
    required String emoji,
    required List<Color> activeGradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: active ? LinearGradient(colors: activeGradient) : null,
          color: active
              ? null
              : (isDarkMode ? GamerColors.darkSurface : Colors.grey.shade100),
          border: Border.all(
            color: active
                ? activeGradient.first.withValues(alpha: 0.6)
                : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
            width: 1.5,
          ),
          boxShadow: active && isDarkMode
              ? GamerColors.subtleGlow(activeGradient.first)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? Colors.white
                    : (isDarkMode ? Colors.white70 : Colors.grey[700]),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Nether-gold sub-option, scoped to the Gold search. Uses a CheckboxListTile
  /// but with a label that makes the scope explicit.
  Widget _buildNetherGoldOption(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? GamerColors.darkSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GamerColors.goldNeon.withValues(alpha: 0.3),
        ),
      ),
      child: CheckboxListTile(
        title:
            Text(l10n.includeNetherGold, style: const TextStyle(fontSize: 14)),
        subtitle: Text(l10n.searchForNetherGold,
            style: const TextStyle(fontSize: 12)),
        value: includeNether,
        activeColor: GamerColors.goldNeon,
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: (bool? value) => onIncludeNetherChanged(value ?? false),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
