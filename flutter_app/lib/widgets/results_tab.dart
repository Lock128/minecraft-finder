import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/ore_location.dart';
import '../models/structure_location.dart';
import '../theme/gamer_theme.dart';
import '../utils/ore_utils.dart';
import '../utils/structure_utils.dart';

class ResultsTab extends StatefulWidget {
  final List<OreLocation> results;
  final List<StructureLocation> structureResults;
  final bool isLoading;
  final bool findAllNetherite;
  final Set<OreType> selectedOreTypes;

  const ResultsTab({
    super.key,
    required this.results,
    required this.structureResults,
    required this.isLoading,
    required this.findAllNetherite,
    required this.selectedOreTypes,
  });

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
      if (!_passesBiomeFilter(location.biome)) return false;
      return _passesCoordinateFilters(location.x, location.y, location.z);
    }).toList();
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
        _buildFilterHeader(context, filteredResults, filteredStructureResults),
        Expanded(
          child: (filteredResults.isEmpty && filteredStructureResults.isEmpty)
              ? _buildNoResultsView(context)
              : _buildResultsList(filteredResults, filteredStructureResults),
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
            width: 48, height: 48,
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
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[500]),
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
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
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
          Icon(Icons.filter_alt_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(l10n.noResultsMatchFilters,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(l10n.tryAdjustingFilters),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(BuildContext context, List<OreLocation> filteredResults,
      List<StructureLocation> filteredStructureResults) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
            bottom: BorderSide(
                color: GamerColors.neonGreen.withValues(alpha: 0.15), width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.resultsCount(
                    filteredResults.length + filteredStructureResults.length,
                    filteredResults.length,
                    filteredStructureResults.length,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
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
          if (widget.results.isNotEmpty) _buildOreFilters(context),
          if (widget.structureResults.isNotEmpty) _buildStructureFilters(context),
          if (widget.results.isNotEmpty || widget.structureResults.isNotEmpty)
            _buildBiomeFilters(context),
          if (_showFilters) _buildCoordinateFilters(context),
        ],
      ),
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
                '${_getBiomeEmoji(biome)} $biome',
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
              checkmarkColor: isDark ? GamerColors.neonGreen : GamerColors.lightGreen,
              backgroundColor: Colors.grey.withValues(alpha: 0.1),
              side: BorderSide(
                color: _visibleBiomes.isEmpty || _visibleBiomes.contains(biome)
                    ? GamerColors.neonGreen.withValues(alpha: isDark ? 0.5 : 0.4)
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
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredResults.length + filteredStructureResults.length,
      itemBuilder: (context, index) {
        if (index < filteredResults.length) {
          return _buildOreResultCard(context, filteredResults[index], index + 1);
        } else {
          final structureIndex = index - filteredResults.length;
          return _buildStructureResultCard(
              context, filteredStructureResults[structureIndex]);
        }
      },
    );
  }

  Widget _buildOreResultCard(BuildContext context, OreLocation location, int originalIndex) {
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
          width: 32, height: 32,
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
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(l10n.chunkLabel(location.chunkX, location.chunkZ),
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            Text(
                l10n.probabilityLabel((location.probability * 100).toStringAsFixed(1)),
                style: TextStyle(fontSize: 11, color: oreColor, fontWeight: FontWeight.w600)),
            if (location.biome != null)
              Text(l10n.biomeLabel(location.biome!),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.copy, size: 18, color: Colors.grey[400]),
          onPressed: () => _copyCoordinates(context, location.x, location.y, location.z),
          tooltip: l10n.copyCoordinates,
        ),
      ),
    );
  }

  Widget _buildStructureResultCard(BuildContext context, StructureLocation structure) {
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
          width: 32, height: 32,
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
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(l10n.chunkLabel(structure.chunkX, structure.chunkZ),
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            Text(
                l10n.probabilityLabel((structure.probability * 100).toStringAsFixed(1)),
                style: TextStyle(fontSize: 11, color: structColor, fontWeight: FontWeight.w600)),
            if (structure.biome != null)
              Text(l10n.biomeLabel(structure.biome!),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.copy, size: 18, color: Colors.grey[400]),
          onPressed: () =>
              _copyCoordinates(context, structure.x, structure.y, structure.z),
          tooltip: l10n.copyCoordinates,
        ),
      ),
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
      case 'savanna':
        return '🦁';
      case 'badlands':
      case 'mesa':
        return '🏔️';
      case 'ocean':
        return '🌊';
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
}
