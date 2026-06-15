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

  bool _findAllNetherite = false;
  bool get findAllNetherite => _findAllNetherite;

  // Counter that increments when recent seeds should be refreshed.
  // Widgets can listen to this to know when to reload.
  final ValueNotifier<int> recentSeedsRefreshNotifier = ValueNotifier<int>(0);

  // Tab controller for auto-switching to results
  TabController? tabController;

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
  Future<String?> findOres(bool comprehensiveNetherite, {
    required String errorEnableSearchType,
    required String errorSelectStructure,
    required String errorSelectOre,
    required String Function(String) errorGeneric,
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

    _isLoading = true;
    _results = [];
    _structureResults = [];
    _findAllNetherite = comprehensiveNetherite;
    notifyListeners();

    // Add the current seed to recent seeds when starting a search
    await PreferencesService.addRecentSeed(seedController.text);

    try {
      final finder = OreFinder();
      final structureFinder = StructureFinder();
      List<OreLocation> allResults = [];

      // Search for ores if enabled
      if (_includeOres) {
        if (comprehensiveNetherite) {
          final results = await finder.findAllNetherite(
            seed: seedController.text,
            centerX: int.parse(xController.text),
            centerZ: int.parse(zController.text),
            edition: _selectedEdition,
            versionEra: _selectedVersionEra,
          );
          allResults.addAll(results);
        } else {
          for (OreType oreType in _selectedOreTypes) {
            final results = await finder.findOres(
              seed: seedController.text,
              centerX: int.parse(xController.text),
              centerY: int.parse(yController.text),
              centerZ: int.parse(zController.text),
              radius: int.parse(radiusController.text),
              oreType: oreType,
              includeNether: _includeNether && oreType == OreType.gold,
              edition: _selectedEdition,
              versionEra: _selectedVersionEra,
            );
            allResults.addAll(results);
          }
        }
      }

      // Search for structures if enabled
      List<StructureLocation> structureResults = [];
      if (_includeStructures && _selectedStructures.isNotEmpty) {
        structureResults = await structureFinder.findStructures(
          seed: seedController.text,
          centerX: int.parse(xController.text),
          centerZ: int.parse(zController.text),
          radius: int.parse(radiusController.text),
          structureTypes: _selectedStructures,
        );
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
      _isLoading = false;
      notifyListeners();
      return errorGeneric(e.toString());
    }
  }

  @override
  void dispose() {
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
