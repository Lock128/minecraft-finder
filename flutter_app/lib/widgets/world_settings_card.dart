import 'package:flutter/material.dart';
import 'recent_seeds_widget.dart';

class WorldSettingsCard extends StatefulWidget {
  final TextEditingController seedController;
  final bool isDarkMode;
  final VoidCallback? onSeedSearched;

  const WorldSettingsCard({
    super.key,
    required this.seedController,
    required this.isDarkMode,
    this.onSeedSearched,
  });

  @override
  State<WorldSettingsCard> createState() => _WorldSettingsCardState();
}

class _WorldSettingsCardState extends State<WorldSettingsCard> {
  final GlobalKey<State<RecentSeedsWidget>> _recentSeedsKey = GlobalKey();

  void refreshRecentSeeds() {
    (_recentSeedsKey.currentState as dynamic)?.refreshSeeds();
  }

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
            colors: widget.isDarkMode
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
                    child: Text('🌍', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'World Settings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.seedController,
              decoration: InputDecoration(
                labelText: 'World Seed',
                hintText: 'Enter your world seed',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: const Color(0xFF4CAF50)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: const Color(0xFF2E7D32), width: 2),
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Center(
                    child: Text('🌱', style: TextStyle(fontSize: 12)),
                  ),
                ),
                filled: true,
                fillColor:
                    widget.isDarkMode ? const Color(0xFF2E2E2E) : Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a world seed';
                }
                return null;
              },
            ),
            RecentSeedsWidget(
              key: _recentSeedsKey,
              seedController: widget.seedController,
              isDarkMode: widget.isDarkMode,
            ),
          ],
        ),
      ),
    );
  }
}
