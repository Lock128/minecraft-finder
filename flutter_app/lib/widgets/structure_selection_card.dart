import 'package:flutter/material.dart';
import '../models/structure_location.dart';
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
                    color: const Color(0xFF8B4513),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Center(
                    child: Text('🏰', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Structure Search',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: includeStructures
                    ? LinearGradient(
                        colors: [
                          const Color(0xFF4CAF50),
                          const Color(0xFF2E7D32)
                        ],
                      )
                    : null,
                border: Border.all(
                  color:
                      includeStructures ? const Color(0xFF4CAF50) : Colors.grey,
                  width: 2,
                ),
              ),
              child: OutlinedButton.icon(
                onPressed: () => onIncludeStructuresChanged(!includeStructures),
                icon: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Center(
                    child: Text('🏰', style: TextStyle(fontSize: 10)),
                  ),
                ),
                label: Text(
                  'Include Structures in Search',
                  style: TextStyle(
                    color: includeStructures
                        ? Colors.white
                        : const Color(0xFF2E7D32),
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
            if (includeStructures) ...[
              const SizedBox(height: 16),
              Text(
                'Select Structures to Find:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildStructureSelection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStructureSelection() {
    final structures = StructureUtils.getAllStructures();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  onStructuresChanged(structures
                      .map((s) => s['type'] as StructureType)
                      .toSet());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Select All'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => onStructuresChanged({}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear All'),
              ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        structure['rarity'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: StructureUtils.getRarityColor(
                              structure['rarity'] as String),
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
                  selectedColor: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  checkmarkColor: const Color(0xFF2E7D32),
                );
              }).toList(),
            ),
          ),
        ),
        if (selectedStructures.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${selectedStructures.length} structures selected',
            style: const TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
