import 'package:flutter/material.dart';

class AppInfoDialog extends StatelessWidget {
  final bool isDarkMode;

  const AppInfoDialog({super.key, this.isDarkMode = false});

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
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B4513),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Center(
                      child: Text('⛏️', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'About Gem, Ore & Struct Finder',
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
                      _buildSectionHeader('🎯 What This App Does'),
                      const SizedBox(height: 12),
                      _buildDescriptionCard(
                        'Advanced Minecraft Ore & Structure Discovery',
                        'This app uses sophisticated world seed analysis to help you find valuable '
                            'resources and structures in your Minecraft worlds. Simply enter your world seed '
                            'and search coordinates to discover the exact locations of diamonds, gold, '
                            'netherite, villages, strongholds, and much more.',
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader('⛏️ Supported Resources'),
                      const SizedBox(height: 12),
                      _buildResourceGrid(),
                      const SizedBox(height: 20),
                      _buildSectionHeader('🏘️ Supported Structures'),
                      const SizedBox(height: 12),
                      _buildStructureList(),
                      const SizedBox(height: 20),
                      _buildSectionHeader('🔍 How It Works'),
                      const SizedBox(height: 12),
                      _buildStepsList(),
                      const SizedBox(height: 20),
                      _buildSectionHeader('✨ Key Features'),
                      const SizedBox(height: 12),
                      _buildFeaturesList(),
                      const SizedBox(height: 20),
                      _buildSectionHeader('🎮 Perfect For'),
                      const SizedBox(height: 12),
                      _buildPlayerTypesList(),
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
                  const Icon(Icons.lightbulb_outline,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tip: Use the Recent Seeds feature to quickly switch between your favorite worlds!',
                      style: TextStyle(
                        color: Colors.orange,
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

  Widget _buildDescriptionCard(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E3A1E) : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceGrid() {
    final resources = [
      {'name': 'Diamond', 'emoji': '💎', 'levels': 'Y -64 to 16'},
      {'name': 'Gold', 'emoji': '🟡', 'levels': 'Y -64 to 32'},
      {'name': 'Netherite', 'emoji': '🔴', 'levels': 'Y 8 to 22'},
      {'name': 'Iron', 'emoji': '⚪', 'levels': 'Y -64 to 256'},
      {'name': 'Redstone', 'emoji': '🔴', 'levels': 'Y -64 to 15'},
      {'name': 'Coal', 'emoji': '⚫', 'levels': 'Y 0 to 256'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: resources
          .map((resource) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isDarkMode ? const Color(0xFF2E2E2E) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  children: [
                    Text(resource['emoji']!,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      resource['name']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      resource['levels']!,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildStructureList() {
    final structures = [
      'Villages 🏘️',
      'Strongholds 🏰',
      'Dungeons 🕳️',
      'Mineshafts ⛏️',
      'Desert Temples 🏜️',
      'Jungle Temples 🌿',
      'Ocean Monuments 🌊',
      'Woodland Mansions 🏚️',
      'Pillager Outposts ⚔️',
      'Ruined Portals 🌀'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: structures
          .map((structure) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF2E2E2E) : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.blue[400]! : Colors.blue[200]!,
                  ),
                ),
                child: Text(
                  structure,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildStepsList() {
    final steps = [
      '1. Enter your world seed in the Search tab',
      '2. Set your search center coordinates (X, Y, Z)',
      '3. Choose your search radius',
      '4. Select which ores and structures to find',
      '5. Tap "Find Ores" to discover nearby resources',
      '6. View results with exact coordinates and probabilities'
    ];

    return Column(
      children: steps
          .map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color:
                            isDarkMode ? const Color(0xFF4CAF50) : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          step.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step.substring(3),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? Colors.white : Colors.black,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      'Recent Seeds History - Quick access to your last 5 seeds',
      'Automatic Parameter Saving - Never lose your search settings',
      'Probability-Based Results - Find the most likely ore locations',
      'Cross-Platform Support - Works on web, mobile, and desktop',
      'Offline Functionality - Works without internet after initial load',
      'Dark/Light Theme - Choose your preferred appearance'
    ];

    return Column(
      children: features
          .map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✅ ',
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

  Widget _buildPlayerTypesList() {
    final playerTypes = [
      'Speedrunners - Find essential resources quickly',
      'Builders - Locate materials for large projects',
      'Content Creators - Showcase interesting world seeds',
      'Casual Players - Discover hidden treasures in your world',
      'New Players - Learn optimal mining strategies'
    ];

    return Column(
      children: playerTypes
          .map((type) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎮 ',
                        style: TextStyle(
                            color: isDarkMode
                                ? const Color(0xFF66BB6A)
                                : const Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        type,
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
      builder: (context) => AppInfoDialog(isDarkMode: isDarkMode),
    );
  }
}
