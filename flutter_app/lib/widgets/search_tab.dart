import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/game_random.dart';
import '../models/ore_location.dart';
import '../models/worldgen/engine_selector.dart';
import '../providers/search_state.dart';
import '../theme/gamer_theme.dart';
import 'edition_version_card.dart';
import 'quick_start_card.dart';
import 'search_action_bar.dart';
import 'search_center_card.dart';
import 'search_history_widget.dart';
import 'what_to_find_card.dart';
import 'world_settings_card.dart';

/// The search form: seed, what to find, search center, and a collapsed
/// "Advanced options" section (edition, version, search mode). The Find button
/// stays pinned at the bottom.
///
/// All form state lives in [SearchState]. Each section reads only the values it
/// shows, so typing in one field or toggling a chip does not rebuild the rest.
class SearchTab extends StatefulWidget {
  final bool isDarkMode;

  /// Runs a search. The argument is true for the whole-world Netherite scan.
  final ValueChanged<bool> onFindOres;

  /// Toggles the whole-world Netherite scope. The parent applies Pro gating.
  final ValueChanged<bool> onWholeWorldChanged;

  const SearchTab({
    super.key,
    required this.isDarkMode,
    required this.onFindOres,
    required this.onWholeWorldChanged,
  });

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  bool _advancedOpen = false;

  bool get _isDark => widget.isDarkMode;

  @override
  Widget build(BuildContext context) {
    final state = context.read<SearchState>();
    final quickStartHidden = context.select<SearchState, bool>(
      (s) => s.quickStartHidden,
    );
    final isLoading = context.select<SearchState, bool>((s) => s.isLoading);
    final wholeWorldActive = context.select<SearchState, bool>(
      (s) =>
          s.wholeWorldNetherite &&
          s.includeOres &&
          s.selectedOreTypes.contains(OreType.netherite),
    );

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            // Tap anywhere outside a text field to dismiss the keyboard.
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Form(
                    key: state.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!quickStartHidden) ...[
                          QuickStartCard(
                            xController: state.xController,
                            yController: state.yController,
                            zController: state.zController,
                            radiusController: state.radiusController,
                            onIncludeOresChanged: state.setIncludeOres,
                            onOreTypesChanged: state.setOreTypes,
                            onDismiss: state.hideQuickStart,
                            isDarkMode: _isDark,
                          ),
                          const SizedBox(height: 10),
                        ],
                        WorldSettingsCard(
                          seedController: state.seedController,
                          isDarkMode: _isDark,
                        ),
                        SearchHistoryWidget(isDarkMode: _isDark),
                        const SizedBox(height: 10),
                        WhatToFindCard(isDarkMode: _isDark),
                        const SizedBox(height: 10),
                        _buildSearchCenter(),
                        const SizedBox(height: 10),
                        _buildAdvanced(context),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SearchActionBar(
          isLoading: isLoading,
          wholeWorldActive: wholeWorldActive,
          onFindOres: widget.onFindOres,
        ),
      ],
    );
  }

  /// Search center: coordinates, radius and the whole-world Netherite scope.
  /// Always visible because nearly every search depends on it.
  Widget _buildSearchCenter() {
    final state = context.read<SearchState>();
    final netheriteSelected = context.select<SearchState, bool>(
      (s) => s.includeOres && s.selectedOreTypes.contains(OreType.netherite),
    );
    final wholeWorld = context.select<SearchState, bool>(
      (s) => s.wholeWorldNetherite,
    );
    return SearchCenterCard(
      xController: state.xController,
      yController: state.yController,
      zController: state.zController,
      radiusController: state.radiusController,
      isDarkMode: _isDark,
      netheriteSelected: netheriteSelected,
      wholeWorldNetherite: wholeWorld,
      onWholeWorldChanged: widget.onWholeWorldChanged,
    );
  }

  Widget _buildAdvanced(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return GamerCard(
      isDarkMode: _isDark,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _advancedOpen = !_advancedOpen),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.tune, size: 20, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.advancedOptionsTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (!_advancedOpen) ...[
                          const SizedBox(height: 2),
                          _AdvancedSummary(),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _advancedOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _advancedOpen
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Consumer<SearchState>(
                      builder: (context, s, _) => EditionVersionCard(
                        embedded: true,
                        isDarkMode: _isDark,
                        selectedEdition: s.selectedEdition,
                        selectedVersionEra: s.selectedVersionEra,
                        onEditionChanged: s.setEdition,
                        onVersionEraChanged: s.setVersionEra,
                        availableVersions: s.availableVersions,
                        selectedVersion: s.selectedVersion,
                        onVersionChanged: s.setSelectedVersion,
                        searchMode: s.searchMode,
                        onSearchModeChanged: s.setSearchMode,
                        webExperimentalAccurate: s.webExperimentalAccurate,
                        onWebExperimentalChanged: s.setWebExperimentalAccurate,
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// One-line summary of the collapsed Advanced options, for example
/// `Java Edition · 1.18+ (Modern) · Accurate`.
class _AdvancedSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meta = context.select<SearchState, _SummaryMeta>(
      (s) => (
        edition: s.selectedEdition,
        era: s.selectedVersionEra,
        version: s.selectedVersion?.release,
        mode: s.searchMode,
      ),
    );
    final edition = meta.edition == MinecraftEdition.java
        ? l10n.editionJava
        : l10n.editionBedrock;
    final era =
        meta.version ??
        (meta.era == VersionEra.legacy
            ? l10n.versionEraLegacy
            : l10n.versionEraModern);
    final mode = meta.mode == SearchMode.accurate
        ? l10n.searchModeAccurate
        : l10n.searchModeEstimate;
    return Text(
      '$edition · $era · $mode',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

typedef _SummaryMeta = ({
  MinecraftEdition edition,
  VersionEra era,
  String? version,
  SearchMode mode,
});
