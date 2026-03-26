import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/gamer_theme.dart';
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
    final l10n = AppLocalizations.of(context);
    final isDark = widget.isDarkMode;
    return GamerCard(
      isDarkMode: isDark,
      accentColor: GamerColors.neonGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GamerSectionHeader(
            emoji: '🌍',
            title: l10n.worldSettingsTitle,
            isDarkMode: isDark,
            accentColor: GamerColors.neonGreen,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.seedController,
            decoration: InputDecoration(
              labelText: l10n.worldSeedLabel,
              hintText: l10n.worldSeedHint,
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('🌱', style: TextStyle(fontSize: 16)),
              ),
              filled: true,
              fillColor: isDark ? GamerColors.darkSurface : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: GamerColors.neonGreen, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.errorEmptySeed;
              }
              return null;
            },
          ),
          RecentSeedsWidget(
            key: _recentSeedsKey,
            seedController: widget.seedController,
            isDarkMode: isDark,
          ),
        ],
      ),
    );
  }
}
