import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/structure_location.dart';
import '../theme/gamer_theme.dart';
import '../utils/structure_utils.dart';

class StructureSelectionCard extends StatelessWidget {
  final bool includeStructures;
  final Set<StructureType> selectedStructures;
  final bool isDarkMode;
  final Function(bool) onIncludeStructuresChanged;
  final Function(Set<StructureType>) onStructuresChanged;

  const StructureSelectionCard({
    super.key,
    required this.includeStructures,
    required this.selectedStructures,
    required this.isDarkMode,
    required this.onIncludeStructuresChanged,
    required this.onStructuresChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GamerCard(
      isDarkMode: isDarkMode,
      accentColor: GamerColors.neonOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GamerSectionHeader(
            emoji: '🏰',
            title: l10n.structureSearchTitle,
            isDarkMode: isDarkMode,
            accentColor: GamerColors.neonOrange,
          ),
          const SizedBox(height: 16),
          _buildToggleButton(context),
          if (includeStructures) ...[
            const SizedBox(height: 16),
            Text(
              l10n.selectStructuresToFind,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            _buildStructureSelection(context),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => onIncludeStructuresChanged(!includeStructures),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: includeStructures
              ? const LinearGradient(colors: [GamerColors.neonOrange, Color(0xFFFF8F00)])
              : null,
          color: includeStructures ? null : (isDarkMode ? GamerColors.darkSurface : Colors.grey.shade100),
          border: Border.all(
            color: includeStructures
                ? GamerColors.neonOrange.withValues(alpha: 0.6)
                : (isDarkMode ? Colors.white24 : Colors.grey.shade300),
            width: 1.5,
          ),
          boxShadow: includeStructures && isDarkMode
              ? GamerColors.subtleGlow(GamerColors.neonOrange)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏰', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              l10n.includeStructuresInSearch,
              style: TextStyle(
                color: includeStructures ? Colors.white : (isDarkMode ? Colors.white70 : Colors.grey[700]),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStructureSelection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final structures = StructureUtils.getAllStructures();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _actionButton(l10n.selectAll, GamerColors.neonGreen, () {
                onStructuresChanged(
                    structures.map((s) => s['type'] as StructureType).toSet());
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionButton(l10n.clearAll, Colors.grey, () {
                onStructuresChanged({});
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: structures.map((structure) {
                final structureType = structure['type'] as StructureType;
                final isSelected = selectedStructures.contains(structureType);

                return FilterChip(
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        structure['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      Text(
                        structure['rarity'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: StructureUtils.getRarityColor(structure['rarity'] as String),
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    Set<StructureType> updated = Set.from(selectedStructures);
                    if (selected) {
                      updated.add(structureType);
                    } else {
                      updated.remove(structureType);
                    }
                    onStructuresChanged(updated);
                  },
                  selectedColor: GamerColors.neonOrange.withValues(alpha: isDarkMode ? 0.25 : 0.12),
                  checkmarkColor: GamerColors.neonOrange,
                  backgroundColor: isDarkMode ? GamerColors.darkSurface : Colors.grey.shade50,
                  side: BorderSide(
                    color: isSelected
                        ? GamerColors.neonOrange.withValues(alpha: 0.5)
                        : (isDarkMode ? Colors.white12 : Colors.grey.shade300),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                );
              }).toList(),
            ),
          ),
        ),
        if (selectedStructures.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.structuresSelected(selectedStructures.length),
            style: TextStyle(
              color: GamerColors.orangeText(isDarkMode),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withValues(alpha: isDarkMode ? 0.2 : 0.1),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ),
    );
  }
}
