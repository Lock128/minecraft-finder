import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/gamer_theme.dart';
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
      setState(() => _recentSeeds = seeds);
    }
  }

  void refreshSeeds() => _loadRecentSeeds();

  void _selectSeed(String seed) {
    widget.seedController.text = seed;
    PreferencesService.saveLastSeed(seed);
  }

  @override
  Widget build(BuildContext context) {
    if (_recentSeeds.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final isDark = widget.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.history, size: 14,
              color: isDark ? Colors.white54 : Colors.grey[500]),
            const SizedBox(width: 4),
            Text(l10n.recentSeeds,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.grey[500],
              )),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _recentSeeds.map((seed) {
            return GestureDetector(
              onTap: () => _selectSeed(seed),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? GamerColors.neonGreen.withValues(alpha: 0.1)
                      : GamerColors.neonGreen.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: GamerColors.neonGreen.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  seed,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? GamerColors.neonGreen : GamerColors.lightGreen,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
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
