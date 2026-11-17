import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/search_history_entry.dart';
import '../providers/monetization_config.dart';
import '../providers/pro_status_provider.dart';
import '../providers/search_history_provider.dart';
import '../providers/search_state.dart';
import '../widgets/search_tab.dart';
import '../widgets/results_tab.dart';
import '../widgets/favorites_tab.dart';
import '../widgets/guide_hub_tab.dart';
import '../widgets/app_info_dialog.dart';
import '../widgets/pro_upgrade_dialog.dart';
import 'package:provider/provider.dart';

class OreFinderScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  final ValueChanged<Locale> onLocaleChanged;
  final Locale? currentLocale;

  const OreFinderScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
    required this.onLocaleChanged,
    required this.currentLocale,
  });

  @override
  State<OreFinderScreen> createState() => _OreFinderScreenState();
}

class _OreFinderScreenState extends State<OreFinderScreen>
    with TickerProviderStateMixin {
  /// Width from which Search and Results are shown side by side.
  static const double _wideBreakpoint = 900;

  late final TabController _tabController;
  final ValueNotifier<int> _index = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    // 0 Search, 1 Results, 2 Favorites, 3 Guide (incl. Bedwars).
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_syncIndex);
  }

  void _syncIndex() => _index.value = _tabController.index;

  @override
  void dispose() {
    _tabController.removeListener(_syncIndex);
    _index.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _findOres(
    bool comprehensiveNetherite,
    BuildContext providerContext,
  ) async {
    final searchState = providerContext.read<SearchState>();
    final proStatus = providerContext.read<ProStatusProvider>();
    final l10n = AppLocalizations.of(providerContext);

    // Capture the history provider before any async gap
    SearchHistoryProvider? historyProvider;
    try {
      historyProvider = providerContext.read<SearchHistoryProvider>();
    } catch (_) {
      // SearchHistoryProvider may not be in tree during tests
    }

    final errorMessage = await searchState.findOres(
      comprehensiveNetherite,
      errorEnableSearchType: l10n.errorEnableSearchType,
      errorSelectStructure: l10n.errorSelectStructure,
      errorSelectOre: l10n.errorSelectOre,
      errorGeneric: (e) => l10n.errorGeneric(e),
      isPro: proStatus.isPro,
    );

    if (!mounted) return;

    if (errorMessage != null) {
      final isGenericError = errorMessage.contains(RegExp(r'Exception|Error'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: isGenericError ? Colors.red : Colors.orange,
        ),
      );
    } else {
      // Tell free users when their requested radius was clamped, instead of
      // silently shrinking the search.
      if (searchState.lastRadiusWasCapped) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.freeRadiusCappedNotice(SearchState.freeRadiusCap),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    // The onboarding card has done its job once a search has succeeded. It can
    // be shown again from the app info dialog.
    if (errorMessage == null && !searchState.quickStartHidden) {
      searchState.hideQuickStart();
    }
    if (errorMessage == null && historyProvider != null) {
      // Record successful search in history
      historyProvider.addEntry(
        SearchHistoryEntry(
          seed: searchState.seedController.text,
          centerX: int.tryParse(searchState.xController.text) ?? 0,
          centerY: int.tryParse(searchState.yController.text) ?? -59,
          centerZ: int.tryParse(searchState.zController.text) ?? 0,
          radius: int.tryParse(searchState.radiusController.text) ?? 50,
          oreTypes: Set.from(searchState.selectedOreTypes),
          structures: Set.from(searchState.selectedStructures),
          edition: searchState.selectedEdition,
          versionEra: searchState.selectedVersionEra,
          timestamp: DateTime.now(),
          resultCount:
              searchState.results.length + searchState.structureResults.length,
          includeOres: searchState.includeOres,
          includeStructures: searchState.includeStructures,
        ),
      );
    }
  }

  /// Handles toggling the whole-world Netherite scope. This is a Pro feature:
  /// free users get the upgrade dialog instead of enabling it.
  void _onWholeWorldChanged(bool value, BuildContext providerContext) {
    final searchState = providerContext.read<SearchState>();
    if (!value) {
      searchState.setWholeWorldNetherite(false);
      return;
    }
    final isPro =
        !providerContext.read<MonetizationConfig>().isEnabled ||
        providerContext.read<ProStatusProvider>().isPro;
    if (isPro) {
      searchState.setWholeWorldNetherite(true);
    } else {
      ProUpgradeDialog.show(providerContext, isDarkMode: widget.isDarkMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SearchState>(
      create: (_) {
        final state = SearchState();
        state.tabController = _tabController;
        return state;
      },
      child: Builder(
        builder: (context) {
          final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
          return ValueListenableBuilder<int>(
            valueListenable: _index,
            builder: (context, index, _) => Scaffold(
              appBar: _buildAppBar(widget.isDarkMode),
              body: wide
                  ? Row(
                      children: [
                        _buildRail(context, index),
                        const VerticalDivider(width: 1),
                        Expanded(child: _buildWideBody(context, index)),
                      ],
                    )
                  : TabBarView(
                      controller: _tabController,
                      // Swiping would fight the results map and lists.
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _KeepAlive(child: _buildSearchTab(context)),
                        _KeepAlive(child: _ResultsPane()),
                        _KeepAlive(
                          child: FavoritesTab(isDarkMode: widget.isDarkMode),
                        ),
                        _KeepAlive(
                          child: GuideHubTab(isDarkMode: widget.isDarkMode),
                        ),
                      ],
                    ),
              bottomNavigationBar: wide
                  ? null
                  : _buildNavigationBar(context, index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchTab(BuildContext context) {
    return SearchTab(
      isDarkMode: widget.isDarkMode,
      onFindOres: (b) => _findOres(b, context),
      onWholeWorldChanged: (v) => _onWholeWorldChanged(v, context),
    );
  }

  void _select(int index) {
    if (_tabController.index != index) _tabController.index = index;
  }

  NavigationBar _buildNavigationBar(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context);
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: _select,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.search),
          label: l10n.searchTab,
        ),
        NavigationDestination(
          icon: const _ResultsIcon(selected: false),
          selectedIcon: const _ResultsIcon(selected: true),
          label: l10n.resultsTab,
        ),
        NavigationDestination(
          icon: const Icon(Icons.bookmark_outline),
          selectedIcon: const Icon(Icons.bookmark),
          label: l10n.favoritesTab,
        ),
        NavigationDestination(
          icon: const Icon(Icons.menu_book_outlined),
          selectedIcon: const Icon(Icons.menu_book),
          label: l10n.guideTab,
        ),
      ],
    );
  }

  /// On wide screens Search and Results share one two-pane destination, so the
  /// rail has three items: Search (tab 0 and 1), Favorites (2) and Guide (3).
  Widget _buildRail(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context);
    const tabForRail = [0, 2, 3];
    final railIndex = index <= 1 ? 0 : index - 1;
    return NavigationRail(
      selectedIndex: railIndex,
      onDestinationSelected: (i) => _select(tabForRail[i]),
      destinations: [
        NavigationRailDestination(
          icon: const _ResultsIcon(selected: false, searchIcon: true),
          selectedIcon: const _ResultsIcon(selected: true, searchIcon: true),
          label: Text(l10n.searchTab),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.bookmark_outline),
          selectedIcon: const Icon(Icons.bookmark),
          label: Text(l10n.favoritesTab),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.menu_book_outlined),
          selectedIcon: const Icon(Icons.menu_book),
          label: Text(l10n.guideTab),
        ),
      ],
    );
  }

  Widget _buildWideBody(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    return IndexedStack(
      index: index <= 1 ? 0 : index - 1,
      children: [
        Row(
          children: [
            SizedBox(width: 440, child: _buildSearchTab(context)),
            VerticalDivider(width: 1, color: scheme.outlineVariant),
            Expanded(child: _ResultsPane()),
          ],
        ),
        FavoritesTab(isDarkMode: widget.isDarkMode),
        GuideHubTab(isDarkMode: widget.isDarkMode),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      toolbarHeight: 56,
      titleSpacing: 16,
      title: Row(
        children: [
          Icon(Icons.diamond_outlined, color: scheme.primary, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context).appTitle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: scheme.outlineVariant),
      ),
      actions: [
        if (context.watch<MonetizationConfig>().isEnabled)
          Consumer<ProStatusProvider>(
            builder: (context, pro, _) {
              if (pro.isPro) return const SizedBox.shrink();
              return IconButton(
                onPressed: () =>
                    ProUpgradeDialog.show(context, isDarkMode: isDark),
                icon: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PRO',
                    style: TextStyle(
                      color: scheme.onTertiaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                tooltip: 'Upgrade to Pro',
              );
            },
          ),
        Builder(
          builder: (iconContext) => IconButton(
            onPressed: () {
              final searchState = iconContext.read<SearchState>();
              AppInfoDialog.show(
                iconContext,
                isDarkMode: widget.isDarkMode,
                quickStartHidden: searchState.quickStartHidden,
                onShowQuickStart: searchState.showQuickStart,
              );
            },
            icon: const Icon(Icons.info_outline),
            tooltip: AppLocalizations.of(iconContext).appInfoTooltip,
          ),
        ),
        PopupMenuButton<Locale>(
          icon: const Icon(Icons.language),
          tooltip: AppLocalizations.of(context).languageTooltip,
          onSelected: (locale) => widget.onLocaleChanged(locale),
          itemBuilder: (context) => [
            _buildLanguageItem(const Locale('en'), 'English'),
            _buildLanguageItem(const Locale('de'), 'Deutsch'),
            _buildLanguageItem(const Locale('es'), 'Espa\u00F1ol'),
            _buildLanguageItem(const Locale('ja'), '\u65E5\u672C\u8A9E'),
            _buildLanguageItem(const Locale('fr'), 'Fran\u00E7ais'),
          ],
        ),
        IconButton(
          onPressed: widget.onThemeToggle,
          icon: Icon(
            widget.isDarkMode
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
          tooltip: widget.isDarkMode
              ? AppLocalizations.of(context).lightThemeTooltip
              : AppLocalizations.of(context).darkThemeTooltip,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  PopupMenuItem<Locale> _buildLanguageItem(Locale locale, String name) {
    final isActive = widget.currentLocale?.languageCode == locale.languageCode;
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuItem<Locale>(
      value: locale,
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isActive) Icon(Icons.check, size: 18, color: scheme.primary),
        ],
      ),
    );
  }
}

/// Results list wired to [SearchState]. Only this subtree rebuilds while a
/// search streams in results.
class _ResultsPane extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SearchState>(
      builder: (context, s, _) => ResultsTab(
        results: s.results,
        structureResults: s.structureResults,
        isLoading: s.isLoading,
        findAllNetherite: s.findAllNetherite,
        selectedOreTypes: s.selectedOreTypes,
        totalFound: s.totalFound,
        searchMeta: s.lastSearchMeta,
      ),
    );
  }
}

/// Navigation icon with a badge showing how many results the last search found.
class _ResultsIcon extends StatelessWidget {
  final bool selected;

  /// Use the search icon instead of the results icon (wide layout, where one
  /// rail item covers both).
  final bool searchIcon;

  const _ResultsIcon({required this.selected, this.searchIcon = false});

  @override
  Widget build(BuildContext context) {
    final count = context.select<SearchState, int>(
      (s) => s.results.length + s.structureResults.length,
    );
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 999 ? '999+' : '$count'),
      child: Icon(
        searchIcon
            ? Icons.search
            : (selected ? Icons.inventory_2 : Icons.inventory_2_outlined),
      ),
    );
  }
}

/// Keeps a tab's state (scroll position, expanded sections) alive while
/// another tab is showing.
class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
