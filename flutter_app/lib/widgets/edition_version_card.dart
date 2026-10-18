import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../l10n/app_localizations.dart';
import '../models/game_random.dart';
import '../models/worldgen/engine_selector.dart';
import '../models/worldgen/minecraft_version.dart';
import '../theme/gamer_theme.dart';

class EditionVersionCard extends StatefulWidget {
  final MinecraftEdition selectedEdition;
  final VersionEra selectedVersionEra;
  final ValueChanged<MinecraftEdition> onEditionChanged;
  final ValueChanged<VersionEra> onVersionEraChanged;
  final bool isDarkMode;

  /// Seed-accurate version picker (Req 12.1). The list is sourced from the
  /// VersionAvailability/registry version list by the caller.
  final List<MinecraftVersion> availableVersions;

  /// The explicitly selected version, or null when none is chosen.
  final MinecraftVersion? selectedVersion;

  /// Called when the user picks a version (or clears it with null).
  final ValueChanged<MinecraftVersion?> onVersionChanged;

  /// The Accurate/Estimate search mode (Req 12.2).
  final SearchMode searchMode;

  /// Called when the user flips the Accurate/Estimate toggle.
  final ValueChanged<SearchMode> onSearchModeChanged;

  /// Whether the experimental "accurate on web" opt-in is enabled.
  final bool webExperimentalAccurate;

  /// Called when the user toggles the experimental "accurate on web" switch.
  final ValueChanged<bool> onWebExperimentalChanged;

  const EditionVersionCard({
    super.key,
    required this.selectedEdition,
    required this.selectedVersionEra,
    required this.onEditionChanged,
    required this.onVersionEraChanged,
    this.isDarkMode = false,
    this.availableVersions = const [],
    this.selectedVersion,
    this.onVersionChanged = _noopVersion,
    this.searchMode = SearchMode.accurate,
    this.onSearchModeChanged = _noopMode,
    this.webExperimentalAccurate = true,
    this.onWebExperimentalChanged = _noopBool,
  });

  static void _noopVersion(MinecraftVersion? _) {}
  static void _noopMode(SearchMode _) {}
  static void _noopBool(bool _) {}

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
  SearchMode get searchMode => widget.searchMode;
  List<MinecraftVersion> get availableVersions => widget.availableVersions;
  MinecraftVersion? get selectedVersion => widget.selectedVersion;

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
    final headerAccent =
        GamerColors.adaptiveAccent(GamerColors.neonOrange, isDarkMode);
    return GamerCard(
      isDarkMode: isDarkMode,
      accentColor: headerAccent,
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
                    accentColor: headerAccent,
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
                  color: isDarkMode ? Colors.white54 : const Color(0xFF616161),
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
            // Seed-accurate version picker (Req 12.1). Only shown when the
            // registry supplies versions for the selected edition.
            if (availableVersions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildVersionPicker(l10n),
            ],
            const SizedBox(height: 12),
            // Accurate/Estimate search mode toggle (Req 12.2).
            _buildModeToggle(l10n),
            const SizedBox(height: 12),
            _buildInfoBox(
              icon: Icons.new_releases_outlined,
              color: GamerColors.neonGreen,
              title: l10n.latestUpdateTitle,
              body: l10n.latestUpdateInfo,
            ),
            if (searchMode == SearchMode.accurate) ...[
              const SizedBox(height: 12),
              _buildInfoBox(
                icon: Icons.verified_outlined,
                color: GamerColors.neonGreen,
                body: l10n.searchModeAccurateInfo,
              ),
            ],
            // Experimental accurate-on-web opt-in. Only meaningful on the web
            // (native already runs the accurate path) and only relevant when
            // Accurate mode is selected.
            if (kIsWeb && searchMode == SearchMode.accurate) ...[
              const SizedBox(height: 12),
              _buildWebExperimentalToggle(l10n),
            ],
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

  /// Dropdown version picker populated from [availableVersions] (Req 12.1).
  Widget _buildVersionPicker(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.minecraftVersionLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: GamerColors.orangeText(isDarkMode),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: (isDarkMode ? Colors.white54 : Colors.grey).withValues(
                alpha: 0.5,
              ),
            ),
          ),
          child: DropdownButton<MinecraftVersion>(
            // Only use the current value when it is in the list, else null.
            value: availableVersions.contains(selectedVersion)
                ? selectedVersion
                : null,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            hint: Text(l10n.minecraftVersionLabel),
            items: [
              for (final version in availableVersions)
                DropdownMenuItem<MinecraftVersion>(
                  value: version,
                  child: Text(version.release),
                ),
            ],
            onChanged: widget.onVersionChanged,
          ),
        ),
      ],
    );
  }

  /// Accurate/Estimate mode toggle (Req 12.2).
  Widget _buildModeToggle(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.searchModeTitle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: GamerColors.orangeText(isDarkMode),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<SearchMode>(
            segments: [
              ButtonSegment(
                value: SearchMode.estimate,
                label: Text(l10n.searchModeEstimate),
              ),
              ButtonSegment(
                value: SearchMode.accurate,
                label: Text(l10n.searchModeAccurate),
              ),
            ],
            selected: {searchMode},
            onSelectionChanged: (selected) {
              widget.onSearchModeChanged(selected.first);
            },
          ),
        ),
      ],
    );
  }

  /// Experimental "accurate on web" opt-in: a labelled switch plus an
  /// explanation of the experimental/unverified caveat.
  Widget _buildWebExperimentalToggle(AppLocalizations l10n) {
    final color = GamerColors.neonOrange;
    final textColor = GamerColors.adaptiveAccent(color, isDarkMode);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: isDarkMode ? 0.10 : 0.06),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 16, color: textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.webExperimentalToggle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              Switch(
                value: widget.webExperimentalAccurate,
                activeThumbColor: GamerColors.neonGreen,
                onChanged: widget.onWebExperimentalChanged,
              ),
            ],
          ),
          Text(
            l10n.webExperimentalInfo,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.8),
            ),
          ),
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
    final textColor = GamerColors.adaptiveAccent(color, isDarkMode);
    final bodyStyle = TextStyle(
      color: textColor.withValues(alpha: 0.8),
      height: 1.4,
      fontSize: 11,
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: isDarkMode ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
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

}
