import 'package:flutter/material.dart';
import '../models/game_random.dart';
import '../theme/gamer_theme.dart';

class EditionVersionCard extends StatelessWidget {
  final MinecraftEdition selectedEdition;
  final VersionEra selectedVersionEra;
  final ValueChanged<MinecraftEdition> onEditionChanged;
  final ValueChanged<VersionEra> onVersionEraChanged;
  final bool isDarkMode;

  const EditionVersionCard({
    super.key,
    required this.selectedEdition,
    required this.selectedVersionEra,
    required this.onEditionChanged,
    required this.onVersionEraChanged,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return GamerCard(
      isDarkMode: isDarkMode,
      accentColor: GamerColors.neonOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GamerSectionHeader(
            emoji: '🎮',
            title: 'Edition & Version',
            isDarkMode: isDarkMode,
            accentColor: GamerColors.neonOrange,
          ),
          const SizedBox(height: 16),
          // Edition selector
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<MinecraftEdition>(
              segments: const [
                ButtonSegment(
                  value: MinecraftEdition.java,
                  label: Text('Java Edition'),
                ),
                ButtonSegment(
                  value: MinecraftEdition.bedrock,
                  label: Text('Bedrock Edition'),
                ),
              ],
              selected: {selectedEdition},
              onSelectionChanged: (selected) {
                onEditionChanged(selected.first);
              },
            ),
          ),
          const SizedBox(height: 12),
          // Version era selector
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<VersionEra>(
              segments: const [
                ButtonSegment(
                  value: VersionEra.legacy,
                  label: Text('Pre-1.18 (Legacy)'),
                ),
                ButtonSegment(
                  value: VersionEra.modern,
                  label: Text('1.18+ (Modern)'),
                ),
              ],
              selected: {selectedVersionEra},
              onSelectionChanged: (selected) {
                onVersionEraChanged(selected.first);
              },
            ),
          ),
          // Conditional info boxes
          if (selectedEdition == MinecraftEdition.bedrock) ...[
            const SizedBox(height: 12),
            _buildInfoBox(
              icon: Icons.info_outline,
              color: GamerColors.neonOrange,
              body:
                  'Bedrock ore prediction accuracy is approximate due to incomplete documentation of Bedrock\'s RNG internals.',
            ),
          ],
          if (selectedVersionEra == VersionEra.legacy) ...[
            const SizedBox(height: 12),
            _buildInfoBox(
              icon: Icons.info_outline,
              color: GamerColors.neonOrange,
              body:
                  'Legacy ore placement uses uniform distribution with classic Y-level sweet spots (e.g., Y=12 for diamonds).',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required Color color,
    required String body,
  }) {
    final textColor = isDarkMode ? color : _lightVariant(color);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDarkMode ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              body,
              style: TextStyle(
                color: isDarkMode
                    ? color.withValues(alpha: 0.8)
                    : textColor.withValues(alpha: 0.8),
                height: 1.4,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _lightVariant(Color c) {
    if (c == GamerColors.neonOrange) return GamerColors.lightOrange;
    if (c == GamerColors.neonPurple) return GamerColors.lightPurple;
    if (c == GamerColors.neonGreen) return GamerColors.lightGreen;
    if (c == GamerColors.neonCyan) return GamerColors.lightCyan;
    return c;
  }
}
