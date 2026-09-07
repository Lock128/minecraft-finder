import 'package:flutter/material.dart';
import '../models/game_random.dart';
import '../models/ore_finder.dart';
import '../models/ore_location.dart';
import '../models/structure_finder.dart';
import '../models/structure_location.dart';
import '../models/search_result.dart';
import '../utils/preferences_service.dart';

/// Holds all search form state and orchestrates the search logic.
class SearchState extends ChangeNotifier {
  // Form controllers
  final formKey = GlobalKey<FormState>();
  final seedController = TextEditingController();
  final xController = TextEditingController(text: '0');
  final yController = TextEditingController(text: '-59');
  final zController = TextEditingController(text: '0');
  final radiusController = TextEditingController(text: '50');

  // Edition & version state
  MinecraftEdition _selectedEdition = MinecraftEdition.java;
  MinecraftEdition get selectedEdition => _selectedEdition;

  VersionEra _selectedVersionEra = VersionEra.modern;
  VersionEra get selectedVersionEra => _selectedVersionEra;

  // Search options
  Set<OreType> _selectedOreTypes = {OreType.diamond};
  Set<OreType> get selectedOreTypes => _selectedOreTypes;

  bool _includeNether = false;
  bool get includeNether => _includeNether;

  bool _includeOres = true;
  bool get includeOres => _includeOres;

  bool _includeStructures = false;
  bool get includeStructures => _includeStructures;

  Set<StructureType> _selectedStructures = {};
  Set<StructureType> get selectedStructures => _selectedStructures;

  // Results state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<OreLocation> _results = [];
  List<OreLocation> get results => _results;

  List<StructureLocation> _structureResults = [];
  List<StructureLocation> get structureResults => _structureResults;

  // Total number of candidate locations found before the display cap was
  // applied. Lets the UI show "showing top N of X found".
  int _totalFound = 0;
  int get totalFound => _totalFound;

  // The display cap applied to the last search (based on Pro status).
  int _resultLimit = 0;
  int get resultLimit => _resultLimit;

  // Whether the last search produced more results than were displayed.
  bool get wasCapped => _totalFound > _results.length + _structureResults.length;

  bool _findAllNetherite = false;
  bool get findAllNetherite => _findAllNetherite;

  // Counter that increments when recent seeds should be refreshed.
  // Widgets can listen to this to know when to reload.
  final ValueNotifier<int> recentSeedsRefreshNotifier = ValueNotifier<int>(0);

  // Tab controller for auto-switching to results
  TabController? tabController;

  // Set once dispose() runs so post-await callbacks don't touch a dead notifier.
  bool _disposed = false;

  // Incremented at the start of every search. A running search compares its
  // captured value against this after each await; if they differ, a newer
  // search has superseded it and the stale one bails out without mutating
  // state. This prevents overlapping searches from clobbering each other.
  int _searchGeneration = 0;

  SearchState() {
    _setupListeners();
    _loadLastSearchParams();
  }

  // Named listener methods so they can be properly removed
  void _onSeedChanged() {
    PreferencesService.saveLastSeed(seedController.text);
  }

  void _onXChanged() {
    PreferencesService.saveLastX(xController.text);
  }

  void _onYChanged() {
    PreferencesService.saveLastY(yController.text);
  }

  void _onZChanged() {
    PreferencesService.saveLastZ(zController.text);
  }

  void _onRadiusChanged() {
    PreferencesService.saveLastRadius(radiusController.text);
  }

  void _setupListeners() {
    seedController.addListener(_onSeedChanged);
    xController.addListener(_onXChanged);
    yController.addListener(_onYChanged);
    zController.addListener(_onZChanged);
    radiusController.addListener(_onRadiusChanged);
  }

  Future<void> _loadLastSearchParams() async {
    final params = await PreferencesService.getAllSearchParams();
    final edition = await PreferencesService.getEdition();
    final versionEra = await PreferencesService.getVersionEra();
    _selectedEdition = edition;
    _selectedVersionEra = versionEra;
    if (_disposed) return;
    seedController.text = params['seed']!;
    xController.text = params['x']!;
    yController.text = params['y']!;
    zController.text = params['z']!;
    radiusController.text = params['radius']!;
    notifyListeners();
  }

  void setOreTypes(Set<OreType> types) {
    _selectedOreTypes = types;
    notifyListeners();
  }

  void setIncludeNether(bool value) {
    _includeNether = value;
    notifyListeners();
  }

  void setIncludeOres(bool value) {
    _includeOres = value;
    notifyListeners();
  }

  void setIncludeStructures(bool value) {
    _includeStructures = value;
    notifyListeners();
  }

  void setSelectedStructures(Set<StructureType> structures) {
    _selectedStructures = structures;
    notifyListeners();
  }

  void setEdition(MinecraftEdition edition) {
    _selectedEdition = edition;
    PreferencesService.saveEdition(edition);
    notifyListeners();
  }

  void setVersionEra(VersionEra era) {
    _selectedVersionEra = era;
    PreferencesService.saveVersionEra(era);
    notifyListeners();
  }

