import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

import 'models/ore_finder.dart';
import 'models/ore_location.dart';
import 'models/structure_finder.dart';
import 'models/structure_location.dart';
import 'models/search_result.dart';
import 'theme/gamer_theme.dart';
import 'widgets/search_tab.dart';
import 'widgets/results_tab.dart';
import 'widgets/guide_tab.dart';
import 'widgets/release_notes_tab.dart';
import 'widgets/bedwars_guide_tab.dart';

import 'widgets/app_info_dialog.dart';
import 'utils/preferences_service.dart';

void main() {
  runApp(const GemOreStructFinderApp());
}

class GemOreStructFinderApp extends StatefulWidget {
  const GemOreStructFinderApp({super.key});

  @override
  State<GemOreStructFinderApp> createState() => _GemOreStructFinderAppState();
}

class _GemOreStructFinderAppState extends State<GemOreStructFinderApp> {
  bool _isDarkMode = false;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final localeCode = await PreferencesService.getLocale();
    if (localeCode != null && localeCode.isNotEmpty) {
      setState(() {
        _locale = Locale(localeCode);
      });
    }
  }

  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    PreferencesService.saveLocale(locale.languageCode);
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gem, Ore & Struct Finder for MC - Find Diamonds, Gold, Netherite & More',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: GamerTheme.buildLight(),
      darkTheme: GamerTheme.buildDark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      home: OreFinderScreen(
        onThemeToggle: _toggleTheme,
        isDarkMode: _isDarkMode,
        onLocaleChanged: _setLocale,
        currentLocale: _locale,
      ),
    );
  }
}

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
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _seedController = TextEditingController();
  final _xController = TextEditingController(text: '0');
  final _yController = TextEditingController(text: '-59');
  final _zController = TextEditingController(text: '0');
  final _radiusController = TextEditingController(text: '50');

  // Key for refreshing recent seeds
  final GlobalKey<State> _searchTabKey = GlobalKey();

  // Search state
  Set<OreType> _selectedOreTypes = {OreType.diamond};
  bool _includeNether = false;
  bool _includeOres = true;
  bool _includeStructures = false;
  Set<StructureType> _selectedStructures = {};

  // Results state
  bool _isLoading = false;
  List<OreLocation> _results = [];
  List<StructureLocation> _structureResults = [];
  bool _findAllNetherite = false;

  // UI state
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadLastSearchParams();
    _setupListeners();
  }

  Future<void> _loadLastSearchParams() async {
    final params = await PreferencesService.getAllSearchParams();
    _seedController.text = params['seed']!;
    _xController.text = params['x']!;
    _yController.text = params['y']!;
    _zController.text = params['z']!;
    _radiusController.text = params['radius']!;
  }

  void _setupListeners() {
    _seedController.addListener(
        () => PreferencesService.saveLastSeed(_seedController.text));
    _xController
        .addListener(() => PreferencesService.saveLastX(_xController.text));
    _yController
        .addListener(() => PreferencesService.saveLastY(_yController.text));
    _zController
        .addListener(() => PreferencesService.saveLastZ(_zController.text));
    _radiusController.addListener(
        () => PreferencesService.saveLastRadius(_radiusController.text));
  }

  @override
  void dispose() {
    // Remove all listeners before disposing
    _seedController.removeListener(
        () => PreferencesService.saveLastSeed(_seedController.text));
    _xController
        .removeListener(() => PreferencesService.saveLastX(_xController.text));
    _yController
        .removeListener(() => PreferencesService.saveLastY(_yController.text));
    _zController
        .removeListener(() => PreferencesService.saveLastZ(_zController.text));
    _radiusController.removeListener(
        () => PreferencesService.saveLastRadius(_radiusController.text));

    _seedController.dispose();
    _xController.dispose();
    _yController.dispose();
    _zController.dispose();
    _radiusController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _findOres(bool comprehensiveNetherite) async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that at least one search type is enabled
    if (!_includeOres && !_includeStructures) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorEnableSearchType),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate that if structures are enabled, at least one structure type is selected
    if (_includeStructures && _selectedStructures.isEmpty) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorSelectStructure),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate that if ores are enabled, at least one ore type is selected
    if (_includeOres && _selectedOreTypes.isEmpty) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorSelectOre),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _results.clear();
      _structureResults.clear();
      _findAllNetherite = comprehensiveNetherite;
    });

    // Add the current seed to recent seeds when starting a search
    await PreferencesService.addRecentSeed(_seedController.text);

    try {
      final finder = OreFinder();
      final structureFinder = StructureFinder();
      List<OreLocation> allResults = [];

      // Search for ores if enabled
      if (_includeOres) {
        if (comprehensiveNetherite) {
          final results = await finder.findAllNetherite(
            seed: _seedController.text,
            centerX: int.parse(_xController.text),
            centerZ: int.parse(_zController.text),
          );
          allResults.addAll(results);
        } else {
          for (OreType oreType in _selectedOreTypes) {
            final results = await finder.findOres(
              seed: _seedController.text,
              centerX: int.parse(_xController.text),
              centerY: int.parse(_yController.text),
              centerZ: int.parse(_zController.text),
              radius: int.parse(_radiusController.text),
              oreType: oreType,
              includeNether: _includeNether && oreType == OreType.gold,
            );
            allResults.addAll(results);
          }
        }
      }

      // Search for structures if enabled
      List<StructureLocation> structureResults = [];
      if (_includeStructures && _selectedStructures.isNotEmpty) {
        structureResults = await structureFinder.findStructures(
          seed: _seedController.text,
          centerX: int.parse(_xController.text),
          centerZ: int.parse(_zController.text),
          radius: int.parse(_radiusController.text),
          structureTypes: _selectedStructures,
        );
      }

      // Combine all results into a unified list for proper sorting
      List<SearchResult> combinedResults = [];

      // Add ore results
      for (final ore in allResults) {
        combinedResults.add(SearchResult.fromOre(ore));
      }

      // Add structure results
      for (final structure in structureResults) {
        combinedResults.add(SearchResult.fromStructure(structure));
      }

      // Sort all results by probability (highest first)
      combinedResults.sort((a, b) => b.probability.compareTo(a.probability));

      // Take top 250 results (or 300 for comprehensive netherite search)
      int maxResults = comprehensiveNetherite ? 300 : 250;
      final topResults = combinedResults.take(maxResults).toList();

      // Separate back into ore and structure lists for the UI
      final topOreResults = <OreLocation>[];
      final topStructureResults = <StructureLocation>[];

      for (final result in topResults) {
        if (result.type == SearchResultType.ore && result.oreLocation != null) {
          topOreResults.add(result.oreLocation!);
        } else if (result.type == SearchResultType.structure &&
            result.structureLocation != null) {
          topStructureResults.add(result.structureLocation!);
        }
      }

      setState(() {
        _results = topOreResults;
        _structureResults = topStructureResults;
        _isLoading = false;
      });

      // Auto-switch to results tab
      _tabController.animateTo(1);

      // Refresh the search tab to update recent seeds
      if (_searchTabKey.currentState != null) {
        (_searchTabKey.currentState as dynamic).refreshRecentSeeds();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorGeneric(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Gamer-styled tab bar
          Container(
            color: isDark ? GamerColors.darkSurface : Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: GamerColors.neonGreen,
              indicatorWeight: 3,
              labelColor: isDark ? GamerColors.neonGreen : GamerColors.lightGreen,
              unselectedLabelColor: isDark ? Colors.white54 : Colors.grey[500],
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(icon: const Icon(Icons.search, size: 18), text: AppLocalizations.of(context).searchTab, height: 48),
                Tab(icon: const Icon(Icons.inventory_2_outlined, size: 18), text: AppLocalizations.of(context).resultsTab, height: 48),
                Tab(icon: const Icon(Icons.menu_book_outlined, size: 18), text: AppLocalizations.of(context).guideTab, height: 48),
                Tab(icon: const Icon(Icons.sports_esports, size: 18), text: AppLocalizations.of(context).bedwarsTab, height: 48),
                Tab(icon: const Icon(Icons.update_outlined, size: 18), text: AppLocalizations.of(context).updatesTab, height: 48),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SearchTab(
                  key: _searchTabKey,
                  formKey: _formKey,
                  seedController: _seedController,
                  xController: _xController,
                  yController: _yController,
                  zController: _zController,
                  radiusController: _radiusController,
                  selectedOreTypes: _selectedOreTypes,
                  includeNether: _includeNether,
                  includeOres: _includeOres,
                  includeStructures: _includeStructures,
                  selectedStructures: _selectedStructures,
                  isLoading: _isLoading,
                  findAllNetherite: _findAllNetherite,
                  isDarkMode: widget.isDarkMode,
                  onOreTypesChanged: (types) =>
                      setState(() => _selectedOreTypes = types),
                  onIncludeNetherChanged: (value) =>
                      setState(() => _includeNether = value),
                  onIncludeOresChanged: (value) =>
                      setState(() => _includeOres = value),
                  onIncludeStructuresChanged: (value) =>
                      setState(() => _includeStructures = value),
                  onStructuresChanged: (structures) =>
                      setState(() => _selectedStructures = structures),
                  onFindOres: _findOres,
                ),
                ResultsTab(
                  results: _results,
                  structureResults: _structureResults,
                  isLoading: _isLoading,
                  findAllNetherite: _findAllNetherite,
                  selectedOreTypes: _selectedOreTypes,
                ),
                GuideTab(isDarkMode: widget.isDarkMode),
                BedwarsGuideTab(isDarkMode: widget.isDarkMode),
                ReleaseNotesTab(isDarkMode: widget.isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isDark = widget.isDarkMode;
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
              boxShadow: isDark ? GamerColors.subtleGlow(GamerColors.neonGreen) : null,
            ),
            child: const Center(
              child: Text('⛏️', style: TextStyle(fontSize: 14)),
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
            _buildLanguageItem(const Locale('es'), 'Español'),
            _buildLanguageItem(const Locale('ja'), '日本語'),
            _buildLanguageItem(const Locale('fr'), 'Français'),
          ],
        ),
        IconButton(
          onPressed: widget.onThemeToggle,
          icon: Icon(
            widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: isDark ? GamerColors.neonYellow : Colors.grey[700],
            size: 20,
          ),
          tooltip: widget.isDarkMode ? AppLocalizations.of(context).lightThemeTooltip : AppLocalizations.of(context).darkThemeTooltip,
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
                color: isDark ? GamerColors.neonGreen : GamerColors.lightGreen),
        ],
      ),
    );
  }
}
