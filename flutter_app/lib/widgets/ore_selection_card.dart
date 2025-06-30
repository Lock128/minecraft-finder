import 'package:flutter/material.dart';
import '../models/ore_location.dart';
import '../models/structure_location.dart';
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
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFF4CAF50), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isDarkMode
                ? [
                    const Color(0xFF2E2E2E),
                    const Color(0xFF1E1E1E),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF1F8E9),
                  ],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Center(
                    child: Text('💎', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Ore Type',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: includeOres
                    ? LinearGradient(
                        colors: [
                          const Color(0xFF4CAF50),
                          const Color(0xFF2E7D32)
                        ],
                      )
                    : null,
                border: Border.all(
                  color: includeOres ? const Color(0xFF4CAF50) : Colors.grey,
                  width: 2,
                ),
              ),
              child: OutlinedButton.icon(
                onPressed: () => onIncludeOresChanged(!includeOres),
                icon: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Center(
                    child: Text('💎', style: TextStyle(fontSize: 10)),
                  ),
                ),
                label: Text(
                  'Include Ores in Search',
                  style: TextStyle(
                    color: includeOres ? Colors.white : const Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.transparent,
                  side: BorderSide.none,
                ),
              ),
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
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Include Nether Gold'),
                  subtitle: const Text('Search for Nether Gold Ore'),
                  value: includeNether,
                  onChanged: (bool? value) =>
                      onIncludeNetherChanged(value ?? false),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOreSelection(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<OreType>(
            segments: [
              ButtonSegment<OreType>(
                value: OreType.diamond,
                label: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('💎 Diamonds',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              ButtonSegment<OreType>(
                value: OreType.gold,
                label: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('🏅 Gold',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            selected: selectedOreTypes
                .where((type) => type != OreType.netherite)
                .toSet(),
            multiSelectionEnabled: true,
            onSelectionChanged: (Set<OreType> newSelection) {
              Set<OreType> updatedSelection = Set.from(newSelection);
              if (selectedOreTypes.contains(OreType.netherite)) {
                updatedSelection.add(OreType.netherite);
              }
              if (updatedSelection.isNotEmpty) {
                onOreTypesChanged(updatedSelection);
              }
            },
            style: SegmentedButton.styleFrom(
              minimumSize: const Size(120, 48),
              backgroundColor:
                  isDarkMode ? const Color(0xFF2E2E2E) : Colors.white,
              selectedBackgroundColor: const Color(0xFF4CAF50),
              selectedForegroundColor: Colors.white,
              side: BorderSide(color: const Color(0xFF4CAF50)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildNetheriteButton(),
      ],
    );
  }

  Widget _buildNetheriteButton() {
    final isSelected = selectedOreTypes.contains(OreType.netherite);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: isSelected
            ? LinearGradient(
                colors: [Colors.deepPurple, Colors.purple[700]!],
              )
            : null,
        border: Border.all(
          color: isSelected ? Colors.deepPurple : Colors.grey,
          width: 2,
        ),
      ),
      child: OutlinedButton.icon(
        onPressed: () {
          Set<OreType> updated = Set.from(selectedOreTypes);
          if (isSelected) {
            updated.remove(OreType.netherite);
          } else {
            updated.add(OreType.netherite);
          }
          onOreTypesChanged(updated);
        },
        icon: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF2C1810),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Center(
            child: Text('🔥', style: TextStyle(fontSize: 12)),
          ),
        ),
        label: Text(
          'Netherite (Ancient Debris)',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          side: BorderSide.none,
        ),
      ),
    );
  }
}