  /// Performs the ore/structure search. Returns an error message string
  /// if validation fails, or null on success.
  ///
  /// When [isPro] is false, certain limits apply:
  /// - Comprehensive netherite search is blocked
  /// - Search radius is capped at 50
  /// - Only 1 structure type can be searched at a time
  /// - Results are capped at 50
  Future<String?> findOres(bool comprehensiveNetherite, {
    required String errorEnableSearchType,
    required String errorSelectStructure,
    required String errorSelectOre,
    required String Function(String) errorGeneric,
    bool isPro = false,
  }) async {
    if (!formKey.currentState!.validate()) return null;

    // Validate that at least one search type is enabled
    if (!_includeOres && !_includeStructures) {
      return errorEnableSearchType;
    }

    // Validate that if structures are enabled, at least one structure type is selected
    if (_includeStructures && _selectedStructures.isEmpty) {
      return errorSelectStructure;
    }

    // Validate that if ores are enabled, at least one ore type is selected
    if (_includeOres && _selectedOreTypes.isEmpty) {
      return errorSelectOre;
    }

    // Mark a new search generation. Any previously running search will see a
    // mismatch after its next await and abort without touching state.
    final int generation = ++_searchGeneration;

    _isLoading = true;
    _results = [];
    _structureResults = [];
    _findAllNetherite = comprehensiveNetherite;
    notifyListeners();

    // Apply Pro tier limits
    final int effectiveRadius;
    if (isPro) {
      effectiveRadius = int.parse(radiusController.text);
    } else {
      // Free users capped at 50-block radius
      final requested = int.parse(radiusController.text);
      effectiveRadius = requested > 50 ? 50 : requested;
    }

    // Free users cannot use comprehensive netherite search
    final bool effectiveComprehensiveNetherite = isPro && comprehensiveNetherite;

    // Free users can only search 1 structure type at a time
    final Set<StructureType> effectiveStructures;
    if (isPro || _selectedStructures.length <= 1) {
      effectiveStructures = _selectedStructures;
    } else {
      effectiveStructures = {_selectedStructures.first};
    }

    // Display cap based on Pro status.
    // Free: 50 results, Pro: 500 (or 300 for comprehensive netherite).
    final int maxResults;
    if (isPro) {
      maxResults = effectiveComprehensiveNetherite ? 300 : 500;
    } else {
      maxResults = 50;
    }

    // Add the current seed to recent seeds when starting a search
    await PreferencesService.addRecentSeed(seedController.text);

    try {
      final finder = OreFinder();
      final structureFinder = StructureFinder();
      List<OreLocation> allResults = [];

      // Total qualifying candidates across all finders, before the display cap.
      // Drives the "showing top N of X found" label in the results tab.
      int totalCandidates = 0;

      // Search for ores if enabled. Each finder retains at most [maxResults]
      // locations internally, so peak memory stays bounded no matter how large
      // the search radius is — this is what prevents the OOM crash.
      if (_includeOres) {
        if (effectiveComprehensiveNetherite) {
          final results = await finder.findAllNetherite(
            seed: seedController.text,
            centerX: int.parse(xController.text),
            centerZ: int.parse(zController.text),
            edition: _selectedEdition,
            versionEra: _selectedVersionEra,
            maxResults: maxResults,
            onTotalFound: (n) => totalCandidates += n,
          );
          allResults.addAll(results);
        } else {
          for (OreType oreType in _selectedOreTypes) {
            final results = await finder.findOres(
              seed: seedController.text,
              centerX: int.parse(xController.text),
              centerY: int.parse(yController.text),
              centerZ: int.parse(zController.text),
              radius: effectiveRadius,
              oreType: oreType,
              includeNether: _includeNether && oreType == OreType.gold,
              edition: _selectedEdition,
              versionEra: _selectedVersionEra,
              maxResults: maxResults,
              onTotalFound: (n) => totalCandidates += n,
            );
            allResults.addAll(results);
          }
        }
      }

      // Search for structures if enabled
      List<StructureLocation> structureResults = [];
      if (_includeStructures && effectiveStructures.isNotEmpty) {
        structureResults = await structureFinder.findStructures(
          seed: seedController.text,
          centerX: int.parse(xController.text),
          centerZ: int.parse(zController.text),
          radius: effectiveRadius,
          structureTypes: effectiveStructures,
          maxResults: maxResults,
          onTotalFound: (n) => totalCandidates += n,
        );
      }

      // A newer search started (or the provider was disposed) while this one
      // was running. Discard these stale results without touching state.
      if (_disposed || generation != _searchGeneration) {
        return null;
      }

      // Combine all results into a unified list for proper sorting
      List<SearchResult> combinedResults = [];
      for (final ore in allResults) {
        combinedResults.add(SearchResult.fromOre(ore));
      }
      for (final structure in structureResults) {
        combinedResults.add(SearchResult.fromStructure(structure));
      }

      // Sort all results by probability (highest first)
      combinedResults.sort((a, b) => b.probability.compareTo(a.probability));

      final topResults = combinedResults.take(maxResults).toList();

      // Record how many candidates were found before capping, so the UI can
      // show the true number of potential findings.
      _totalFound = totalCandidates;
      _resultLimit = maxResults;

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

      _results = topOreResults;
      _structureResults = topStructureResults;
      _isLoading = false;
      notifyListeners();

      // Auto-switch to results tab
      tabController?.animateTo(1);

      // Signal recent seeds widgets to refresh
      recentSeedsRefreshNotifier.value++;

      return null; // success
    } catch (e) {
      // Only surface the error if this search is still the current one and the
      // provider is alive; otherwise there's nothing to update.
      if (_disposed || generation != _searchGeneration) {
        return null;
      }
      _isLoading = false;
      notifyListeners();
      return errorGeneric(e.toString());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    seedController.removeListener(_onSeedChanged);
    xController.removeListener(_onXChanged);
    yController.removeListener(_onYChanged);
    zController.removeListener(_onZChanged);
    radiusController.removeListener(_onRadiusChanged);

    seedController.dispose();
    xController.dispose();
    yController.dispose();
    zController.dispose();
    radiusController.dispose();
    recentSeedsRefreshNotifier.dispose();
    super.dispose();
  }
}
