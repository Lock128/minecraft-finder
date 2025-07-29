import 'package:flutter/material.dart';
import '../utils/preferences_service.dart';

class RecentSeedsWidget extends StatefulWidget {
  final TextEditingController seedController;
  final bool isDarkMode;

  const RecentSeedsWidget({
    super.key,
    required this.seedController,
    required this.isDarkMode,
  });

  @override
  State<RecentSeedsWidget> createState() => _RecentSeedsWidgetState();
}

class _RecentSeedsWidgetState extends State<RecentSeedsWidget> {
  List<String> _recentSeeds = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSeeds();
  }

  Future<void> _loadRecentSeeds() async {
    final seeds = await PreferencesService.getRecentSeeds();
    if (mounted) {
      setState(() {
        _recentSeeds = seeds;
      });
    }
  }

  void refreshSeeds() {
    _loadRecentSeeds();
  }

  void _selectSeed(String seed) {
    widget.seedController.text = seed;
    // Trigger the listener to save the seed
    PreferencesService.saveLastSeed(seed);
  }

  @override
  Widget build(BuildContext context) {
    if (_recentSeeds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.history,
              size: 16,
              color: widget.isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              'Recent Seeds',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: widget.isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _recentSeeds.map((seed) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Tooltip(
                message: 'Click to use seed: $seed',
                child: GestureDetector(
                  onTap: () => _selectSeed(seed),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                          : const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      seed,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode
                            ? const Color(0xFF81C784)
                            : const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500,
                        fontFamily:
                            'monospace', // Use monospace for better number readability
                      ),
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
