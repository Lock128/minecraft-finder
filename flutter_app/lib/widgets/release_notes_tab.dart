import 'package:flutter/material.dart';

class ReleaseNotesTab extends StatelessWidget {
  final bool isDarkMode;

  const ReleaseNotesTab({super.key, required this.isDarkMode});

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.new_releases, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Release Notes - Version 1.0.42',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content
            _buildSectionHeader('🔵 Lapis Lazuli Ore Discovery - NEW!'),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Complete Ore Coverage',
              'Added full Lapis Lazuli ore finding capabilities! Now supports all 7 major '
                  'Minecraft ores including the essential enchanting resource. Lapis generates '
                  'optimally at Y 0-32 with enhanced probability calculations for accurate results.',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Enhanced Mining Guide',
              'Comprehensive lapis mining information added to the guide tab. Learn optimal '
                  'Y-levels, generation patterns, and uses including enchanting tables, blue dye, '
                  'and villager trading. Perfect for setting up your enchanting room!',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Complete UI Integration',
              'Lapis seamlessly integrated into ore selection, filtering, and results display. '
                  'Blue-themed visual elements (🔵) maintain consistency throughout the app. '
                  'All search and filter functionality works perfectly with the new ore type.',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Enhanced Navigation Structure',
              'Improved app organization with new 4-tab layout: Search, Results, Guide, and '
                  'Updates. Release notes now have their own dedicated tab for better accessibility. '
                  'Enhanced App Info dialog provides quick access to ore information and app details.',
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('🔄 Recent Seeds History'),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Quick Seed Access',
              'Never lose track of your favorite world seeds! The app now automatically '
                  'saves your last 5 searched seeds and displays them as clickable options '
                  'below the seed input field. Simply tap any recent seed to instantly use it again.',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Smart Seed Management',
              'Recent seeds are automatically managed - when you search a seed again, '
                  'it moves to the top of the list. The oldest seed is automatically removed '
                  'when you reach the 5-seed limit. All seed digits are fully visible with '
                  'improved monospace formatting for better readability.',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Enhanced User Experience',
              'Perfect for players who test multiple seeds or return to favorite worlds. '
                  'No more manually typing long seed numbers - just click and search! '
                  'Seeds persist across app sessions, so your history is always available.',
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('💾 Complete Search Memory Feature'),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Automatic Parameter Saving',
              'The app remembers ALL your search parameters including world seed, '
                  'X/Y/Z coordinates, and search radius. Everything is automatically '
                  'saved when you type and restored when you restart the app.',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Seamless Workflow',
              'Continue your ore hunting sessions exactly where you left off. '
                  'No more re-entering coordinates or adjusting search settings. '
                  'Focus on finding ores instead of configuring search settings!',
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('🎯 Enhanced User Experience'),
            const SizedBox(height: 12),
            _buildFeatureList([
              'Recent Seeds: Quick access to your last 5 searched world seeds',
              'Time Saving: Eliminates the need to remember and re-enter search parameters',
              'Better Productivity: Focus purely on ore discovery',
              'Cross-Platform: Works consistently across all supported platforms',
              'Smart Defaults: Falls back to sensible defaults for new users',
              'Improved Readability: Monospace font for better seed number visibility',
            ]),
            const SizedBox(height: 20),

            _buildSectionHeader('🔧 Technical Improvements'),
            const SizedBox(height: 12),
            _buildFeatureList([
              'Recent Seeds Storage: Persistent seed history with automatic management',
              'Offline Font Support: Improved performance without internet connection',
              'Comprehensive Persistence: All text input fields are automatically saved',
              'Efficient Storage: Uses platform-native storage for optimal performance',
              'Enhanced Stability: Better error handling and user experience',
              'Full Seed Visibility: Complete seed numbers displayed without truncation',
            ]),
            const SizedBox(height: 20),

