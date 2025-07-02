import 'package:flutter/material.dart';

class ReleaseNotesDialog extends StatelessWidget {
  final bool isDarkMode;

  const ReleaseNotesDialog({super.key, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF4CAF50),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.new_releases, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Release Notes - Version 1.0.21',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: Container(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                          '🆕 Major Update: Extended Ore Discovery'),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        '⚪ Iron Ore Discovery',
                        'Y-Level Range: Y -64 to 256 (entire world height)\n'
                            'Peak Zones: Y 15 (underground) & Y 232 (mountains)\n'
                            'Essential for tools, armor, and redstone contraptions',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        '🔴 Redstone Ore Discovery',
                        'Y-Level Range: Y -64 to 15 (deep underground)\n'
                            'Peak Zone: Y -64 to -59 (90% probability)\n'
                            'Perfect for automation systems and contraptions',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        '⚫ Coal Ore Discovery',
                        'Y-Level Range: Y 0 to 256 (surface to sky)\n'
                            'Peak Zone: Y 80-136 (peaks at Y 96)\n'
                            'Primary fuel source and torch crafting',
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader('🎨 Enhanced User Interface'),
                      const SizedBox(height: 12),
                      _buildFeatureList([
                        'Compact ore selection with space-efficient layout',
                        'Visual legend showing what each emoji represents',
                        'Enhanced results filtering for all 6 ore types',
                        'Improved color coding in results display',
                      ]),
                      const SizedBox(height: 20),
                      _buildSectionHeader('📚 Comprehensive Guide Updates'),
                      const SizedBox(height: 12),
                      _buildFeatureList([
                        'Detailed mining guides for Iron, Redstone, and Coal',
                        'Optimal Y-level data for efficient mining',
                        'Practical usage information for each ore type',
                        'Enhanced formatting with emojis and color coding',
                      ]),
                      const SizedBox(height: 20),
                      _buildSectionHeader('🛠 Technical Improvements'),
                      const SizedBox(height: 12),
                      _buildFeatureList([
                        'Realistic ore generation patterns matching Minecraft',
                        'Optimized search performance for multiple ore types',
                        'Better error handling and stability improvements',
                        'Enhanced probability calculations for accuracy',
                      ]),
                      const SizedBox(height: 20),
                      _buildSectionHeader('🎯 Perfect for All Players'),
                      const SizedBox(height: 12),
                      _buildFeatureList([
                        'Speedrunners: Quick access to essential ores',
                        'Builders: Iron for tools, redstone for mechanisms',
                        'Automation enthusiasts: Redstone for contraptions',
                        'New players: Learn optimal mining levels',
                      ]),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2E2E2E) : Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Now supporting all 6 major Minecraft ore types!',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Got it!'),
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

  static void show(BuildContext context, {bool isDarkMode = false}) {
    showDialog(
      context: context,
      builder: (context) => ReleaseNotesDialog(isDarkMode: isDarkMode),
    );
  }
}
