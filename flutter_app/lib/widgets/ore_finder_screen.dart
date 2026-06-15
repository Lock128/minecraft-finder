import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../providers/search_state.dart';
import '../theme/gamer_theme.dart';
import '../widgets/search_tab.dart';
import '../widgets/results_tab.dart';
import '../widgets/guide_tab.dart';
import '../widgets/release_notes_tab.dart';
import '../widgets/bedwars_guide_tab.dart';
import '../widgets/app_info_dialog.dart';
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
  late final TabController _tabController;
  late final SearchState _searchState;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchState = SearchState();
    _searchState.tabController = _tabController;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchState.dispose();
    super.dispose();
  }

  Future<void> _findOres(bool comprehensiveNetherite) async {
    final l10n = AppLocalizations.of(context);
    final errorMessage = await _searchState.findOres(
      comprehensiveNetherite,
      errorEnableSearchType: l10n.errorEnableSearchType,
      errorSelectStructure: l10n.errorSelectStructure,
      errorSelectOre: l10n.errorSelectOre,
      errorGeneric: (e) => l10n.errorGeneric(e),
    );

    if (errorMessage != null && mounted) {
      final isGenericError = errorMessage.contains(RegExp(r'Exception|Error'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: isGenericError ? Colors.red : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SearchState>.value(
      value: _searchState,
      child: Consumer<SearchState>(
        builder: (context, searchState, _) {
          final isDark = widget.isDarkMode;
          return Scaffold(
            appBar: _buildAppBar(isDark),
            body: Column(
              children: [
                _buildTabBar(isDark),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      SearchTab(
                        formKey: searchState.formKey,
                        seedController: searchState.seedController,
                        xController: searchState.xController,
                        yController: searchState.yController,
                        zController: searchState.zController,
                        radiusController: searchState.radiusController,
                        selectedOreTypes: searchState.selectedOreTypes,
                        includeNether: searchState.includeNether,
                        includeOres: searchState.includeOres,
                        includeStructures: searchState.includeStructures,
                        selectedStructures: searchState.selectedStructures,
                        isLoading: searchState.isLoading,
                        findAllNetherite: searchState.findAllNetherite,
                        isDarkMode: isDark,
                        selectedEdition: searchState.selectedEdition,
                        selectedVersionEra: searchState.selectedVersionEra,
                        onOreTypesChanged: searchState.setOreTypes,
                        onIncludeNetherChanged: searchState.setIncludeNether,
                        onIncludeOresChanged: searchState.setIncludeOres,
                        onIncludeStructuresChanged:
                            searchState.setIncludeStructures,
                        onStructuresChanged: searchState.setSelectedStructures,
                        onFindOres: _findOres,
                        onEditionChanged: searchState.setEdition,
                        onVersionEraChanged: searchState.setVersionEra,
                      ),
                      ResultsTab(
                        results: searchState.results,
                        structureResults: searchState.structureResults,
                        isLoading: searchState.isLoading,
                        findAllNetherite: searchState.findAllNetherite,
                        selectedOreTypes: searchState.selectedOreTypes,
                      ),
                      GuideTab(isDarkMode: isDark),
                      BedwarsGuideTab(isDarkMode: isDark),
                      ReleaseNotesTab(isDarkMode: isDark),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      color: isDark ? GamerColors.darkSurface : Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: GamerColors.neonGreen,
        indicatorWeight: 3,
        labelColor: isDark ? GamerColors.neonGreen : GamerColors.lightGreen,
        unselectedLabelColor: isDark ? Colors.white54 : Colors.grey[500],
        labelStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        unselectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
              icon: const Icon(Icons.search, size: 18),
              text: AppLocalizations.of(context).searchTab,
              height: 48),
          Tab(
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              text: AppLocalizations.of(context).resultsTab,
              height: 48),
          Tab(
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              text: AppLocalizations.of(context).guideTab,
              height: 48),
          Tab(
              icon: const Icon(Icons.sports_esports, size: 18),
              text: AppLocalizations.of(context).bedwarsTab,
              height: 48),
          Tab(
              icon: const Icon(Icons.update_outlined, size: 18),
              text: AppLocalizations.of(context).updatesTab,
              height: 48),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      toolbarHeight: 52,
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [GamerColors.neonGreen, GamerColors.neonCyan],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow:
                  isDark ? GamerColors.subtleGlow(GamerColors.neonGreen) : null,
            ),
            child: const Center(
              child: Text('\u26CF\uFE0F', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context).appTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: isDark ? GamerColors.darkSurface : Colors.white,
      foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A2E),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                GamerColors.neonGreen.withValues(alpha: 0.0),
                GamerColors.neonGreen.withValues(alpha: isDark ? 0.6 : 0.3),
                GamerColors.neonCyan.withValues(alpha: isDark ? 0.6 : 0.3),
                GamerColors.neonCyan.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () =>
              AppInfoDialog.show(context, isDarkMode: widget.isDarkMode),
          icon: Icon(Icons.info_outline,
              color: isDark ? Colors.white70 : Colors.grey[600], size: 20),
          tooltip: AppLocalizations.of(context).appInfoTooltip,
        ),
        PopupMenuButton<Locale>(
          icon: Icon(Icons.language,
              color: isDark ? Colors.white70 : Colors.grey[600], size: 20),
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
            widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: isDark ? GamerColors.neonYellow : Colors.grey[700],
            size: 20,
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
    final isDark = widget.isDarkMode;
    return PopupMenuItem<Locale>(
      value: locale,
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          if (isActive)
            Icon(Icons.check,
                size: 18,
                color:
                    isDark ? GamerColors.neonGreen : GamerColors.lightGreen),
        ],
      ),
    );
  }
}
