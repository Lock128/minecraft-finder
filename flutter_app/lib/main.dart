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
  
  // Filter states
  Set<OreType> _visibleOreTypes = {OreType.diamond, OreType.gold};
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

  Future<void> _findOres() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _results.clear();
    });

    try {
      final finder = OreFinder();
      List<OreLocation> allResults = [];

      // Search for each selected ore type
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

      // Sort all results by probability
      allResults.sort((a, b) => b.probability.compareTo(a.probability));

      setState(() {
        _results = allResults.take(15 * _selectedOreTypes.length).toList();
        _isLoading = false;
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
                        if (radius > 1000) {
                          return 'Radius too large (max 1000)';
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
                        selected: _selectedOreTypes,
                        multiSelectionEnabled: true,
                        onSelectionChanged: (Set<OreType> newSelection) {
                          setState(() {
                            if (newSelection.isNotEmpty) {
                              _selectedOreTypes = newSelection;
                            }
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          minimumSize: const Size(120, 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedOreTypes.length == 2 
                        ? 'Searching for both diamonds and gold'
                        : _selectedOreTypes.contains(OreType.diamond)
                          ? 'Searching for diamonds only'
                          : 'Searching for gold only',
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
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _findOres,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(_isLoading ? 'Searching...' : 'Find Ores'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing world generation...'),
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
              // Ore Type Filter (always visible)
              const SizedBox(height: 8),
              SegmentedButton<OreType>(
                segments: const [
                  ButtonSegment<OreType>(
                    value: OreType.diamond,
                    label: Text('💎'),
                    tooltip: 'Show/Hide Diamonds',
                  ),
                  ButtonSegment<OreType>(
                    value: OreType.gold,
                    label: Text('🏅'),
                    tooltip: 'Show/Hide Gold',
                  ),
                ],
                selected: _visibleOreTypes,
                multiSelectionEnabled: true,
                onSelectionChanged: (Set<OreType> newSelection) {
                  setState(() {
                    if (newSelection.isNotEmpty) {
                      _visibleOreTypes = newSelection;
                    }
                  });
                },
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
    }
  }

  IconData _getOreIcon(OreType oreType) {
    switch (oreType) {
      case OreType.diamond:
        return Icons.diamond;
      case OreType.gold:
        return Icons.star;
    }
  }

  String _getOreEmoji(OreType oreType) {
    switch (oreType) {
      case OreType.diamond:
        return '💎';
      case OreType.gold:
        return '🏅';
    }
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