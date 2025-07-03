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
                      'Release Notes - Version 1.0.36',
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
                      _buildSectionHeader('💾 Complete Search Memory Feature'),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        'Automatic Parameter Saving',
                        'The app now remembers ALL your search parameters including world seed, '
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
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        'Perfect for Regular Users',
                        'Ideal for players who frequently search the same world areas. '
                            'Never lose your search configuration again with instant restoration '
                            'of all your last search settings.',
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader('🎯 Enhanced User Experience'),
                      const SizedBox(height: 12),
                      _buildFeatureList([
                        'Time Saving: Eliminates the need to remember and re-enter search parameters',
                        'Better Productivity: Focus purely on ore discovery',
                        'Cross-Platform: Works consistently across all supported platforms',
                        'Smart Defaults: Falls back to sensible defaults for new users',
                      ]),
                      const SizedBox(height: 20),
                      _buildSectionHeader('🔧 Technical Improvements'),
                      const SizedBox(height: 12),
                      _buildFeatureList([
                        'Comprehensive Persistence: All text input fields are automatically saved',
                        'Efficient Storage: Uses platform-native storage for optimal performance',
                        'Enhanced Stability: Better error handling and user experience',
                        'Addresses most requested feature from the community',
                      ]),
                      const SizedBox(height: 20),
                      _buildSectionHeader('📋 Previous Updates'),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        'Version 1.0.27 - Minor Update',
                        'Updated splash screen and icons for better visual consistency.',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        'Version 1.0.22 - Extended Ore Discovery',
                        '⚪ Iron Ore (Y -64 to 256, peaks at Y 15 & Y 232)\n'
                            '🔴 Redstone Ore (Y -64 to 15, 90% at Y -64 to -59)\n'
                            '⚫ Coal Ore (Y 0 to 256, peaks at Y 96)\n'
                            'Enhanced UI with compact ore selection and visual legend',
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader('🎯 Perfect for All Players'),
                      const SizedBox(height: 12),
                      _buildFeatureList([
                        'Speedrunners: Quick access to essential ores with saved parameters',
                        'Builders: Iron for tools, redstone for mechanisms',
                        'Regular Players: Seamless continuation of mining sessions',
                        'New Players: Learn optimal mining levels with persistent settings',
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
                      'All your search parameters are now automatically saved!',
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
