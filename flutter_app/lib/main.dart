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
  final _seedController = TextEditingController();
  final _xController = TextEditingController(text: '0');
  final _yController = TextEditingController(text: '-59');
  final _zController = TextEditingController(text: '0');
  final _radiusController = TextEditingController(text: '300');

  OreType _selectedOreType = OreType.diamond;
  bool _includeNether = false;
  bool _isLoading = false;
  List<OreLocation> _results = [];

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
      final results = await finder.findOres(
        seed: _seedController.text,
        centerX: int.parse(_xController.text),
        centerY: int.parse(_yController.text),
        centerZ: int.parse(_zController.text),
        radius: int.parse(_radiusController.text),
        oreType: _selectedOreType,
        includeNether: _includeNether,
      );

      setState(() {
        _results = results.take(10).toList();
        _isLoading = false;
      });
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
                    SegmentedButton<OreType>(
                      segments: const [
                        ButtonSegment<OreType>(
                          value: OreType.diamond,
                          label: Text('💎 Diamonds'),
                          icon: Icon(Icons.diamond),
                        ),
                        ButtonSegment<OreType>(
                          value: OreType.gold,
                          label: Text('🏅 Gold'),
                          icon: Icon(Icons.star),
                        ),
                      ],
                      selected: {_selectedOreType},
                      onSelectionChanged: (Set<OreType> newSelection) {
                        setState(() {
                          _selectedOreType = newSelection.first;
                        });
                      },
                    ),
                    if (_selectedOreType == OreType.gold) ...[
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final location = _results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getOreColor(location.oreType),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              'Coordinates: (${location.x}, ${location.y}, ${location.z})',
              style: const TextStyle(fontWeight: FontWeight.bold),
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