import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/ore_finder.dart';
import 'models/ore_location.dart';

void main() {
  runApp(const MinecraftOreFinderApp());
}

class MinecraftOreFinderApp extends StatelessWidget {
  const MinecraftOreFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minecraft Ore Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const OreFinderScreen(),
    );
  }
}

class OreFinderScreen extends StatefulWidget {
  const OreFinderScreen({super.key});

  @override
  State<OreFinderScreen> createState() => _OreFinderScreenState();
}

class _OreFinderScreenState extends State<OreFinderScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _seedController = TextEditingController(text: '8674308105921866736');
  final _xController = TextEditingController(text: '0');
  final _yController = TextEditingController(text: '-59');
  final _zController = TextEditingController(text: '0');
  final _radiusController = TextEditingController(text: '50');

  Set<OreType> _selectedOreTypes = {OreType.diamond};
  bool _includeNether = false;
  bool _isLoading = false;
  List<OreLocation> _results = [];
  bool _findAllNetherite = false;
  
  // Filter states
  Set<OreType> _visibleOreTypes = {OreType.diamond, OreType.gold, OreType.netherite};
  final _minXController = TextEditingController();
  final _maxXController = TextEditingController();
  final _minYController = TextEditingController();
  final _maxYController = TextEditingController();
  final _minZController = TextEditingController();
  final _maxZController = TextEditingController();
  bool _showFilters = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _seedController.dispose();
    _xController.dispose();
    _yController.dispose();
    _zController.dispose();
    _radiusController.dispose();
    _tabController.dispose();
    _minXController.dispose();
    _maxXController.dispose();
    _minYController.dispose();
    _maxYController.dispose();
    _minZController.dispose();
    _maxZController.dispose();
    super.dispose();
  }

  Future<void> _findOres(bool comprehensiveNetherite) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _results.clear();
      _findAllNetherite = comprehensiveNetherite;
    });

    try {
      final finder = OreFinder();
      List<OreLocation> allResults = [];

      if (comprehensiveNetherite) {
        // Comprehensive netherite search - ONLY search for netherite
        final results = await finder.findAllNetherite(
          seed: _seedController.text,
          centerX: int.parse(_xController.text),
          centerZ: int.parse(_zController.text),
        );
        allResults.addAll(results);
      } else {
        // Regular search for each selected ore type
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

      // Sort all results by probability
      allResults.sort((a, b) => b.probability.compareTo(a.probability));

      setState(() {
        // Show 150 locations by default, more for comprehensive netherite search
        int maxResults = comprehensiveNetherite 
            ? 200  // Even more for comprehensive search
            : 150; // Default 150 locations
        _results = allResults.take(maxResults).toList();
        _isLoading = false;
        
        // For comprehensive netherite search, ensure only netherite is visible in filters
        if (comprehensiveNetherite) {
          _visibleOreTypes = {OreType.netherite};
        }
      });

      // Auto-switch to results tab
      _tabController.animateTo(1);
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
      appBar: AppBar(
        title: const Text('Minecraft Ore Finder'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Find Ores'),
            Tab(icon: Icon(Icons.list), text: 'Results'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildResultsTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'World Settings',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _seedController,
                      decoration: const InputDecoration(
                        labelText: 'World Seed',
                        hintText: 'Enter your world seed',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.public),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a world seed';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Center',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _xController,
                            decoration: const InputDecoration(
                              labelText: 'X',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _yController,
                            decoration: const InputDecoration(
                              labelText: 'Y',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final y = int.tryParse(value);
                              if (y == null) {
                                return 'Invalid';
                              }
                              if (y < -64 || y > 320) {
                                return 'Y must be between -64 and 320';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _zController,
                            decoration: const InputDecoration(
                              labelText: 'Z',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _radiusController,
                      decoration: const InputDecoration(
                        labelText: 'Search Radius (blocks)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.radar),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter search radius';
                        }
                        final radius = int.tryParse(value);
                        if (radius == null || radius <= 0) {
                          return 'Radius must be a positive number';
                        }
                        if (radius > 2000) {
                          return 'Radius too large (max 2000)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ore Type',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<OreType>(
                            segments: const [
                              ButtonSegment<OreType>(
                                value: OreType.diamond,
                                label: Text('💎 Diamonds'),
                              ),
                              ButtonSegment<OreType>(
                                value: OreType.gold,
                                label: Text('🏅 Gold'),
                              ),
                            ],
                            selected: _selectedOreTypes.where((type) => type != OreType.netherite).toSet(),
                            multiSelectionEnabled: true,
                            onSelectionChanged: (Set<OreType> newSelection) {
                              setState(() {
                                // Keep netherite if it was selected, add/remove others
                                Set<OreType> updatedSelection = Set.from(newSelection);
                                if (_selectedOreTypes.contains(OreType.netherite)) {
                                  updatedSelection.add(OreType.netherite);
                                }
                                if (updatedSelection.isNotEmpty) {
                                  _selectedOreTypes = updatedSelection;
                                }
                              });
                            },
                            style: SegmentedButton.styleFrom(
                              minimumSize: const Size(120, 48),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                if (_selectedOreTypes.contains(OreType.netherite)) {
                                  _selectedOreTypes.remove(OreType.netherite);
                                } else {
                                  _selectedOreTypes.add(OreType.netherite);
                                }
                              });
                            },
                            icon: Icon(
                              _selectedOreTypes.contains(OreType.netherite) 
                                ? Icons.check_circle 
                                : Icons.local_fire_department,
                              color: _selectedOreTypes.contains(OreType.netherite) 
                                ? Colors.deepPurple 
                                : null,
                            ),
                            label: Text(
                              '🔥 Netherite (Ancient Debris)',
                              style: TextStyle(
                                color: _selectedOreTypes.contains(OreType.netherite) 
                                  ? Colors.deepPurple 
                                  : null,
                                fontWeight: _selectedOreTypes.contains(OreType.netherite) 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              side: BorderSide(
                                color: _selectedOreTypes.contains(OreType.netherite) 
                                  ? Colors.deepPurple 
                                  : Colors.grey,
                                width: _selectedOreTypes.contains(OreType.netherite) ? 2 : 1,
                              ),
                            ),
                          ),
                        ),
                        if (_selectedOreTypes.contains(OreType.netherite))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Nether only, Y 8-22 (very rare!)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.deepPurple,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getSearchDescription(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (_selectedOreTypes.contains(OreType.gold)) ...[
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Include Nether Gold'),
                        subtitle: const Text('Search for Nether Gold Ore'),
                        value: _includeNether,
                        onChanged: (bool? value) {
                          setState(() {
                            _includeNether = value ?? false;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Main search buttons
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _findOres(false),
                    icon: _isLoading && !_findAllNetherite
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(_isLoading && !_findAllNetherite ? 'Searching...' : 'Find Ores'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _findOres(true),
                    icon: _isLoading && _findAllNetherite
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.explore),
                    label: Text(
                      _isLoading && _findAllNetherite 
                        ? 'Searching All Netherite...' 
                        : 'Find ALL Netherite',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Info text for comprehensive search
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.deepPurple,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Comprehensive Netherite Search',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Searches entire world (4000x4000 blocks)\n• May take 30-60 seconds\n• Shows up to 200 netherite locations\n• Ignores other ore selections',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.deepPurple.withOpacity(0.8),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<OreLocation> get _filteredResults {
    return _results.where((location) {
      // Filter by ore type
      if (!_visibleOreTypes.contains(location.oreType)) {
        return false;
      }
      
      // Filter by coordinates
      if (_minXController.text.isNotEmpty) {
        final minX = int.tryParse(_minXController.text);
        if (minX != null && location.x < minX) return false;
      }
      
      if (_maxXController.text.isNotEmpty) {
        final maxX = int.tryParse(_maxXController.text);
        if (maxX != null && location.x > maxX) return false;
      }
      
      if (_minYController.text.isNotEmpty) {
        final minY = int.tryParse(_minYController.text);
        if (minY != null && location.y < minY) return false;
      }
      
      if (_maxYController.text.isNotEmpty) {
        final maxY = int.tryParse(_maxYController.text);
        if (maxY != null && location.y > maxY) return false;
      }
      
      if (_minZController.text.isNotEmpty) {
        final minZ = int.tryParse(_minZController.text);
        if (minZ != null && location.z < minZ) return false;
      }
      
      if (_maxZController.text.isNotEmpty) {
        final maxZ = int.tryParse(_maxZController.text);
        if (maxZ != null && location.z > maxZ) return false;
      }
      
      return true;
    }).toList();
  }

  Widget _buildResultsTab() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _findAllNetherite && _selectedOreTypes.contains(OreType.netherite)
                  ? 'Comprehensive netherite search in progress...'
                  : 'Analyzing world generation...',
            ),
            if (_findAllNetherite && _selectedOreTypes.contains(OreType.netherite)) ...[
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

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No results yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Use the search tab to find ores'),
          ],
        ),
      );
    }

    final filteredResults = _filteredResults;

    return Column(
      children: [
        // Filter Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show comprehensive search indicator
                  if (_findAllNetherite && _results.isNotEmpty && _results.first.oreType == OreType.netherite)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.explore, color: Colors.deepPurple, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Comprehensive Netherite Search Results',
                              style: TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Results: ${filteredResults.length} of ${_results.length}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                        tooltip: _showFilters ? 'Hide filters' : 'Show filters',
                      ),
                    ],
                  ),
                ],
              ),
              // Ore Type Filter (always visible)
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('💎 Diamonds'),
                    selected: _visibleOreTypes.contains(OreType.diamond),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _visibleOreTypes.add(OreType.diamond);
                        } else {
                          _visibleOreTypes.remove(OreType.diamond);
                        }
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('🏅 Gold'),
                    selected: _visibleOreTypes.contains(OreType.gold),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _visibleOreTypes.add(OreType.gold);
                        } else {
                          _visibleOreTypes.remove(OreType.gold);
                        }
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('🔥 Netherite'),
                    selected: _visibleOreTypes.contains(OreType.netherite),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _visibleOreTypes.add(OreType.netherite);
                        } else {
                          _visibleOreTypes.remove(OreType.netherite);
                        }
                      });
                    },
                  ),
                ],
              ),
              // Coordinate Filters (collapsible)
              if (_showFilters) ...[
                const SizedBox(height: 16),
                _buildCoordinateFilters(),
              ],
            ],
          ),
        ),
        // Results List
        Expanded(
          child: filteredResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_alt_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No results match filters',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text('Try adjusting your filter settings'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredResults.length,
                  itemBuilder: (context, index) {
                    final location = filteredResults[index];
                    final originalIndex = _results.indexOf(location) + 1;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getOreColor(location.oreType),
                          child: Text(
                            '$originalIndex',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              _getOreEmoji(location.oreType),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Coordinates: (${location.x}, ${location.y}, ${location.z})',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Chunk: (${location.chunkX}, ${location.chunkZ})'),
                            Text('Probability: ${(location.probability * 100).toStringAsFixed(1)}%'),
                            if (location.biome != null)
                              Text('Biome: ${location.biome}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copyCoordinates(location),
                          tooltip: 'Copy coordinates',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCoordinateFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coordinate Filters',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minXController,
                decoration: const InputDecoration(
                  labelText: 'Min X',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _maxXController,
                decoration: const InputDecoration(
                  labelText: 'Max X',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minYController,
                decoration: const InputDecoration(
                  labelText: 'Min Y',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _maxYController,
                decoration: const InputDecoration(
                  labelText: 'Max Y',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minZController,
                decoration: const InputDecoration(
                  labelText: 'Min Z',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _maxZController,
                decoration: const InputDecoration(
                  labelText: 'Max Z',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _minXController.clear();
                  _maxXController.clear();
                  _minYController.clear();
                  _maxYController.clear();
                  _minZController.clear();
                  _maxZController.clear();
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      ],
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

  IconData _getOreIcon(OreType oreType) {
    switch (oreType) {
      case OreType.diamond:
        return Icons.diamond;
      case OreType.gold:
        return Icons.star;
      case OreType.netherite:
        return Icons.local_fire_department;
    }
  }

  String _getOreEmoji(OreType oreType) {
    switch (oreType) {
      case OreType.diamond:
        return '💎';
      case OreType.gold:
        return '🏅';
      case OreType.netherite:
        return '🔥';
    }
  }

  String _getSearchDescription() {
    List<String> oreNames = [];
    if (_selectedOreTypes.contains(OreType.diamond)) oreNames.add('diamonds');
    if (_selectedOreTypes.contains(OreType.gold)) oreNames.add('gold');
    if (_selectedOreTypes.contains(OreType.netherite)) oreNames.add('netherite');
    
    if (oreNames.isEmpty) return 'No ores selected';
    if (oreNames.length == 1) return 'Searching for ${oreNames[0]} only';
    if (oreNames.length == 2) return 'Searching for ${oreNames[0]} and ${oreNames[1]}';
    return 'Searching for ${oreNames.sublist(0, oreNames.length - 1).join(', ')}, and ${oreNames.last}';
  }

  void _copyCoordinates(OreLocation location) {
    final coordinates = '${location.x} ${location.y} ${location.z}';
    Clipboard.setData(ClipboardData(text: coordinates));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied coordinates: $coordinates'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}