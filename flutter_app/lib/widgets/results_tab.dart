import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ore_location.dart';
import '../models/structure_location.dart';
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
  Set<OreType> _visibleOreTypes = {
    OreType.diamond,
    OreType.gold,
    OreType.netherite
  };
  Set<StructureType> _visibleStructures = {};
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
      return _passesCoordinateFilters(location.x, location.y, location.z);
    }).toList();
  }

  List<StructureLocation> get _filteredStructureResults {
    return widget.structureResults.where((location) {
      if (_visibleStructures.isNotEmpty &&
          !_visibleStructures.contains(location.structureType)) {
        return false;
      }
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

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingView();
    }

    if (widget.results.isEmpty && widget.structureResults.isEmpty) {
      return _buildEmptyView();
    }

    final filteredResults = _filteredResults;
    final filteredStructureResults = _filteredStructureResults;

    return Column(
      children: [
        _buildFilterHeader(filteredResults, filteredStructureResults),
        Expanded(
          child: (filteredResults.isEmpty && filteredStructureResults.isEmpty)
              ? _buildNoResultsView()
              : _buildResultsList(filteredResults, filteredStructureResults),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            widget.findAllNetherite &&
                    widget.selectedOreTypes.contains(OreType.netherite)
                ? 'Comprehensive netherite search in progress...'
                : 'Analyzing world generation...',
          ),
          if (widget.findAllNetherite &&
              widget.selectedOreTypes.contains(OreType.netherite)) ...[
            const SizedBox(height: 8),
            const Text(
              'This may take 30-60 seconds',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No results yet',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Use the search tab to find ores'),
        ],
      ),
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No results match filters',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Try adjusting your filter settings'),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(List<OreLocation> filteredResults,
      List<StructureLocation> filteredStructureResults) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
            bottom:
                BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      child: Column(
        children: [
          // Results count and filter toggle
          Row(
            children: [
              Expanded(
                child: Text(
                  'Results: ${filteredResults.length + filteredStructureResults.length} (${filteredResults.length} ores, ${filteredStructureResults.length} structures)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: Icon(
                    _showFilters ? Icons.filter_list_off : Icons.filter_list),
                onPressed: () => setState(() => _showFilters = !_showFilters),
                tooltip: _showFilters ? 'Hide filters' : 'Show filters',
              ),
            ],
          ),
          // Ore filters
          if (widget.results.isNotEmpty) _buildOreFilters(),
          // Structure filters
          if (widget.structureResults.isNotEmpty) _buildStructureFilters(),
          // Coordinate filters
          if (_showFilters) _buildCoordinateFilters(),
        ],
      ),
    );
  }

  Widget _buildOreFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text('Ore Filters:',
            style:
                Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12)),
        const SizedBox(height: 3),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _buildOreFilterChip(OreType.diamond, '💎 Diamonds'),
            _buildOreFilterChip(OreType.gold, '🏅 Gold'),
            _buildOreFilterChip(OreType.netherite, '🔥 Netherite'),
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

  Widget _buildStructureFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Structure Filters:',
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

  Widget _buildCoordinateFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Coordinate Filters',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        // X filters
        Row(
          children: [
            Expanded(child: _buildFilterField(_minXController, 'Min X')),
            const SizedBox(width: 8),
            Expanded(child: _buildFilterField(_maxXController, 'Max X')),
          ],
        ),
        const SizedBox(height: 8),
        // Y filters
        Row(
          children: [
            Expanded(child: _buildFilterField(_minYController, 'Min Y')),
            const SizedBox(width: 8),
            Expanded(child: _buildFilterField(_maxYController, 'Max Y')),
          ],
        ),
        const SizedBox(height: 8),
        // Z filters
        Row(
          children: [
            Expanded(child: _buildFilterField(_minZController, 'Min Z')),
            const SizedBox(width: 8),
            Expanded(child: _buildFilterField(_maxZController, 'Max Z')),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _clearFilters,
          icon: const Icon(Icons.clear),
          label: const Text('Clear Filters'),
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
          return _buildOreResultCard(filteredResults[index], index + 1);
        } else {
          final structureIndex = index - filteredResults.length;
          return _buildStructureResultCard(
              filteredStructureResults[structureIndex]);
        }
      },
    );
  }

  Widget _buildOreResultCard(OreLocation location, int originalIndex) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _getOreColor(location.oreType),
          radius: 16,
          child: Text(
            '$originalIndex',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
        title: Row(
          children: [
            Text(OreUtils.getOreEmoji(location.oreType),
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Coordinates: (${location.x}, ${location.y}, ${location.z})',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chunk: (${location.chunkX}, ${location.chunkZ})',
                style: const TextStyle(fontSize: 11)),
            Text(
                'Probability: ${(location.probability * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 11)),
            if (location.biome != null)
              Text('Biome: ${location.biome}',
                  style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () => _copyCoordinates(location.x, location.y, location.z),
          tooltip: 'Copy coordinates',
        ),
      ),
    );
  }

  Widget _buildStructureResultCard(StructureLocation structure) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: Colors.brown.withValues(alpha: 0.1),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: const CircleAvatar(
          backgroundColor: Colors.brown,
          radius: 16,
          child: Text('🏰', style: TextStyle(fontSize: 12)),
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
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chunk: (${structure.chunkX}, ${structure.chunkZ})',
                style: const TextStyle(fontSize: 11)),
            Text(
                'Probability: ${(structure.probability * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 11)),
            if (structure.biome != null)
              Text('Biome: ${structure.biome}',
                  style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () =>
              _copyCoordinates(structure.x, structure.y, structure.z),
          tooltip: 'Copy coordinates',
        ),
      ),
    );
  }

  Color _getOreColor(OreType oreType) {
    switch (oreType) {
      case OreType.diamond:
        return Colors.cyan;
      case OreType.gold:
        return Colors.amber;
      case OreType.netherite:
        return Colors.deepPurple;
    }
  }

  List<StructureType> _getUniqueStructureTypes() {
    return widget.structureResults.map((s) => s.structureType).toSet().toList();
  }

  void _copyCoordinates(int x, int y, int z) {
    final coordinates = '$x $y $z';
    Clipboard.setData(ClipboardData(text: coordinates));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied coordinates: $coordinates'),
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
    });
  }
}
