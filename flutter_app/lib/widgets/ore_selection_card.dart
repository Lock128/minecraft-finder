import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/ore_location.dart';
import '../models/structure_location.dart';
import '../theme/gamer_theme.dart';
import '../utils/ore_utils.dart';

class OreSelectionCard extends StatelessWidget {
  final Set<OreType> selectedOreTypes;
  final bool includeNether;
  final bool includeOres;
  final bool isDarkMode;
  final bool includeStructures;
  final Set<StructureType> selectedStructures;
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
    required this.onOreTypesChanged,
    required this.onIncludeNetherChanged,
    required this.onIncludeOresChanged,
  });

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
            _buildOreSelection(context),
            const SizedBox(height: 8),
            Text(
              OreUtils.getSearchDescription(selectedOreTypes, includeOres,
                  includeStructures, selectedStructures),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (selectedOreTypes.contains(OreType.gold)) ...[
              const SizedBox(height: 12),
              _buildCheckbox(context),
            ],
          ],
        ],
      ),
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
          color: active ? null : (isDarkMode ? GamerColors.darkSurface : Colors.grey.shade100),
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
                color: active ? Colors.white : (isDarkMode ? Colors.white70 : Colors.grey[700]),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? GamerColors.darkSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GamerColors.goldNeon.withValues(alpha: 0.3),
        ),
      ),
      child: CheckboxListTile(
        title: Text(l10n.includeNetherGold, style: const TextStyle(fontSize: 14)),
        subtitle: Text(l10n.searchForNetherGold, style: const TextStyle(fontSize: 12)),
        value: includeNether,
        activeColor: GamerColors.goldNeon,
        onChanged: (bool? value) => onIncludeNetherChanged(value ?? false),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildOreSelection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // First row: Diamond, Gold, Iron
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<OreType>(
            segments: const [
              ButtonSegment<OreType>(
                value: OreType.diamond,
                label: Text('💎', style: TextStyle(fontSize: 16)),
              ),
              ButtonSegment<OreType>(
                value: OreType.gold,
                label: Text('🏅', style: TextStyle(fontSize: 16)),
              ),
              ButtonSegment<OreType>(
                value: OreType.iron,
                label: Text('⚪', style: TextStyle(fontSize: 16)),
              ),
            ],
            selected: selectedOreTypes
                .where((type) => [OreType.diamond, OreType.gold, OreType.iron].contains(type))
                .toSet(),
            multiSelectionEnabled: true,
            emptySelectionAllowed: true,
            onSelectionChanged: (Set<OreType> newSelection) {
              Set<OreType> updated = Set.from(selectedOreTypes);
              updated.removeWhere((t) => [OreType.diamond, OreType.gold, OreType.iron].contains(t));
              updated.addAll(newSelection);
              if (updated.isEmpty) updated.add(OreType.diamond);
              onOreTypesChanged(updated);
            },
            style: SegmentedButton.styleFrom(
              minimumSize: const Size(60, 44),
              backgroundColor: isDarkMode ? GamerColors.darkSurface : Colors.white,
              selectedBackgroundColor: GamerColors.neonGreen.withValues(alpha: isDarkMode ? 0.3 : 0.15),
              selectedForegroundColor: GamerColors.greenText(isDarkMode),
              side: BorderSide(
                color: isDarkMode ? GamerColors.neonGreen.withValues(alpha: 0.3) : GamerColors.lightGreen.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Second row: Redstone, Coal, Lapis
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<OreType>(
            segments: const [
              ButtonSegment<OreType>(
                value: OreType.redstone,
                label: Text('🔴', style: TextStyle(fontSize: 16)),
              ),
              ButtonSegment<OreType>(
                value: OreType.coal,
                label: Text('⚫', style: TextStyle(fontSize: 16)),
              ),
              ButtonSegment<OreType>(
                value: OreType.lapis,
                label: Text('🔵', style: TextStyle(fontSize: 16)),
              ),
            ],
            selected: selectedOreTypes
                .where((type) => [OreType.redstone, OreType.coal, OreType.lapis].contains(type))
                .toSet(),
            multiSelectionEnabled: true,
            emptySelectionAllowed: true,
            onSelectionChanged: (Set<OreType> newSelection) {
              Set<OreType> updated = Set.from(selectedOreTypes);
              updated.removeWhere((t) => [OreType.redstone, OreType.coal, OreType.lapis].contains(t));
              updated.addAll(newSelection);
              if (updated.isEmpty) updated.add(OreType.diamond);
              onOreTypesChanged(updated);
            },
            style: SegmentedButton.styleFrom(
              minimumSize: const Size(60, 44),
              backgroundColor: isDarkMode ? GamerColors.darkSurface : Colors.white,
              selectedBackgroundColor: GamerColors.neonGreen.withValues(alpha: isDarkMode ? 0.3 : 0.15),
              selectedForegroundColor: GamerColors.greenText(isDarkMode),
              side: BorderSide(
                color: isDarkMode ? GamerColors.neonGreen.withValues(alpha: 0.3) : GamerColors.lightGreen.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            _legendItem(l10n.legendDiamond),
            _legendItem(l10n.legendGold),
            _legendItem(l10n.legendIron),
            _legendItem(l10n.legendRedstone),
            _legendItem(l10n.legendCoal),
            _legendItem(l10n.legendLapis),
          ],
        ),
        const SizedBox(height: 12),
        _buildNetheriteButton(context),
      ],
    );
  }

  Widget _legendItem(String text) {
    return Text(text,
      style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.white54 : Colors.grey[500]));
  }

  Widget _buildNetheriteButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSelected = selectedOreTypes.contains(OreType.netherite);
    return _buildToggleButton(
      active: isSelected,
      label: l10n.netheriteAncientDebris,
      emoji: '🔥',
      activeGradient: [GamerColors.neonPurple, GamerColors.neonPink],
      onTap: () {
        Set<OreType> updated = Set.from(selectedOreTypes);
        if (isSelected) {
          updated.remove(OreType.netherite);
        } else {
          updated.add(OreType.netherite);
        }
        onOreTypesChanged(updated);
      },
    );
  }
}