            _buildSectionHeader('🎯 Perfect for All Players'),
            const SizedBox(height: 12),
            _buildFeatureList([
              'Seed Explorers: Quickly switch between favorite world seeds',
              'Speedrunners: Quick access to essential ores with saved parameters',
              'Builders: Iron for tools, redstone for mechanisms',
              'Regular Players: Seamless continuation of mining sessions',
              'New Players: Learn optimal mining levels with persistent settings',
              'Content Creators: Easy seed management for showcasing different worlds',
            ]),
            const SizedBox(height: 20),

            _buildSectionHeader('📋 Previous Updates'),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Version 1.0.41 - Recent Seeds History',
              'Introduced automatic seed history management with quick access to your last 5 '
                  'searched seeds. Enhanced user experience with one-tap seed selection, '
                  'persistent storage across sessions, and improved seed number readability '
                  'with monospace formatting.',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Version 1.0.36 - Complete Search Memory',
              'Introduced comprehensive search parameter persistence including world seed, '
                  'X/Y/Z coordinates, and search radius. All search settings are now automatically '
                  'saved when you type and restored when you restart the app. This update addressed '
                  'the most requested feature from the community.',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Version 1.0.27 - Visual Improvements',
              'Updated splash screen and icons for better visual consistency across all platforms. '
                  'Enhanced app branding and improved first-time user experience with cleaner '
                  'visual elements and better icon recognition.',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Version 1.0.22 - Extended Ore Discovery',
              'Major expansion of ore finding capabilities:\n\n'
                  '⚪ Iron Ore: Y -64 to 256 (peaks at Y 15 & Y 232)\n'
                  '🔴 Redstone Ore: Y -64 to 15 (90% concentration at Y -64 to -59)\n'
                  '⚫ Coal Ore: Y 0 to 256 (peaks at Y 96)\n'
                  '🔵 Lapis Lazuli: Y -64 to 64 (enhanced at Y 0-32)\n\n'
                  'Enhanced UI with compact ore selection interface and comprehensive visual legend. '
                  'Improved mining efficiency with detailed Y-level optimization data.',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Version 1.0.15 - Structure Discovery',
              'Added comprehensive structure finding capabilities including villages, strongholds, '
                  'dungeons, mineshafts, temples, and ocean monuments. Introduced biome-aware '
                  'structure generation with accurate coordinate prediction and probability analysis.',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              'Version 1.0.10 - Foundation Release',
              'Initial release with core diamond, gold, and netherite finding functionality. '
                  'Established the fundamental seed analysis engine with coordinate-based searching '
                  'and probability calculations. Introduced the basic UI framework and search system.',
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('🏆 Version History Highlights'),
            const SizedBox(height: 12),
            _buildVersionHistoryTimeline(),
            const SizedBox(height: 20),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2E2E2E) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'NEW: Recent seeds history + all search parameters automatically saved!',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E3A1E) : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDarkMode ? const Color(0xFF4CAF50) : Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(List<String> features) {
    return Column(
      children: features
          .map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: TextStyle(
                            color: isDarkMode
                                ? const Color(0xFF66BB6A)
                                : const Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildVersionHistoryTimeline() {
    final versions = [
      {
        'version': '1.0.41',
        'date': 'Current',
        'highlight': 'Recent Seeds History',
        'color': Colors.green,
      },
      {
        'version': '1.0.36',
        'date': 'Previous',
        'highlight': 'Search Memory',
        'color': Colors.blue,
      },
      {
        'version': '1.0.27',
        'date': 'Earlier',
        'highlight': 'Visual Updates',
        'color': Colors.orange,
      },
      {
        'version': '1.0.22',
        'date': 'Earlier',
        'highlight': 'Extended Ores',
        'color': Colors.purple,
      },
      {
        'version': '1.0.15',
        'date': 'Earlier',
        'highlight': 'Structure Finding',
        'color': Colors.teal,
      },
      {
        'version': '1.0.10',
        'date': 'Earlier',
        'highlight': 'Core Features',
        'color': Colors.indigo,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: versions.map((version) {
          final isLast = version == versions.last;
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: version['color'] as Color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'v${version['version']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (version['color'] as Color)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            version['date'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: version['color'] as Color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          version['highlight'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isLast) ...[
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  width: 1,
                  height: 20,
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }
}
