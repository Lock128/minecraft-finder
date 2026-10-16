import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/game_random.dart';
import '../theme/gamer_theme.dart';

class EditionVersionCard extends StatefulWidget {
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
  State<EditionVersionCard> createState() => _EditionVersionCardState();
}

class _EditionVersionCardState extends State<EditionVersionCard> {
  // The whole card is collapsed by default — most users never change edition
  // or version era, so we show a compact one-line summary and only reveal the
  // selectors (and caveats) when the user taps to expand.
  bool _expanded = false;

  bool get isDarkMode => widget.isDarkMode;
  MinecraftEdition get selectedEdition => widget.selectedEdition;
  VersionEra get selectedVersionEra => widget.selectedVersionEra;

  String _editionLabel(AppLocalizations l10n) =>
      selectedEdition == MinecraftEdition.java
          ? l10n.editionJava
          : l10n.editionBedrock;

  String _versionLabel(AppLocalizations l10n) =>
      selectedVersionEra == VersionEra.legacy
          ? l10n.versionEraLegacy
          : l10n.versionEraModern;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GamerCard(
      isDarkMode: isDarkMode,
      accentColor: GamerColors.neonOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact, tappable summary header: "🎮 Edition & Version  Java · 1.18+ ⌄"
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  child: GamerSectionHeader(
                    emoji: '🎮',
                    title: l10n.editionVersionTitle,
                    isDarkMode: isDarkMode,
                    accentColor: GamerColors.neonOrange,
                  ),
                ),
                if (!_expanded)
                  Flexible(
                    child: Text(
                      '${_editionLabel(l10n)} · ${_versionLabel(l10n)}',
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: GamerColors.orangeText(isDarkMode),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: isDarkMode ? Colors.white54 : Colors.grey[600],
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 16),
            // Edition selector
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<MinecraftEdition>(
                segments: [
                  ButtonSegment(
                    value: MinecraftEdition.java,
                    label: Text(l10n.editionJava),
                  ),
                  ButtonSegment(
                    value: MinecraftEdition.bedrock,
                    label: Text(l10n.editionBedrock),
                  ),
                ],
                selected: {selectedEdition},
                onSelectionChanged: (selected) {
                  widget.onEditionChanged(selected.first);
                },
              ),
            ),
            const SizedBox(height: 12),
            // Version era selector
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<VersionEra>(
                segments: [
                  ButtonSegment(
                    value: VersionEra.legacy,
                    label: Text(l10n.versionEraLegacy),
                  ),
                  ButtonSegment(
                    value: VersionEra.modern,
                    label: Text(l10n.versionEraModern),
                  ),
                ],
                selected: {selectedVersionEra},
                onSelectionChanged: (selected) {
                  widget.onVersionEraChanged(selected.first);
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoBox(
              icon: Icons.new_releases_outlined,
              color: GamerColors.neonGreen,
              title: l10n.latestUpdateTitle,
              body: l10n.latestUpdateInfo,
            ),
            if (selectedEdition == MinecraftEdition.bedrock) ...[
              const SizedBox(height: 12),
              _buildInfoBox(
                icon: Icons.info_outline,
                color: GamerColors.neonOrange,
                body: l10n.editionBedrockInfo,
              ),
            ],
            if (selectedVersionEra == VersionEra.legacy) ...[
              const SizedBox(height: 12),
              _buildInfoBox(
                icon: Icons.info_outline,
                color: GamerColors.neonOrange,
                body: l10n.versionLegacyInfo,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required Color color,
    required String body,
    String? title,
  }) {
    final textColor = isDarkMode ? color : _lightVariant(color);
    final bodyStyle = TextStyle(
      color: isDarkMode
          ? color.withValues(alpha: 0.8)
          : textColor.withValues(alpha: 0.8),
      height: 1.4,
      fontSize: 11,
    );
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      height: 1.4,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  body,
                  style: bodyStyle,
                ),
              ],
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
