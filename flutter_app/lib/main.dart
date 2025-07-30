import 'package:flutter/material.dart';

import 'models/ore_finder.dart';
import 'models/ore_location.dart';
import 'models/structure_finder.dart';
import 'models/structure_location.dart';
import 'models/search_result.dart';
import 'widgets/search_tab.dart';
import 'widgets/results_tab.dart';
import 'widgets/guide_tab.dart';
import 'widgets/release_notes_tab.dart';

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

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:
          'Gem, Ore & Struct Finder for MC - Find Diamonds, Gold, Netherite & More',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home:
          OreFinderScreen(onThemeToggle: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      primarySwatch: Colors.green,
      useMaterial3: true,
      fontFamily: null, // Use system default fonts
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF4CAF50),
        secondary: const Color(0xFF8BC34A),
        surface: const Color(0xFFF1F8E9),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: null, // Use system default fonts
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF66BB6A),
        secondary: const Color(0xFF8BC34A),
        surface: const Color(0xFF1E1E1E),
      ),
      cardTheme: CardThemeData(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class OreFinderScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const OreFinderScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
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
    _tabController = TabController(length: 4, vsync: this);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please enable at least one search type (Ores or Structures)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate that if structures are enabled, at least one structure type is selected
    if (_includeStructures && _selectedStructures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please select at least one structure type to search for'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate that if ores are enabled, at least one ore type is selected
    if (_includeOres && _selectedOreTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one ore type to search for'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: TabBarView(
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
          ReleaseNotesTab(isDarkMode: widget.isDarkMode),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 48,
      title: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF8B4513),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFF654321), width: 1),
            ),
            child: const Center(
              child: Text('⛏️', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Gem, Ore & Struct Finder',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor:
          widget.isDarkMode ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50),
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 2),
          child: IconButton(
            onPressed: () =>
                AppInfoDialog.show(context, isDarkMode: widget.isDarkMode),
            icon: const Icon(Icons.info_outline, color: Colors.white, size: 20),
            tooltip: 'App Info',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 4),
          child: IconButton(
            onPressed: widget.onThemeToggle,
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
              size: 20,
            ),
            tooltip: widget.isDarkMode ? 'Light' : 'Dark',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          indicatorWeight: 2,
          tabs: [
            const Tab(
                icon: Icon(Icons.search, size: 16), text: 'Search', height: 40),
            const Tab(
                icon: Icon(Icons.inventory, size: 16),
                text: 'Results',
                height: 40),
            const Tab(
                icon: Icon(Icons.info, size: 16), text: 'Guide', height: 40),
            const Tab(
                icon: Icon(Icons.new_releases, size: 16),
                text: 'Updates',
                height: 40),
          ],
        ),
      ),
    );
  }
}
