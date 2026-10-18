import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/ore_location.dart';
import '../models/search_runner.dart';
import '../models/structure_location.dart';
import '../providers/favorites_provider.dart';
import '../providers/monetization_config.dart';
import '../providers/pro_status_provider.dart';
import '../providers/search_state.dart';
import '../theme/gamer_theme.dart';
import '../utils/ore_utils.dart';
import '../utils/structure_utils.dart';
import 'pro_upgrade_dialog.dart';
import 'result_presentation.dart';
import 'results_map_view.dart';

class ResultsTab extends StatefulWidget {
  final List<OreLocation> results;
  final List<StructureLocation> structureResults;
  final bool isLoading;
  final bool findAllNetherite;
  final Set<OreType> selectedOreTypes;
  final int totalFound;

  /// Metadata for the last search. Drives honest-metadata rendering (Req 12.3,
  /// 12.4, 12.5, 5.4): in Accurate mode the fabricated probability % is
  /// omitted, real metadata is shown, and the Estimate-mode fallback notice is
  /// rendered when a fallback occurred. Null means plain Estimate behavior.
  final SearchMeta? searchMeta;

  const ResultsTab({
    super.key,
    required this.results,
    required this.structureResults,
    required this.isLoading,
    required this.findAllNetherite,
    required this.selectedOreTypes,
    this.totalFound = 0,
    this.searchMeta,
  });

  /// Pure presentation model derived from [searchMeta].
  ResultPresentation get presentation =>
      ResultPresentation.fromMeta(searchMeta);

