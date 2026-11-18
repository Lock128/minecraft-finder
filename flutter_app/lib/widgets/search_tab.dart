import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/game_random.dart';
import '../models/ore_location.dart';
import '../providers/search_state.dart';
import '../theme/gamer_theme.dart';
import 'edition_version_card.dart';
import 'quick_start_card.dart';
import 'search_action_bar.dart';
import 'search_center_card.dart';
import 'search_history_widget.dart';
import 'what_to_find_card.dart';
import 'world_settings_card.dart';

/// The search form: seed, what to find, and a collapsed "Advanced options"
/// section (edition, version, search area). The Find button stays pinned at the
/// bottom.
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

  void _find(bool wholeWorld) {
    // Fields inside the collapsed Advanced section are still part of the form.
    // If one of them is invalid, open the section so the error is visible.
    final state = context.read<SearchState>();
    final valid = state.formKey.currentState?.validate() ?? true;
    if (!valid && !_advancedOpen) setState(() => _advancedOpen = true);
    widget.onFindOres(wholeWorld);
  }

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
              padding: const EdgeInsets.all(16),
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
                          const SizedBox(height: 12),
                        ],
                        WorldSettingsCard(
                          seedController: state.seedController,
                          isDarkMode: _isDark,
                        ),
                        SearchHistoryWidget(isDarkMode: _isDark),
                        const SizedBox(height: 12),
                        WhatToFindCard(isDarkMode: _isDark),
                        const SizedBox(height: 12),
                        _buildAdvanced(context, state),
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
          onFindOres: _find,
        ),
      ],
    );
  }

  Widget _buildAdvanced(BuildContext context, SearchState state) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );

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
              padding: const EdgeInsets.all(16),
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
          // Offstage keeps the fields (and their validators) alive while the
          // section is collapsed, so form validation still covers them.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Offstage(
              offstage: !_advancedOpen,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.editionVersionTitle, style: labelStyle),
                    const SizedBox(height: 8),
                    Consumer<SearchState>(
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
                    const SizedBox(height: 20),
                    Text(l10n.searchCenterTitle, style: labelStyle),
                    const SizedBox(height: 8),
                    Consumer<SearchState>(
                      builder: (context, s, _) => SearchCenterCard(
                        embedded: true,
                        xController: s.xController,
                        yController: s.yController,
                        zController: s.zController,
                        radiusController: s.radiusController,
                        isDarkMode: _isDark,
                        netheriteSelected:
                            s.includeOres &&
                            s.selectedOreTypes.contains(OreType.netherite),
                        wholeWorldNetherite: s.wholeWorldNetherite,
                        onWholeWorldChanged: widget.onWholeWorldChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One-line summary of the collapsed Advanced options, for example
/// `Java Edition · 1.18+ · 0, -59, 0 · r50`.
class _AdvancedSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.read<SearchState>();
    final meta = context.select<SearchState, _SummaryMeta>(
      (s) => (
        edition: s.selectedEdition,
        era: s.selectedVersionEra,
        version: s.selectedVersion?.release,
        wholeWorld:
            s.wholeWorldNetherite &&
            s.includeOres &&
            s.selectedOreTypes.contains(OreType.netherite),
      ),
    );
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return ListenableBuilder(
      listenable: Listenable.merge([
        state.xController,
        state.yController,
        state.zController,
        state.radiusController,
      ]),
      builder: (context, _) {
        final edition = meta.edition == MinecraftEdition.java
            ? l10n.editionJava
            : l10n.editionBedrock;
        final era =
            meta.version ??
            (meta.era == VersionEra.legacy
                ? l10n.versionEraLegacy
                : l10n.versionEraModern);
        final area = meta.wholeWorld
            ? l10n.wholeWorldNetheriteTitle
            : '${state.xController.text}, ${state.yController.text}, '
                  '${state.zController.text} · r${state.radiusController.text}';
        return Text(
          '$edition · $era · $area',
          style: style,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

typedef _SummaryMeta = ({
  MinecraftEdition edition,
  VersionEra era,
  String? version,
  bool wholeWorld,
});
