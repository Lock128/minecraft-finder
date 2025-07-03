import 'package:flutter/material.dart';

class GuideTab extends StatelessWidget {
  final bool isDarkMode;

  const GuideTab({super.key, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [
                  const Color(0xFF1A237E), // Dark blue
                  const Color(0xFF2E7D32), // Dark green
                ]
              : [
                  const Color(0xFF87CEEB), // Sky blue
                  const Color(0xFF98FB98), // Pale green
                ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildExplanationCard(
              title: '💎 Diamond Generation',
              icon: '💎',
              iconColor: Colors.cyan,
              content: [
                'Diamonds spawn in the Overworld between Y -64 and Y 16.',
                '',
                '🎯 Optimal Y Levels:',
                '• Y -64 to -54: Peak diamond layer (80% base probability)',
                '• Y -53 to -48: Good diamond layer (60% base probability)',
                '• Y -47 to -32: Decent diamond layer (40% base probability)',
                '• Y -31 to 16: Lower diamond layer (20% base probability)',
              ],
            ),
            const SizedBox(height: 16),
            _buildExplanationCard(
              title: '🏅 Gold Generation',
              icon: '🏅',
              iconColor: Colors.amber,
              content: [
                'Gold has different generation patterns based on biome and dimension.',
                '',
                '🌍 Overworld Gold (Y -64 to 32):',
                '• Y -47 to -16: Peak gold layer (60% base probability)',
                '• Y -64 to -48: Lower levels (40% base probability)',
                '• Y -15 to 32: Higher levels (30% base probability)',
                '',
                '🏜️ Badlands/Mesa Biome (BONUS!):',
                '• Y 32 to 80: Excellent surface gold (90% base probability)',
                '• 6x more gold than regular biomes!',
              ],
            ),
            const SizedBox(height: 16),
            _buildExplanationCard(
              title: '🔥 Netherite (Ancient Debris)',
              icon: '🔥',
              iconColor: Colors.deepPurple,
              content: [
                'Ancient Debris is the rarest ore, found only in the Nether.',
                '',
                '🎯 Nether Y Levels (Y 8 to 22):',
                '• Y 13 to 17: Peak ancient debris layer (90% base probability)',
                '• Y 10 to 19: Good ancient debris layer (70% base probability)',
                '• Y 8 to 22: Decent ancient debris layer (50% base probability)',
                '',
                '🔍 Search Modes:',
                '• Regular Search: Uses minimum 15% probability threshold',
                '• Comprehensive Search: Uses 5% threshold, covers 4000x4000 blocks',
              ],
            ),
            const SizedBox(height: 16),
            _buildExplanationCard(
              title: '⚪ Iron Generation',
              icon: '⚪',
              iconColor: Colors.grey,
              content: [
                'Iron is one of the most versatile and common ores in block-based games.',
                '',
                '🎯 Optimal Y Levels:',
                '• Y 128 to 256: Mountain iron generation (peaks at Y 232)',
                '• Y -24 to 56: Underground iron generation (peaks at Y 15)',
                '• Y -64 to 72: General iron availability (40% base probability)',
                '',
                '⚒️ Uses:',
                '• Essential for tools, armor, and redstone contraptions',
                '• Required for anvils, hoppers, and iron golems',
              ],
            ),
            const SizedBox(height: 16),
            _buildExplanationCard(
              title: '🔴 Redstone Generation',
              icon: '🔴',
              iconColor: Colors.red,
              content: [
                'Redstone is the key to automation and complex contraptions.',
                '',
                '🎯 Optimal Y Levels (Y -64 to 15):',
                '• Y -64 to -59: Peak redstone layer (90% base probability)',
                '• Y -58 to -48: Good redstone layer (70% base probability)',
                '• Y -47 to -32: Decent redstone layer (50% base probability)',
                '• Y -31 to 15: Lower redstone layer (30% base probability)',
                '',
                '⚡ Uses:',
                '• Powers pistons, dispensers, and other mechanisms',
                '• Essential for automated farms and contraptions',
              ],
            ),
            const SizedBox(height: 16),
            _buildExplanationCard(
              title: '⚫ Coal Generation',
              icon: '⚫',
              iconColor: Colors.black87,
              content: [
                'Coal is the most common ore and primary fuel source.',
                '',
                '🎯 Optimal Y Levels (Y 0 to 256):',
                '• Y 80 to 136: Peak coal generation (peaks at Y 96)',
                '• Y 0 to 256: General coal availability (60% base probability)',
                '• Found abundantly throughout the overworld',
                '',
                '🔥 Uses:',
                '• Primary fuel for furnaces and campfires',
                '• Crafting torches for lighting and mob prevention',
                '• Can be converted to coal blocks for efficient storage',
              ],
            ),
            const SizedBox(height: 16),
            _buildExplanationCard(
              title: '🏰 Structure Generation',
              icon: '🏰',
              iconColor: Colors.brown,
              content: [
                'Structures are generated based on biome compatibility and rarity patterns.',
                '',
                '🏘️ Common Structures (High Spawn Rate):',
                '• Villages: Plains, desert, savanna, taiga biomes',
                '• Pillager Outposts: Same biomes as villages',
                '• Ruined Portals: Can spawn in any dimension',
                '',
                '🏛️ Rare Structures (Low Spawn Rate):',
                '• Strongholds: Underground, only 128 per world',
                '• End Cities: End dimension outer islands',
                '• Ocean Monuments: Deep ocean biomes',
                '• Ancient Cities: Deep dark biome (Y -52)',
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Pro Tip',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This tool provides statistical predictions based on block game generation algorithms. '
                    'Use the coordinates as starting points for your mining expeditions, and always explore '
                    'the surrounding areas once you find ore veins!',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard({
    required String title,
    required String icon,
    required Color iconColor,
    required List<String> content,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: iconColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isDarkMode
                ? [const Color(0xFF2E2E2E), const Color(0xFF1E1E1E)]
                : [Colors.white, const Color(0xFFF8F9FA)],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: iconColor.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...content.map((line) {
              if (line.isEmpty) {
                return const SizedBox(height: 8);
              } else if (line.startsWith('🎯') ||
                  line.startsWith('🌍') ||
                  line.startsWith('🏜️') ||
                  line.startsWith('🔍') ||
                  line.startsWith('🏘️') ||
                  line.startsWith('🏛️')) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(
                    line,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                      fontSize: 16,
                    ),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    line,
                    style: const TextStyle(height: 1.4, fontSize: 14),
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}
