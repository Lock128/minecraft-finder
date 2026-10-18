import 'package:flutter/material.dart';
import '../models/game_random.dart';
import '../models/ore_location.dart';
import '../models/search_runner.dart';
import '../models/structure_location.dart';
import '../models/search_result.dart';
import '../models/version_availability.dart';
import '../models/worldgen/default_registry.dart';
import '../models/worldgen/engine_selector.dart';
import '../models/worldgen/minecraft_version.dart';
import '../models/worldgen/version_strategy_registry.dart';
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

  // Registry of seed-accurate version strategies. Single source of truth for
  // which versions are Supported / Verified — the UI reads it so the version
  // picker and the result cards never hard-code verification state.
  final VersionStrategyRegistry _registry = buildDefaultRegistry();

  /// Supported versions for the current edition, sourced from the registry,
  /// for the version picker (Req 12.1). Empty when the edition has no
  /// seed-accurate strategies yet (e.g. Bedrock today).
  List<MinecraftVersion> get availableVersions =>
      VersionAvailability.supportedVersions(_registry,
          edition: _selectedEdition);

  /// The explicitly selected Minecraft version, or null when the user has not
  /// picked one (the search then derives a version from the era). Only versions
  /// in [availableVersions] are ever stored here.
  MinecraftVersion? _selectedVersion;
  MinecraftVersion? get selectedVersion => _selectedVersion;

  /// Whether [version] is a Verified_Version per the registry.
  bool isVersionVerified(MinecraftVersion version) =>
      _registry.isVerified(version);

  /// The requested search mode (Req 12.2). Defaults to [SearchMode.estimate]
  /// so existing users keep the current behavior exactly.
  SearchMode _searchMode = SearchMode.estimate;
  SearchMode get searchMode => _searchMode;

  /// Metadata describing how the most recent search output was produced
  /// (mode / version / verified / fallbackReason). Null until a search runs.
  /// The results UI reads it to omit the fabricated probability % in Accurate
  /// mode and to render the Estimate-mode fallback notice (Req 12.3-12.5, 5.4).
  SearchMeta? _lastSearchMeta;
  SearchMeta? get lastSearchMeta => _lastSearchMeta;

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

  // When true (and Netherite is selected), the single "Find" action performs a
  // whole-world Netherite deep scan instead of a radius-bounded search. This
  // replaces the former separate "Find all Netherite" button.
  bool _wholeWorldNetherite = false;
  bool get wholeWorldNetherite => _wholeWorldNetherite;

  void setWholeWorldNetherite(bool value) {
    _wholeWorldNetherite = value;
    notifyListeners();
  }

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
  bool get wasCapped =>
      _totalFound > _results.length + _structureResults.length;

  /// Radius cap applied to free-tier searches.
  static const int freeRadiusCap = 50;

  /// Whether the last search clamped a free user's requested radius down to
  /// [freeRadiusCap]. Surfaced in the UI so the clamp is not silent.
  bool _lastRadiusWasCapped = false;
  bool get lastRadiusWasCapped => _lastRadiusWasCapped;

  bool _findAllNetherite = false;
  bool get findAllNetherite => _findAllNetherite;

  // Counter that increments when recent seeds should be refreshed.
  // Widgets can listen to this to know when to reload.
  final ValueNotifier<int> recentSeedsRefreshNotifier = ValueNotifier<int>(0);

  // Whether the Quick Start onboarding card has been dismissed by the user.
  // Loaded from preferences on construction; hiding it persists the choice so
  // returning users don't see it again.
  bool _quickStartHidden = false;
  bool get quickStartHidden => _quickStartHidden;

  void hideQuickStart() {
    _quickStartHidden = true;
    PreferencesService.setQuickStartHidden(true);
    notifyListeners();
  }

  /// Restore the Quick Start card (e.g. from settings). Persists the choice.
  void showQuickStart() {
    _quickStartHidden = false;
    PreferencesService.setQuickStartHidden(false);
    notifyListeners();
  }

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
    final quickStartHidden = await PreferencesService.getQuickStartHidden();
    _selectedEdition = edition;
    _selectedVersionEra = versionEra;
    _quickStartHidden = quickStartHidden;
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
    _pruneUnavailableSelections();
    notifyListeners();
  }

  void setVersionEra(VersionEra era) {
    _selectedVersionEra = era;
    PreferencesService.saveVersionEra(era);
    _pruneUnavailableSelections();
    notifyListeners();
  }

  /// Select an explicit [MinecraftVersion] from the picker, or clear the
  /// selection with null. Keeps [selectedVersionEra] in sync so the Simulated
  /// path and content gating still work from the chosen version's era.
  void setSelectedVersion(MinecraftVersion? version) {
    _selectedVersion = version;
    if (version != null) {
      _selectedVersionEra = version.era;
      PreferencesService.saveVersionEra(_selectedVersionEra);
      _pruneUnavailableSelections();
    }
    notifyListeners();
  }

  /// Switch the Accurate/Estimate [SearchMode] (Req 12.2).
  void setSearchMode(SearchMode mode) {
    _searchMode = mode;
    notifyListeners();
  }

  /// Drop any selected ore/structure that does not exist in the currently
  /// selected edition/version era. Called when the edition or era changes so
  /// the selection never silently holds content that the search would reject
  /// and the UI no longer shows. Keeps at least one valid ore selected.
  void _pruneUnavailableSelections() {
    final availableOres = VersionAvailability.availableOres(
      era: _selectedVersionEra,
      edition: _selectedEdition,
    ).toSet();
    _selectedOreTypes =
        _selectedOreTypes.where(availableOres.contains).toSet();
    if (_selectedOreTypes.isEmpty && availableOres.isNotEmpty) {
      _selectedOreTypes = {availableOres.first};
    }
    // Nether gold only makes sense when gold is still selected.
    if (!_selectedOreTypes.contains(OreType.gold)) {
      _includeNether = false;
    }

    final availableStructures = VersionAvailability.availableStructures(
      era: _selectedVersionEra,
      edition: _selectedEdition,
    ).toSet();
    _selectedStructures =
        _selectedStructures.where(availableStructures.contains).toSet();
  }

  /// Performs the ore/structure search. Returns an error message string
  /// if validation fails, or null on success.
  ///
  /// When [isPro] is false, certain limits apply:
  /// - Comprehensive netherite search is blocked
  /// - Search radius is capped at 50
  /// - Only 1 structure type can be searched at a time
  /// - Results are capped at 50
  Future<String?> findOres(
    bool comprehensiveNetherite, {
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
    _lastRadiusWasCapped = false;
    if (isPro) {
      effectiveRadius = int.parse(radiusController.text);
    } else {
      // Free users capped at [freeRadiusCap]. Record when we actually clamped
      // so the UI can tell the user instead of silently shrinking the search.
      final requested = int.parse(radiusController.text);
      if (requested > freeRadiusCap) {
        effectiveRadius = freeRadiusCap;
        _lastRadiusWasCapped = true;
      } else {
        effectiveRadius = requested;
      }
    }

    // Free users cannot use comprehensive netherite search
    final bool effectiveComprehensiveNetherite =
        isPro && comprehensiveNetherite;

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

    // Parse coordinates once, before dispatching to the background isolate.
    final int centerX = int.parse(xController.text);
    final int centerY = int.parse(yController.text);
    final int centerZ = int.parse(zController.text);
    final String seed = seedController.text;

    // The mode + explicit version id to send with each search request. These
    // flow into the WorldGenEngine selection inside the isolate.
    final SearchMode mode = _searchMode;
    final String? versionId = _selectedVersion?.id;

    try {
      List<OreLocation> allResults = [];

      // Total qualifying candidates across all finders, before the display cap.
      // Drives the "showing top N of X found" label in the results tab.
      int totalCandidates = 0;

      // The SearchMeta from the produced output(s). All sub-searches in a run
      // share the same mode/version, so the first non-null meta describes the
      // whole result set and drives the results-tab presentation.
      SearchMeta? meta;

      // Search for ores and structures if enabled. Each search runs on its own
      // background isolate (via compute) so the heavy loops never block the UI
      // thread. The per-ore searches and the structure search are mutually
      // independent, so we dispatch them all up front and await them together
      // with Future.wait — on a multi-core device this runs them concurrently
      // instead of one-at-a-time, cutting a multi-ore search toward the cost of
      // the single slowest ore. Each finder still retains at most [maxResults]
      // locations, keeping memory bounded.
      //
      // Determinism of the combined output is preserved because results are
      // gathered in a fixed order (ores in _selectedOreTypes order, then
      // structures) regardless of which isolate finishes first, and the final
      // sort is stable.

      // Dispatch ore searches (futures started eagerly, awaited below).
      Future<SearchOutput<OreLocation>>? netheriteFuture;
      final List<Future<SearchOutput<OreLocation>>> oreFutures = [];
      if (_includeOres) {
        if (effectiveComprehensiveNetherite) {
          netheriteFuture = SearchRunner.findAllNetherite(
            NetheriteSearchParams(
              seed: seed,
              centerX: centerX,
              centerZ: centerZ,
              edition: _selectedEdition,
              versionEra: _selectedVersionEra,
              maxResults: maxResults,
            ),
          );
        } else {
          for (final OreType oreType in _selectedOreTypes) {
            oreFutures.add(
              SearchRunner.findOres(
                OreSearchParams(
                  seed: seed,
                  centerX: centerX,
                  centerY: centerY,
                  centerZ: centerZ,
                  radius: effectiveRadius,
                  oreType: oreType,
                  includeNether: _includeNether && oreType == OreType.gold,
                  edition: _selectedEdition,
                  versionEra: _selectedVersionEra,
                  maxResults: maxResults,
                  mode: mode,
                  versionId: versionId,
                ),
              ),
            );
          }
        }
      }

      // Dispatch the structure search concurrently with the ore searches.
      Future<SearchOutput<StructureLocation>>? structureFuture;
      if (_includeStructures && effectiveStructures.isNotEmpty) {
        structureFuture = SearchRunner.findStructures(
          StructureSearchParams(
            seed: seed,
            centerX: centerX,
            centerZ: centerZ,
            radius: effectiveRadius,
            structureTypes: effectiveStructures,
            maxResults: maxResults,
            edition: _selectedEdition,
            versionEra: _selectedVersionEra,
            mode: mode,
            versionId: versionId,
          ),
        );
      }

      // Await everything together. Collect ore outputs in a fixed order so the
      // combined result and the chosen [meta] are independent of completion
      // order.
      final List<SearchOutput<OreLocation>> oreOutputs =
          await Future.wait(oreFutures);
      final SearchOutput<OreLocation>? netheriteOutput =
          netheriteFuture == null ? null : await netheriteFuture;
      final SearchOutput<StructureLocation>? structureOutput =
          structureFuture == null ? null : await structureFuture;

      // Gather ore results (ore precedence first, mirroring the previous
      // sequential order), then structures.
      if (netheriteOutput != null) {
        allResults.addAll(netheriteOutput.results);
        totalCandidates += netheriteOutput.totalFound;
        meta ??= netheriteOutput.meta;
      }
      for (final output in oreOutputs) {
        allResults.addAll(output.results);
        totalCandidates += output.totalFound;
        meta ??= output.meta;
      }

      List<StructureLocation> structureResults = [];
      if (structureOutput != null) {
        structureResults = structureOutput.results;
        totalCandidates += structureOutput.totalFound;
        meta ??= structureOutput.meta;
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
      _lastSearchMeta = meta;
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