  @override
  State<ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends State<ResultsTab> {
  final Set<OreType> _visibleOreTypes = {
    OreType.diamond,
    OreType.gold,
    OreType.netherite,
    OreType.redstone,
    OreType.iron,
    OreType.coal,
    OreType.lapis
  };
  Set<StructureType> _visibleStructures = {};
  Set<String> _visibleBiomes = {};
  bool _showFilters = false;
  bool _showMap = false;

  /// Minimum probability (0.0–1.0) a finding must have to be shown.
  /// Defaults to 0.5 so users see a useful spread of findings out of the box
  /// rather than only the very highest-confidence ones (which made searches
  /// look like they "missed" results). A hint below the header tells the user
  /// how many findings the filter is currently hiding.
  double _minProbability = 0.5;

  /// Minimum vein size (ore blocks) a finding must have to be shown. 0 means
  /// "show all". Lets users keep only the bigger veins (e.g. "5+ diamonds").
  /// Only applies to ore results (structures have no vein size).
  int _minVeinSize = 0;

  // Filter controllers
  final _minXController = TextEditingController();
  final _maxXController = TextEditingController();
  final _minYController = TextEditingController();
  final _maxYController = TextEditingController();
  final _minZController = TextEditingController();
  final _maxZController = TextEditingController();

  @override
  void dispose() {
    _minXController.dispose();
    _maxXController.dispose();
    _minYController.dispose();
    _maxYController.dispose();
    _minZController.dispose();
    _maxZController.dispose();
    super.dispose();
  }

  List<OreLocation> get _filteredResults {
    return widget.results.where((location) {
      if (!_visibleOreTypes.contains(location.oreType)) return false;
      if (location.probability < _minProbability) return false;
      if (location.estimatedVeinSize < _minVeinSize) return false;
      if (!_passesBiomeFilter(location.biome)) return false;
      return _passesCoordinateFilters(location.x, location.y, location.z);
    }).toList();
  }

  List<StructureLocation> get _filteredStructureResults {
    return widget.structureResults.where((location) {
      if (_visibleStructures.isNotEmpty &&
          !_visibleStructures.contains(location.structureType)) {
        return false;
      }
      if (location.probability < _minProbability) return false;
      if (!_passesBiomeFilter(location.biome)) return false;
      return _passesCoordinateFilters(location.x, location.y, location.z);
    }).toList();
  }

  /// Number of findings that pass every active filter EXCEPT the probability
  /// threshold — i.e. how many results the probability slider is currently
  /// hiding. Used to surface a "N hidden" hint in the header.
  int get _probabilityHiddenCount {
    int hidden = 0;
    for (final location in widget.results) {
      if (!_visibleOreTypes.contains(location.oreType)) continue;
      if (!_passesBiomeFilter(location.biome)) continue;
      if (!_passesCoordinateFilters(location.x, location.y, location.z)) {
        continue;
      }
      if (location.probability < _minProbability) hidden++;
    }
    for (final location in widget.structureResults) {
      if (_visibleStructures.isNotEmpty &&
          !_visibleStructures.contains(location.structureType)) {
        continue;
      }
      if (!_passesBiomeFilter(location.biome)) continue;
      if (!_passesCoordinateFilters(location.x, location.y, location.z)) {
        continue;
      }
      if (location.probability < _minProbability) hidden++;
    }
    return hidden;
  }

  Widget _buildProbabilityHiddenHint(
      BuildContext context, AppLocalizations l10n) {
    final color = GamerColors.neonGreen;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.visibility_off_outlined,
              size: 14, color: color.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.resultsHiddenByFilter(_probabilityHiddenCount),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _minProbability = 0.0),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: color,
            ),
            child: Text(l10n.showAll,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  bool _passesCoordinateFilters(int x, int y, int z) {
    if (_minXController.text.isNotEmpty) {
      final minX = int.tryParse(_minXController.text);
      if (minX != null && x < minX) return false;
    }
    if (_maxXController.text.isNotEmpty) {
      final maxX = int.tryParse(_maxXController.text);
      if (maxX != null && x > maxX) return false;
    }
    if (_minYController.text.isNotEmpty) {
      final minY = int.tryParse(_minYController.text);
      if (minY != null && y < minY) return false;
    }
    if (_maxYController.text.isNotEmpty) {
      final maxY = int.tryParse(_maxYController.text);
      if (maxY != null && y > maxY) return false;
    }
    if (_minZController.text.isNotEmpty) {
      final minZ = int.tryParse(_minZController.text);
      if (minZ != null && z < minZ) return false;
    }
    if (_maxZController.text.isNotEmpty) {
      final maxZ = int.tryParse(_maxZController.text);
      if (maxZ != null && z > maxZ) return false;
    }
    return true;
  }

  bool _passesBiomeFilter(String? biome) {
    // If no biome filters are set, show all
    if (_visibleBiomes.isEmpty) return true;
    // If biome is null, only show if "Unknown" is selected
    if (biome == null) return _visibleBiomes.contains('Unknown');
    // Otherwise check if the biome is in the visible set
    return _visibleBiomes.contains(biome);
  }

  List<String> _getUniqueBiomes() {
    Set<String> biomes = {};

    // Add biomes from ore results
    for (final ore in widget.results) {
      if (ore.biome != null) {
        biomes.add(ore.biome!);
      } else {
        biomes.add('Unknown');
      }
    }

    // Add biomes from structure results
    for (final structure in widget.structureResults) {
      if (structure.biome != null) {
        biomes.add(structure.biome!);
      } else {
        biomes.add('Unknown');
      }
    }

    return biomes.toList()..sort();
  }

  /// Returns a localized "Showing top N of X potential findings" label when
  /// the search produced more candidates than are displayed. Returns null
  /// when nothing was capped (so the extra line is hidden).
  String? _totalFoundLabel(AppLocalizations l10n) {
    final shown = widget.results.length + widget.structureResults.length;
    if (widget.totalFound > shown) {
      return l10n.showingTopOf(shown, widget.totalFound);
    }
    return null;
  }

  /// Counts how many distinct chunks the given (already filtered) results span.
  /// A chunk is identified by its (chunkX, chunkZ) pair, so several findings in
  /// the same 16x16 chunk are counted once.
  int _distinctChunkCount(List<OreLocation> ores,
      List<StructureLocation> structures) {
    final Set<String> chunks = {};
    for (final ore in ores) {
      chunks.add('${ore.chunkX},${ore.chunkZ}');
    }
    for (final structure in structures) {
      chunks.add('${structure.chunkX},${structure.chunkZ}');
    }
    return chunks.length;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingView(context);
    }

    if (widget.results.isEmpty && widget.structureResults.isEmpty) {
      return _buildEmptyView(context);
    }

    final filteredResults = _filteredResults;
    final filteredStructureResults = _filteredStructureResults;

    return Column(
      children: [
        _buildModeNotice(context),
        _buildFilterHeader(context, filteredResults, filteredStructureResults),
        Expanded(
          child: _showMap
              ? ResultsMapView(
                  results: filteredResults,
                  structureResults: filteredStructureResults,
                  isDarkMode: Theme.of(context).brightness == Brightness.dark,
                )
              : (filteredResults.isEmpty && filteredStructureResults.isEmpty)
                  ? _buildNoResultsView(context)
                  : _buildResultsList(
                      filteredResults, filteredStructureResults),
        ),
      ],
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: GamerColors.neonGreen,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.findAllNetherite &&
                    widget.selectedOreTypes.contains(OreType.netherite)
                ? l10n.loadingNetherite
                : l10n.loadingAnalyzing,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (widget.findAllNetherite &&
              widget.selectedOreTypes.contains(OreType.netherite)) ...[
            const SizedBox(height: 8),
            Text(
              l10n.loadingTimeMay,
              style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: GamerColors.mutedText(context)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 64, color: GamerColors.mutedIcon(context, alpha: 0.55)),
          const SizedBox(height: 16),
          Text(l10n.noResultsYet,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(l10n.useSearchTabToFind),
        ],
      ),
    );
  }

  Widget _buildNoResultsView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt_off,
              size: 64, color: GamerColors.mutedIcon(context, alpha: 0.55)),
          const SizedBox(height: 16),
          Text(l10n.noResultsMatchFilters,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(l10n.tryAdjustingFilters),
        ],
      ),
    );
  }

  /// Renders the mode-dependent notice above the results:
  ///   - the Estimate-mode fallback notice (with its reason) when a fallback
  ///     occurred (Req 5.4);
  ///   - a seed-accurate notice for Verified Accurate results;
  ///   - the estimate disclaimer for every other (Estimate) result.
  /// Returns an empty box when nothing applies.
  Widget _buildModeNotice(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final presentation = widget.presentation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (presentation.showFallbackNotice) {
      return _buildNoticeBanner(
        context,
        icon: Icons.info_outline,
        color: GamerColors.neonOrange,
        isDark: isDark,
        text: presentation.fallbackText!,
      );
    }
    if (presentation.showExperimentalNotice) {
      // Experimental Accurate (user opt-in on web, unverified version): real
      // positions, but flagged as experimental rather than verified-accurate.
      return _buildNoticeBanner(
        context,
        icon: Icons.science_outlined,
        color: GamerColors.neonOrange,
        isDark: isDark,
        text: l10n.experimentalAccurateNotice,
      );
    }
    if (presentation.showRealMetadata) {
      // Verified Accurate: no disclaimer; surface a positive notice instead.
      return _buildNoticeBanner(
        context,
        icon: Icons.verified_outlined,
        color: GamerColors.neonGreen,
        isDark: isDark,
        text: l10n.accurateResultsNotice,
      );
    }
    if (presentation.showDisclaimer) {
      return _buildNoticeBanner(
        context,
        icon: Icons.info_outline,
        color: GamerColors.neonOrange,
        isDark: isDark,
        text: l10n.estimateDisclaimer,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildNoticeBanner(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required bool isDark,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: color.withValues(alpha: isDark ? 0.12 : 0.08),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 16, color: GamerColors.adaptiveAccent(color, isDark)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(
      BuildContext context,
      List<OreLocation> filteredResults,
      List<StructureLocation> filteredStructureResults) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = GamerColors.greenText(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
            bottom: BorderSide(
                color: GamerColors.neonGreen.withValues(alpha: 0.15),
                width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.place_outlined, size: 20, color: accent),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            l10n.placesFound(filteredResults.length +
                                filteredStructureResults.length),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.grid_on, size: 15, color: accent),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            l10n.chunksCount(_distinctChunkCount(
                                filteredResults, filteredStructureResults)),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.resultsCount(
                        filteredResults.length +
                            filteredStructureResults.length,
                        filteredResults.length,
                        filteredStructureResults.length,
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    if (_totalFoundLabel(l10n) != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 13, color: accent),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _totalFoundLabel(l10n)!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(_showMap ? Icons.view_list : Icons.map_outlined,
                    size: 20),
                onPressed: () => setState(() => _showMap = !_showMap),
                tooltip: _showMap ? l10n.resultsListView : l10n.resultsMapView,
              ),
              IconButton(
                icon: Icon(
                    _showFilters ? Icons.filter_list_off : Icons.filter_list,
                    size: 20),
                onPressed: () => setState(() => _showFilters = !_showFilters),
                tooltip: _showFilters ? l10n.hideFilters : l10n.showFilters,
              ),
            ],
          ),
          // If the probability filter is hiding findings, tell the user and
          // offer a one-tap way to reveal them — so a search never looks like
          // it "missed" results that are actually just filtered out.
          if (_probabilityHiddenCount > 0)
            _buildProbabilityHiddenHint(context, l10n),
          // Filters are hidden by default so results get maximum space.
          // Tap the filter icon to reveal ore/biome/coordinate filters.
          if (_showFilters) ...[
            _buildProbabilityFilter(context),
            if (widget.results.isNotEmpty) _buildVeinSizeFilter(context),
            if (widget.results.isNotEmpty) _buildOreFilters(context),
            if (widget.structureResults.isNotEmpty)
              _buildStructureFilters(context),
            if (widget.results.isNotEmpty || widget.structureResults.isNotEmpty)
              _buildBiomeFilters(context),
            _buildCoordinateFilters(context),
          ],
        ],
      ),
    );
  }

  Widget _buildProbabilityFilter(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = (_minProbability * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(l10n.minProbabilityFilterLabel(percent),
            style:
                Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12)),
        Slider(
          value: _minProbability,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          label: '$percent%',
          activeColor: GamerColors.neonGreen,
          onChanged: (value) => setState(() => _minProbability = value),
        ),
      ],
    );
  }

  /// Largest vein size across the current ore results, used as the slider's
  /// upper bound. Falls back to a small default when there are no results.
  int get _maxVeinSizeInResults {
    int max = 0;
    for (final ore in widget.results) {
      if (ore.estimatedVeinSize > max) max = ore.estimatedVeinSize;
    }
    return max;
  }

  /// "Minimum vein size" slider — keep only veins with at least N blocks. Only
  /// meaningful for ore results, so the caller renders it only when ores exist.
  Widget _buildVeinSizeFilter(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final int maxVein = _maxVeinSizeInResults;
    // Nothing to filter when every vein is the same minimal size.
    if (maxVein <= 1) return const SizedBox.shrink();
    // Clamp the current value in case a new search shrank the range.
    if (_minVeinSize > maxVein) {
      _minVeinSize = maxVein;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(
          _minVeinSize <= 0
              ? l10n.minVeinSizeFilterAll
              : l10n.minVeinSizeFilterLabel(_minVeinSize),
          style:
              Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12),
        ),
        Slider(
          value: _minVeinSize.toDouble().clamp(0, maxVein.toDouble()),
          min: 0,
          max: maxVein.toDouble(),
          divisions: maxVein,
          label: _minVeinSize <= 0 ? l10n.showAll : '$_minVeinSize+',
          activeColor: GamerColors.neonGreen,
          onChanged: (value) =>
              setState(() => _minVeinSize = value.round()),
        ),
      ],
    );
  }

  Widget _buildOreFilters(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(l10n.oreFiltersLabel,
            style:
                Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12)),
        const SizedBox(height: 3),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _buildOreFilterChip(OreType.diamond, l10n.filterDiamonds),
            _buildOreFilterChip(OreType.gold, l10n.filterGold),
            _buildOreFilterChip(OreType.iron, l10n.filterIron),
            _buildOreFilterChip(OreType.redstone, l10n.filterRedstone),
            _buildOreFilterChip(OreType.coal, l10n.filterCoal),
            _buildOreFilterChip(OreType.lapis, l10n.filterLapis),
            _buildOreFilterChip(OreType.netherite, l10n.filterNetherite),
          ],
        ),
      ],
    );
  }

  Widget _buildOreFilterChip(OreType oreType, String label) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      selected: _visibleOreTypes.contains(oreType),
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            _visibleOreTypes.add(oreType);
          } else {
            _visibleOreTypes.remove(oreType);
          }
        });
      },
    );
  }

  Widget _buildStructureFilters(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(l10n.structureFiltersLabel,
            style:
                Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _getUniqueStructureTypes().map((structureType) {
            return FilterChip(
              label: Text(
                '${StructureUtils.getStructureEmoji(structureType)} ${StructureUtils.getStructureName(structureType)}',
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              selected: _visibleStructures.isEmpty ||
                  _visibleStructures.contains(structureType),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    if (_visibleStructures.isEmpty) {
                      _visibleStructures = _getUniqueStructureTypes().toSet();
                    } else {
                      _visibleStructures.add(structureType);
                    }
                  } else {
                    if (_visibleStructures.isEmpty) {
                      _visibleStructures = _getUniqueStructureTypes().toSet();
                    }
                    _visibleStructures.remove(structureType);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBiomeFilters(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uniqueBiomes = _getUniqueBiomes();
    if (uniqueBiomes.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(l10n.biomeFiltersLabel,
            style:
                Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: uniqueBiomes.map((biome) {
            return FilterChip(
              label: Text(
                '${_getBiomeEmoji(biome)} ${_getBiomeName(context, biome)}',
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              selected:
                  _visibleBiomes.isEmpty || _visibleBiomes.contains(biome),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    if (_visibleBiomes.isEmpty) {
                      _visibleBiomes = uniqueBiomes.toSet();
                    } else {
                      _visibleBiomes.add(biome);
                    }
                  } else {
                    if (_visibleBiomes.isEmpty) {
                      _visibleBiomes = uniqueBiomes.toSet();
                    }
                    _visibleBiomes.remove(biome);
                  }
                });
              },
              selectedColor: GamerColors.neonGreen.withValues(alpha: 0.2),
              checkmarkColor:
                  isDark ? GamerColors.neonGreen : GamerColors.lightGreen,
              backgroundColor: Colors.grey.withValues(alpha: 0.1),
              side: BorderSide(
                color: _visibleBiomes.isEmpty || _visibleBiomes.contains(biome)
                    ? GamerColors.neonGreen
                        .withValues(alpha: isDark ? 0.5 : 0.4)
                    : Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCoordinateFilters(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(l10n.coordinateFiltersTitle,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        // X filters
        Row(
          children: [
            Expanded(child: _buildFilterField(_minXController, l10n.minX)),
            const SizedBox(width: 8),
            Expanded(child: _buildFilterField(_maxXController, l10n.maxX)),
          ],
        ),
        const SizedBox(height: 8),
        // Y filters
        Row(
          children: [
            Expanded(child: _buildFilterField(_minYController, l10n.minY)),
            const SizedBox(width: 8),
            Expanded(child: _buildFilterField(_maxYController, l10n.maxY)),
          ],
        ),
        const SizedBox(height: 8),
        // Z filters
        Row(
          children: [
            Expanded(child: _buildFilterField(_minZController, l10n.minZ)),
            const SizedBox(width: 8),
            Expanded(child: _buildFilterField(_maxZController, l10n.maxZ)),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _clearFilters,
          icon: const Icon(Icons.clear),
          label: Text(l10n.clearAllFilters),
        ),
      ],
    );
  }

  Widget _buildFilterField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))],
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildResultsList(List<OreLocation> filteredResults,
      List<StructureLocation> filteredStructureResults) {
    final isPro = !context.watch<MonetizationConfig>().isEnabled ||
        context.watch<ProStatusProvider>().isPro;
    final totalItems = filteredResults.length + filteredStructureResults.length;
    // Add 1 extra item for the Pro upsell card if not pro and has results
    final showProUpsell = !isPro && totalItems > 0;

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      // Dismiss the keyboard (from the coordinate filter fields) when the
      // user scrolls the results list.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: totalItems + (showProUpsell ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < filteredResults.length) {
          return _buildOreResultCard(
              context, filteredResults[index], index + 1);
        } else if (index < totalItems) {
          final structureIndex = index - filteredResults.length;
          return _buildStructureResultCard(
              context, filteredStructureResults[structureIndex]);
        } else {
          // Pro upsell card at the end
          return _buildProUpsellCard(context);
        }
      },
    );
  }

  Widget _buildProUpsellCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 6, top: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: GamerColors.neonPurple.withValues(alpha: 0.3)),
      ),
      color: isDark
          ? GamerColors.neonPurple.withValues(alpha: 0.08)
          : GamerColors.lightPurple.withValues(alpha: 0.05),
      child: InkWell(
        onTap: () {
          // Import is handled via the provider already in scope
          showDialog(
            context: context,
            builder: (_) => ProUpgradeDialog(isDarkMode: isDark),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [GamerColors.neonPurple, GamerColors.neonCyan],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.diamond, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Want more results?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      'Upgrade to Pro for up to 500 results, unlimited radius, and more.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white54
                            : GamerColors.mutedText(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14,
                  color: isDark
                      ? GamerColors.neonPurple
                      : GamerColors.lightPurple),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOreResultCard(
      BuildContext context, OreLocation location, int originalIndex) {
    final l10n = AppLocalizations.of(context);
    final oreColor = _getOreColor(location.oreType);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: oreColor.withValues(alpha: 0.25), width: 1),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: oreColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: oreColor.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              '$originalIndex',
              style: TextStyle(
                  color: oreColor, fontWeight: FontWeight.w800, fontSize: 11),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(OreUtils.getOreEmoji(location.oreType),
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '(${location.x}, ${location.y}, ${location.z})',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            // The thing users care about most: roughly how many ore blocks are
            // in this vein. Always shown (the vein size is populated in every
            // mode), so the result reads "~5 blocks" rather than just a chunk.
            Text(l10n.veinSizeLabel(location.estimatedVeinSize),
                style: TextStyle(
                    fontSize: 14,
                    color: oreColor,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(l10n.chunkLabel(location.chunkX, location.chunkZ),
                style: TextStyle(
                    fontSize: 13, color: GamerColors.mutedText(context))),
            // In Accurate mode the fabricated probability % is omitted
            // (Req 12.3); it only adds noise alongside the vein size.
            if (widget.presentation.showProbability)
              Text(
                  l10n.probabilityLabel(
                      (location.probability * 100).toStringAsFixed(1)),
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500)),
            if (location.biome != null)
              Text(l10n.biomeLabel(_getBiomeName(context, location.biome!)),
                  style: TextStyle(
                    fontSize: 13, color: GamerColors.mutedText(context))),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOreBookmarkButton(context, location),
            IconButton(
              icon: Icon(Icons.copy,
                  size: 18, color: GamerColors.mutedIcon(context)),
              onPressed: () =>
                  _copyCoordinates(context, location.x, location.y, location.z),
              tooltip: l10n.copyCoordinates,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOreBookmarkButton(BuildContext context, OreLocation location) {
    FavoritesProvider? favProvider;
    try {
      favProvider = context.watch<FavoritesProvider>();
    } catch (_) {
      return const SizedBox.shrink();
    }
    String seed = '';
    try {
      seed = context.read<SearchState>().seedController.text;
    } catch (_) {}
    final isFav = favProvider.isOreFavorite(location, seed);
    return IconButton(
      icon: Icon(
        isFav ? Icons.bookmark : Icons.bookmark_border,
        size: 18,
        color: isFav
            ? GamerColors.purpleText(
                Theme.of(context).brightness == Brightness.dark)
            : GamerColors.mutedIcon(context),
      ),
      onPressed: () {
        if (isFav) {
          favProvider!.removeOreFavorite(location, seed);
        } else {
          favProvider!.addOreFavorite(location, seed);
        }
      },
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _buildStructureResultCard(
      BuildContext context, StructureLocation structure) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final structColor = GamerColors.orangeText(isDark);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: structColor.withValues(alpha: 0.25), width: 1),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: structColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: structColor.withValues(alpha: 0.4)),
          ),
          child: const Center(
            child: Text('🏰', style: TextStyle(fontSize: 14)),
          ),
        ),
        title: Row(
          children: [
            Text(StructureUtils.getStructureEmoji(structure.structureType),
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${StructureUtils.getStructureName(structure.structureType)}: (${structure.x}, ${structure.y}, ${structure.z})',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(l10n.chunkLabel(structure.chunkX, structure.chunkZ),
                style: TextStyle(
                    fontSize: 13, color: GamerColors.mutedText(context))),
            // In Accurate mode omit the fabricated probability % (Req 12.3);
            // surface the real structure variant where available (Req 12.4).
            if (widget.presentation.showProbability)
              Text(
                  l10n.probabilityLabel(
                      (structure.probability * 100).toStringAsFixed(1)),
                  style: TextStyle(
                      fontSize: 13,
                      color: structColor,
                      fontWeight: FontWeight.w600)),
            if (widget.presentation.showRealMetadata && structure.biome != null)
              Text(
                  l10n.structureVariantLabel(
                      _getBiomeName(context, structure.biome!)),
                  style: TextStyle(
                      fontSize: 13,
                      color: structColor,
                      fontWeight: FontWeight.w600)),
            if (structure.biome != null)
              Text(l10n.biomeLabel(_getBiomeName(context, structure.biome!)),
                  style: TextStyle(
                    fontSize: 13, color: GamerColors.mutedText(context))),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStructureBookmarkButton(context, structure),
            IconButton(
              icon: Icon(Icons.copy,
                  size: 18, color: GamerColors.mutedIcon(context)),
              onPressed: () => _copyCoordinates(
                  context, structure.x, structure.y, structure.z),
              tooltip: l10n.copyCoordinates,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStructureBookmarkButton(
      BuildContext context, StructureLocation structure) {
    FavoritesProvider? favProvider;
    try {
      favProvider = context.watch<FavoritesProvider>();
    } catch (_) {
      return const SizedBox.shrink();
    }
    String seed = '';
    try {
      seed = context.read<SearchState>().seedController.text;
    } catch (_) {}
    final isFav = favProvider.isStructureFavorite(structure, seed);
    return IconButton(
      icon: Icon(
        isFav ? Icons.bookmark : Icons.bookmark_border,
        size: 18,
        color: isFav
            ? GamerColors.purpleText(
                Theme.of(context).brightness == Brightness.dark)
            : GamerColors.mutedIcon(context),
      ),
      onPressed: () {
        if (isFav) {
          favProvider!.removeStructureFavorite(structure, seed);
        } else {
          favProvider!.addStructureFavorite(structure, seed);
        }
      },
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Color _getOreColor(OreType oreType) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (oreType) {
      case OreType.diamond:
        return GamerColors.diamondText(isDark);
      case OreType.gold:
        return GamerColors.goldText(isDark);
      case OreType.netherite:
        return GamerColors.netheriteText(isDark);
      case OreType.redstone:
        return GamerColors.redstoneText(isDark);
      case OreType.iron:
        return GamerColors.ironText(isDark);
      case OreType.coal:
        return GamerColors.coalText(isDark);
      case OreType.lapis:
        return GamerColors.lapisText(isDark);
      case OreType.copper:
        return GamerColors.orangeText(isDark);
      case OreType.emerald:
        return GamerColors.greenText(isDark);
    }
  }

  List<StructureType> _getUniqueStructureTypes() {
    return widget.structureResults.map((s) => s.structureType).toSet().toList();
  }

  void _copyCoordinates(BuildContext context, int x, int y, int z) {
    final l10n = AppLocalizations.of(context);
    final coordinates = '$x $y $z';
    Clipboard.setData(ClipboardData(text: coordinates));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.copiedCoordinates(coordinates)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _minXController.clear();
      _maxXController.clear();
      _minYController.clear();
      _maxYController.clear();
      _minZController.clear();
      _maxZController.clear();
      _visibleBiomes.clear(); // Also clear biome filters
      _minProbability = 0.8; // Reset probability threshold to default
      _minVeinSize = 0; // Reset vein-size filter to "show all"
    });
  }

  String _getBiomeEmoji(String biome) {
    switch (biome.toLowerCase()) {
      case 'plains':
        return '🌾';
      case 'forest':
        return '🌲';
      case 'desert':
        return '🏜️';
      case 'jungle':
        return '🌿';
      case 'swamp':
        return '🐸';
      case 'taiga':
        return '🌲';
      case 'dappled_forest':
        return '🍂';
      case 'cherry_grove':
        return '🌸';
      case 'savanna':
        return '🦁';
      case 'badlands':
      case 'mesa':
        return '🏔️';
      case 'ocean':
      case 'deep_ocean':
        return '🌊';
      case 'beach':
        return '🏖️';
      case 'nether':
        return '🔥';
      case 'end':
        return '🌌';
      case 'overworld':
        return '🌍';
      case 'unknown':
        return '❓';
      default:
        return '🌍';
    }
  }

  /// Maps an internal biome id (e.g. "dappled_forest") to a friendly,
  /// localized display name (e.g. "Autumn Forest"). Falls back to a
  /// title-cased version of the id for any biome we don't have a name for.
  String _getBiomeName(BuildContext context, String biome) {
    final l10n = AppLocalizations.of(context);
    switch (biome.toLowerCase()) {
      case 'plains':
        return l10n.biomeNamePlains;
      case 'forest':
        return l10n.biomeNameForest;
      case 'desert':
        return l10n.biomeNameDesert;
      case 'jungle':
        return l10n.biomeNameJungle;
      case 'swamp':
        return l10n.biomeNameSwamp;
      case 'taiga':
        return l10n.biomeNameTaiga;
      case 'mountains':
        return l10n.biomeNameMountains;
      case 'dappled_forest':
        return l10n.biomeNameDappledForest;
      case 'cherry_grove':
        return l10n.biomeNameCherryGrove;
      case 'savanna':
        return l10n.biomeNameSavanna;
      case 'badlands':
      case 'mesa':
        return l10n.biomeNameBadlands;
      case 'ocean':
        return l10n.biomeNameOcean;
      case 'deep_ocean':
        return l10n.biomeNameDeepOcean;
      case 'beach':
        return l10n.biomeNameBeach;
      case 'nether':
        return l10n.biomeNameNether;
      case 'end':
        return l10n.biomeNameEnd;
      case 'deep_dark':
        return l10n.biomeNameDeepDark;
      case 'overworld':
        return l10n.biomeNameOverworld;
      case 'unknown':
        return l10n.biomeNameUnknown;
      default:
        return _titleCaseBiomeId(biome);
    }
  }

  /// Fallback: turn a snake_case biome id into a readable label,
  /// e.g. "some_new_biome" -> "Some New Biome".
  String _titleCaseBiomeId(String biome) {
    return biome
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
