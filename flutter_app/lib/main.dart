import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/ore_finder.dart';
import 'models/ore_location.dart';
import 'models/structure_finder.dart';
import 'models/structure_location.dart';

void main() {
  runApp(const MinecraftOreFinderApp());
}

class MinecraftOreFinderApp extends StatefulWidget {
  const MinecraftOreFinderApp({super.key});

  @override
  State<MinecraftOreFinderApp> createState() => _MinecraftOreFinderAppState();
}

class _MinecraftOreFinderAppState extends State<MinecraftOreFinderApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minecraft Ore Finder',
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50), // Minecraft green
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF8BC34A),
          surface: const Color(0xFFF1F8E9),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: OreFinderScreen(onThemeToggle: _toggleTheme, isDarkMode: _isDarkMode),
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
  List<StructureLocation> _structureResults = [];
  bool _findAllNetherite = false;
  bool _isDarkMode = false;
  bool _includeStructures = false;
  Set<StructureType> _selectedStructures = {};
  bool _includeOres = true;
  
  // Filter states
  Set<OreType> _visibleOreTypes = {OreType.diamond, OreType.gold, OreType.netherite};
  Set<StructureType> _visibleStructures = {};
  bool _showStructures = true;
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
    _tabController = TabController(length: 3, vsync: this);
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
      _structureResults.clear();
      _findAllNetherite = comprehensiveNetherite;
    });

    try {
      final finder = OreFinder();
      final structureFinder = StructureFinder();
      List<OreLocation> allResults = [];

      // Only search for ores if ore search is enabled
      if (_includeOres) {
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
      }

      // Search for structures if enabled
      if (_includeStructures && _selectedStructures.isNotEmpty) {
        final structureResults = await structureFinder.findStructures(
          seed: _seedController.text,
          centerX: int.parse(_xController.text),
          centerZ: int.parse(_zController.text),
          radius: int.parse(_radiusController.text),
          structureTypes: _selectedStructures,
        );
        _structureResults.addAll(structureResults);
      }

      // Sort all results by probability
      allResults.sort((a, b) => b.probability.compareTo(a.probability));
      _structureResults.sort((a, b) => b.probability.compareTo(a.probability));

      setState(() {
        // Show 150 locations by default, more for comprehensive netherite search
        int maxResults = comprehensiveNetherite 
            ? 200  // Even more for comprehensive search
            : 150; // Default 150 locations
        _results = allResults.take(maxResults).toList();
        _structureResults = _structureResults.take(50).toList(); // Limit structures
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
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF8B4513), // Brown like dirt block
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF654321), width: 2),
              ),
              child: const Center(
                child: Text(
                  '⛏️',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Minecraft Ore Finder',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: widget.isDarkMode ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: widget.onThemeToggle,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  key: ValueKey(widget.isDarkMode),
                  color: Colors.white,
                ),
              ),
              tooltip: widget.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.search),
              text: 'Search',
            ),
            Tab(
              icon: Icon(Icons.inventory),
              text: 'Results',
            ),
            Tab(
              icon: Icon(Icons.info),
              text: 'How It Works',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildResultsTab(),
          _buildExplanationsTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isDarkMode 
            ? [
                const Color(0xFF1A237E), // Dark blue
                const Color(0xFF2E7D32), // Dark green
              ]
            : [
                const Color(0xFF87CEEB), // Sky blue
                const Color(0xFF98FB98), // Pale green
              ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: const Color(0xFF4CAF50), width: 2),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: widget.isDarkMode
                        ? [
                            const Color(0xFF2E2E2E),
                            const Color(0xFF1E1E1E),
                          ]
                        : [
                            Colors.white,
                            const Color(0xFFF1F8E9),
                          ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B4513),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Center(
                              child: Text('🌍', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'World Settings',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: const Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _seedController,
                      decoration: InputDecoration(
                        labelText: 'World Seed',
                        hintText: 'Enter your world seed',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xFF4CAF50)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: const Color(0xFF2E7D32), width: 2),
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B4513),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Center(
                            child: Text('🌱', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
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
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: const Color(0xFF4CAF50), width: 2),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      const Color(0xFFF1F8E9),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF795548),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Center(
                            child: Text('📍', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Search Center',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _xController,
                            decoration: InputDecoration(
                              labelText: 'X',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
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
                            decoration: InputDecoration(
                              labelText: 'Y',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
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
                            decoration: InputDecoration(
                              labelText: 'Z',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
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
                      decoration: InputDecoration(
                        labelText: 'Search Radius (blocks)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF607D8B),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Center(
                            child: Text('🔍', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
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
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: const Color(0xFF4CAF50), width: 2),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: widget.isDarkMode
                      ? [
                          const Color(0xFF2E2E2E),
                          const Color(0xFF1E1E1E),
                        ]
                      : [
                          Colors.white,
                          const Color(0xFFF1F8E9),
                        ],
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF9C27B0),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Center(
                            child: Text('💎', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ore Type',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: _includeOres
                          ? LinearGradient(
                              colors: [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
                            )
                          : null,
                        border: Border.all(
                          color: _includeOres 
                            ? const Color(0xFF4CAF50)
                            : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _includeOres = !_includeOres;
                          });
                        },
                        icon: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF9C27B0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Center(
                            child: Text('💎', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                        label: Text(
                          'Include Ores in Search',
                          style: TextStyle(
                            color: _includeOres 
                              ? Colors.white 
                              : const Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.transparent,
                          side: BorderSide.none,
                        ),
                      ),
                    ),
                    if (_includeOres) ...[
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<OreType>(
                            segments: [
                              ButtonSegment<OreType>(
                                value: OreType.diamond,
                                label: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('💎 Diamonds', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              ButtonSegment<OreType>(
                                value: OreType.gold,
                                label: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('🏅 Gold', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
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
                              backgroundColor: widget.isDarkMode ? const Color(0xFF2E2E2E) : Colors.white,
                              selectedBackgroundColor: const Color(0xFF4CAF50),
                              selectedForegroundColor: Colors.white,
                              side: BorderSide(color: const Color(0xFF4CAF50)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: _selectedOreTypes.contains(OreType.netherite)
                              ? LinearGradient(
                                  colors: [Colors.deepPurple, Colors.purple[700]!],
                                )
                              : null,
                            border: Border.all(
                              color: _selectedOreTypes.contains(OreType.netherite) 
                                ? Colors.deepPurple 
                                : Colors.grey,
                              width: 2,
                            ),
                          ),
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
                            icon: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C1810),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Center(
                                child: Text('🔥', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            label: Text(
                              'Netherite (Ancient Debris)',
                              style: TextStyle(
                                color: _selectedOreTypes.contains(OreType.netherite) 
                                  ? Colors.white 
                                  : Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.transparent,
                              side: BorderSide.none,
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
            ],
            const SizedBox(height: 16),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: const Color(0xFF4CAF50), width: 2),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: widget.isDarkMode
                      ? [
                          const Color(0xFF2E2E2E),
                          const Color(0xFF1E1E1E),
                        ]
                      : [
                          Colors.white,
                          const Color(0xFFF1F8E9),
                        ],
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B4513),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Center(
                            child: Text('🏰', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Structure Search',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: _includeStructures
                          ? LinearGradient(
                              colors: [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
                            )
                          : null,
                        border: Border.all(
                          color: _includeStructures 
                            ? const Color(0xFF4CAF50)
                            : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _includeStructures = !_includeStructures;
                          });
                        },
                        icon: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B4513),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Center(
                            child: Text('🏰', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                        label: Text(
                          'Include Structures in Search',
                          style: TextStyle(
                            color: _includeStructures 
                              ? Colors.white 
                              : const Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.transparent,
                          side: BorderSide.none,
                        ),
                      ),
                    ),
                    if (_includeStructures) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Select Structures to Find:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStructureSelection(),
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
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _findOres(false),
                      icon: _isLoading && !_findAllNetherite
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B4513),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Center(
                                child: Text('⛏️', style: TextStyle(fontSize: 10)),
                              ),
                            ),
                      label: Text(
                        _isLoading && !_findAllNetherite ? 'Searching...' : 'Find',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple, Colors.purple[800]!],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _findOres(true),
                      icon: _isLoading && _findAllNetherite
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C1810),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Center(
                                child: Text('🔥', style: TextStyle(fontSize: 10)),
                              ),
                            ),
                      label: Text(
                        _isLoading && _findAllNetherite 
                          ? 'Searching All Netherite...' 
                          : 'Find ALL Netherite',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        padding: const EdgeInsets.all(16),
                      ),
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

  List<StructureLocation> get _filteredStructureResults {
    return _structureResults.where((location) {
      // Filter by structure type
      // If _visibleStructures is empty, show all structures
      // If _visibleStructures has items, only show those structures
      if (_visibleStructures.isNotEmpty && !_visibleStructures.contains(location.structureType)) {
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
    final filteredResults = _filteredResults;
    final filteredStructureResults = _filteredStructureResults;
    
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
                          'Results: ${filteredResults.length + filteredStructureResults.length} (${filteredResults.length} ores, ${filteredStructureResults.length} structures)',
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
              // Ore Type Filter (only visible if ores were searched)
              if (_results.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Ore Filters:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
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
              ],
              // Structure Filters
              if (_structureResults.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Structure Filters:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _getUniqueStructureTypes().map((structureType) {
                    return FilterChip(
                      label: Text(
                        '${_getStructureEmoji(structureType)} ${_getStructureName(structureType)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      selected: _visibleStructures.isEmpty || _visibleStructures.contains(structureType),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            // If no specific filters, show all except the deselected ones
                            if (_visibleStructures.isEmpty) {
                              _visibleStructures = _getUniqueStructureTypes().toSet();
                            } else {
                              _visibleStructures.add(structureType);
                            }
                          } else {
                            // If no specific filters, create filter set excluding this one
                            if (_visibleStructures.isEmpty) {
                              _visibleStructures = _getUniqueStructureTypes().toSet();
                            }
                            _visibleStructures.remove(structureType);
                          }
                        });
                      },
                      selectedColor: Colors.brown.withOpacity(0.3),
                      checkmarkColor: Colors.brown[700],
                      backgroundColor: Colors.grey.withOpacity(0.1),
                      side: BorderSide(
                        color: _visibleStructures.isEmpty || _visibleStructures.contains(structureType)
                          ? Colors.brown
                          : Colors.grey,
                        width: 1,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _visibleStructures.clear(); // Show all structures
                        });
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Show All'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.brown,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _visibleStructures = _getUniqueStructureTypes().toSet(); // Hide all structures
                        });
                      },
                      icon: const Icon(Icons.visibility_off, size: 16),
                      label: const Text('Hide All'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.brown,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
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
          child: (filteredResults.isEmpty && filteredStructureResults.isEmpty)
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
                  itemCount: filteredResults.length + filteredStructureResults.length,
                  itemBuilder: (context, index) {
                    if (index < filteredResults.length) {
                      // Ore result
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
                    } else {
                      // Structure result
                      final structureIndex = index - filteredResults.length;
                      final structure = filteredStructureResults[structureIndex];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Colors.brown.withOpacity(0.1),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.brown,
                            child: Text(
                              '🏰',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                _getStructureEmoji(structure.structureType),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_getStructureName(structure.structureType)}: (${structure.x}, ${structure.y}, ${structure.z})',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Chunk: (${structure.chunkX}, ${structure.chunkZ})'),
                              Text('Probability: ${(structure.probability * 100).toStringAsFixed(1)}%'),
                              if (structure.biome != null)
                                Text('Biome: ${structure.biome}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () => _copyStructureCoordinates(structure),
                            tooltip: 'Copy coordinates',
                          ),
                        ),
                      );
                    }
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
    List<String> searchItems = [];
    
    // Add ore types if ore search is enabled
    if (_includeOres) {
      if (_selectedOreTypes.contains(OreType.diamond)) searchItems.add('diamonds');
      if (_selectedOreTypes.contains(OreType.gold)) searchItems.add('gold');
      if (_selectedOreTypes.contains(OreType.netherite)) searchItems.add('netherite');
    }
    
    // Add structure info if structure search is enabled
    if (_includeStructures) {
      if (_selectedStructures.isEmpty) {
        searchItems.add('all structures');
      } else {
        searchItems.add('${_selectedStructures.length} structure types');
      }
    }
    
    if (searchItems.isEmpty) return 'No search items selected';
    if (searchItems.length == 1) return 'Searching for ${searchItems[0]} only';
    if (searchItems.length == 2) return 'Searching for ${searchItems[0]} and ${searchItems[1]}';
    return 'Searching for ${searchItems.sublist(0, searchItems.length - 1).join(', ')}, and ${searchItems.last}';
  }

  Widget _buildExplanationsTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isDarkMode 
            ? [
                const Color(0xFF1A237E), // Dark blue
                const Color(0xFF2E7D32), // Dark green
              ]
            : [
                const Color(0xFF87CEEB), // Sky blue
                const Color(0xFF98FB98), // Pale green
              ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildExplanationCard(
              title: '💎 Diamond Generation',
              icon: '💎',
              iconColor: Colors.cyan,
              content: [
                'Diamonds spawn in the Overworld between Y -64 and Y 16.',
                '',
                '🎯 Optimal Y Levels:',
                '• Y -64 to -54: Peak diamond layer (80% base probability)',
                '• Y -53 to -48: Good diamond layer (60% base probability)',
                '• Y -47 to -32: Decent diamond layer (40% base probability)',
                '• Y -31 to 16: Lower diamond layer (20% base probability)',
                '',
                '⚙️ Algorithm Factors:',
                '• Chunk-based randomness using world seed',
                '• Coordinate-based variation patterns',
                '• Simulated ore vein generation',
                '• Linear Congruential Generator for predictability',
                '',
                '📊 Probability Calculation:',
                'Final probability = Base probability × (0.5 + random factors)',
                'Random factors include chunk seed, coordinate position, and vein patterns.',
              ],
            ),
            const SizedBox(height: 16),
            _buildExplanationCard(
              title: '🏅 Gold Generation',
              icon: '🏅',
              iconColor: Colors.amber,
              content: [
                'Gold has different generation patterns based on biome and dimension.',
                '',
                '🌍 Overworld Gold (Y -64 to 32):',
                '• Y -47 to -16: Peak gold layer (60% base probability)',
                '• Y -64 to -48: Lower levels (40% base probability)',
                '• Y -15 to 32: Higher levels (30% base probability)',
                '',
                '🏜️ Badlands/Mesa Biome (BONUS!):',
                '• Y 32 to 80: Excellent surface gold (90% base probability)',
                '• Y -64 to 31: Good underground gold (70% base probability)',
                '• Y 81 to 256: Surface gold (50% base probability)',
                '• 6x more gold than regular biomes!',
                '',
                '🔥 Nether Gold Ore (Y 10 to 117):',
                '• Spawns throughout middle Nether layers',
                '• High probability (80% base probability)',
                '• Different ore type (Nether Gold Ore)',
                '',
                '🎲 Biome Detection:',
                'Algorithm simulates biome generation using chunk-based randomness.',
                '~5% of areas are classified as Badlands for bonus gold rates.',
              ],
            ),
            const SizedBox(height: 16),
            _buildExplanationCard(
              title: '🔥 Netherite (Ancient Debris)',
              icon: '🔥',
              iconColor: Colors.deepPurple,
              content: [
                'Ancient Debris is the rarest ore, found only in the Nether.',
                '',
                '🎯 Nether Y Levels (Y 8 to 22):',
                '• Y 13 to 17: Peak ancient debris layer (90% base probability)',
                '• Y 10 to 19: Good ancient debris layer (70% base probability)',
                '• Y 8 to 22: Decent ancient debris layer (50% base probability)',
                '',
                '⚠️ Rarity Multiplier:',
                'Final probability is multiplied by 0.8 to reflect extreme rarity.',
                'This makes Ancient Debris much harder to find than other ores.',
                '',
                '🔍 Search Modes:',
                '• Regular Search: Uses minimum 15% probability threshold',
                '• Comprehensive Search: Uses 5% threshold, covers 4000x4000 blocks',
                '• Searches every Y level from 8-22 with 1-block precision',
                '',
                '🧮 Special Algorithm:',
                '• Always treats coordinates as Nether biome',
                '• Uses smaller search steps for maximum coverage',
                '• Focuses on chunk-center coordinates for efficiency',
                '',
                '💡 Mining Tips:',
                '• Ancient Debris is blast-resistant',
                '• Use beds or TNT for efficient mining',
                '• 4 Ancient Debris + 4 Gold Ingots = 1 Netherite Ingot',
              ],
            ),
            const SizedBox(height: 16),
            _buildExplanationCard(
              title: '🔬 Technical Details',
              icon: '⚙️',
              iconColor: Colors.blueGrey,
              content: [
                'Understanding the algorithm behind ore prediction.',
                '',
                '🌱 Seed Processing:',
                '• String seeds converted to numeric using hash function',
                '• Numeric seeds used directly',
                '• Same seed always produces same results',
                '',
                '🎲 Random Number Generation:',
                '• Linear Congruential Generator (LCG) for predictability',
                '• Formula: (seed × 1664525 + 1013904223) mod 2³²',
                '• Chunk-based seeding for spatial consistency',
                '',
                '📐 Coordinate System:',
                '• Chunks are 16×16 block areas',
                '• Algorithm samples every 8 blocks for performance',
                '• Netherite uses 1-block precision for accuracy',
                '',
                '🧮 Probability Factors:',
                '1. Base probability by Y level and ore type',
                '2. Chunk-based randomness (30% weight)',
                '3. Coordinate-based randomness (20% weight)',
                '4. Simulated vein patterns (30% weight)',
                '5. Biome multipliers (Badlands bonus)',
                '',
                '⚡ Performance Optimizations:',
                '• Async processing prevents UI blocking',
                '• Progress updates every 100 chunks',
                '• Result limiting to prevent memory issues',
                '• Efficient chunk-based sampling',
                '',
                '🎯 Accuracy Notes:',
                'This is a simulation based on known Minecraft mechanics.',
                'Actual results may vary due to:',
                '• Cave generation interference',
                '• Structure placement conflicts',
                '• Version-specific generation changes',
              ],
            ),
            const SizedBox(height: 16),
            _buildExplanationCard(
              title: '📊 Probability Guide',
              icon: '📈',
              iconColor: Colors.green,
              content: [
                'Understanding what the probability percentages mean.',
                '',
                '🎯 Probability Ranges:',
                '• 90-100%: Extremely likely to find ore',
                '• 70-89%: Very high chance',
                '• 50-69%: Good chance',
                '• 30-49%: Moderate chance',
                '• 15-29%: Lower chance but worth checking',
                '• Below 15%: Filtered out (except comprehensive search)',
                '',
                '💡 Interpretation Tips:',
                '• Higher percentages = better mining spots',
                '• Focus on top 10-20 results for efficiency',
                '• Multiple nearby locations = potential vein area',
                '• Consider travel distance vs probability',
                '',
                '⛏️ Mining Strategy:',
                '1. Start with highest probability locations',
                '2. Create branch mines connecting multiple spots',
                '3. Use coordinates as starting points, not exact locations',
                '4. Explore surrounding areas once you find ore',
                '',
                '🔍 Search Tips:',
                '• Larger radius = more options but longer search time',
                '• Center search around your base or current location',
                '• Use filters to focus on specific coordinate ranges',
                '• Comprehensive netherite search for complete coverage',
              ],
            ),
            const SizedBox(height: 16),
            _buildExplanationCard(
              title: '🏰 Structure Generation',
              icon: '🏰',
              iconColor: Colors.brown,
              content: [
                'Structures are generated based on biome compatibility and rarity patterns.',
                '',
                '🏘️ Common Structures (High Spawn Rate):',
                '• Villages: Plains, desert, savanna, taiga biomes',
                '• Pillager Outposts: Same biomes as villages',
                '• Ruined Portals: Can spawn in any dimension',
                '• Shipwrecks: Ocean biomes and beaches',
                '',
                '🏛️ Rare Structures (Low Spawn Rate):',
                '• Strongholds: Underground, only 128 per world',
                '• End Cities: End dimension outer islands',
                '• Ocean Monuments: Deep ocean biomes',
                '• Ancient Cities: Deep dark biome (Y -52)',
                '• Woodland Mansions: Dark forest biomes',
                '',
                '🔥 Nether Structures:',
                '• Nether Fortresses: Nether wastes and soul sand valleys',
                '• Bastion Remnants: All nether biomes except basalt deltas',
                '',
                '🎲 Generation Algorithm:',
                '• Biome-specific spawning rules',
                '• Chunk-based probability calculations',
                '• Distance-based rarity adjustments',
                '• Dimension-aware coordinate mapping',
                '',
                '📊 Structure Probability Factors:',
                '1. Base rarity (varies by structure type)',
                '2. Biome compatibility (must match requirements)',
                '3. Chunk-based randomness using world seed',
                '4. Coordinate-based variation patterns',
                '5. Distance from world spawn (some structures)',
                '',
                '🔍 Search Optimization:',
                '• Samples every 4 chunks (64 blocks) for efficiency',
                '• Filters by biome compatibility first',
                '• Uses structure-specific Y levels',
                '• Combines multiple structure types in one search',
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isDarkMode 
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isDarkMode 
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: Colors.blue,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pro Tip',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This tool provides statistical predictions based on Minecraft\'s generation algorithms. '
                    'Use the coordinates as starting points for your mining expeditions, and always explore '
                    'the surrounding areas once you find ore veins!',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard({
    required String title,
    required String icon,
    required Color iconColor,
    required List<String> content,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: iconColor.withOpacity(0.3), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: widget.isDarkMode
              ? [
                  const Color(0xFF2E2E2E),
                  const Color(0xFF1E1E1E),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8F9FA),
                ],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: iconColor.withOpacity(0.5)),
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...content.map((line) {
              if (line.isEmpty) {
                return const SizedBox(height: 8);
              } else if (line.startsWith('🎯') || line.startsWith('⚙️') || 
                        line.startsWith('📊') || line.startsWith('🌍') ||
                        line.startsWith('🏜️') || line.startsWith('🔥') ||
                        line.startsWith('🎲') || line.startsWith('⚠️') ||
                        line.startsWith('🔍') || line.startsWith('🧮') ||
                        line.startsWith('💡') || line.startsWith('🌱') ||
                        line.startsWith('📐') || line.startsWith('⚡') ||
                        line.startsWith('💎') || line.startsWith('⛏️')) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(
                    line,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    line,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                  ),
                );
              }
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStructureSelection() {
    final structures = [
      {'type': StructureType.village, 'name': '🏘️ Village', 'rarity': 'Common'},
      {'type': StructureType.stronghold, 'name': '🏛️ Stronghold', 'rarity': 'Rare'},
      {'type': StructureType.endCity, 'name': '🌃 End City', 'rarity': 'Rare'},
      {'type': StructureType.netherFortress, 'name': '🏰 Nether Fortress', 'rarity': 'Uncommon'},
      {'type': StructureType.bastionRemnant, 'name': '🏯 Bastion Remnant', 'rarity': 'Uncommon'},
      {'type': StructureType.ancientCity, 'name': '🏛️ Ancient City', 'rarity': 'Very Rare'},
      {'type': StructureType.oceanMonument, 'name': '🌊 Ocean Monument', 'rarity': 'Rare'},
      {'type': StructureType.woodlandMansion, 'name': '🏚️ Woodland Mansion', 'rarity': 'Very Rare'},
      {'type': StructureType.pillagerOutpost, 'name': '🗼 Pillager Outpost', 'rarity': 'Common'},
      {'type': StructureType.ruinedPortal, 'name': '🌀 Ruined Portal', 'rarity': 'Very Common'},
      {'type': StructureType.shipwreck, 'name': '🚢 Shipwreck', 'rarity': 'Common'},
      {'type': StructureType.buriedTreasure, 'name': '💰 Buried Treasure', 'rarity': 'Uncommon'},
      {'type': StructureType.desertTemple, 'name': '🏜️ Desert Temple', 'rarity': 'Uncommon'},
      {'type': StructureType.jungleTemple, 'name': '🌿 Jungle Temple', 'rarity': 'Rare'},
      {'type': StructureType.witchHut, 'name': '🧙 Witch Hut', 'rarity': 'Rare'},
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedStructures = structures.map((s) => s['type'] as StructureType).toSet();
                  });
                },
                child: const Text('Select All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedStructures.clear();
                  });
                },
                child: const Text('Clear All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: structures.map((structure) {
                final structureType = structure['type'] as StructureType;
                final isSelected = _selectedStructures.contains(structureType);
                
                return FilterChip(
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        structure['name'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        structure['rarity'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getRarityColor(structure['rarity'] as String),
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedStructures.add(structureType);
                      } else {
                        _selectedStructures.remove(structureType);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF4CAF50).withOpacity(0.3),
                  checkmarkColor: const Color(0xFF2E7D32),
                );
              }).toList(),
            ),
          ),
        ),
        if (_selectedStructures.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${_selectedStructures.length} structures selected',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'Very Common':
        return Colors.green;
      case 'Common':
        return Colors.lightGreen;
      case 'Uncommon':
        return Colors.orange;
      case 'Rare':
        return Colors.red;
      case 'Very Rare':
        return Colors.purple;
      default:
        return Colors.grey;
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

  String _getStructureEmoji(StructureType structureType) {
    switch (structureType) {
      case StructureType.village:
        return '🏘️';
      case StructureType.stronghold:
        return '🏛️';
      case StructureType.endCity:
        return '🌃';
      case StructureType.netherFortress:
        return '🏰';
      case StructureType.bastionRemnant:
        return '🏯';
      case StructureType.ancientCity:
        return '🏛️';
      case StructureType.oceanMonument:
        return '🌊';
      case StructureType.woodlandMansion:
        return '🏚️';
      case StructureType.pillagerOutpost:
        return '🗼';
      case StructureType.ruinedPortal:
        return '🌀';
      case StructureType.shipwreck:
        return '🚢';
      case StructureType.buriedTreasure:
        return '💰';
      case StructureType.desertTemple:
        return '🏜️';
      case StructureType.jungleTemple:
        return '🌿';
      case StructureType.witchHut:
        return '🧙';
    }
  }

  String _getStructureName(StructureType structureType) {
    switch (structureType) {
      case StructureType.village:
        return 'Village';
      case StructureType.stronghold:
        return 'Stronghold';
      case StructureType.endCity:
        return 'End City';
      case StructureType.netherFortress:
        return 'Nether Fortress';
      case StructureType.bastionRemnant:
        return 'Bastion Remnant';
      case StructureType.ancientCity:
        return 'Ancient City';
      case StructureType.oceanMonument:
        return 'Ocean Monument';
      case StructureType.woodlandMansion:
        return 'Woodland Mansion';
      case StructureType.pillagerOutpost:
        return 'Pillager Outpost';
      case StructureType.ruinedPortal:
        return 'Ruined Portal';
      case StructureType.shipwreck:
        return 'Shipwreck';
      case StructureType.buriedTreasure:
        return 'Buried Treasure';
      case StructureType.desertTemple:
        return 'Desert Temple';
      case StructureType.jungleTemple:
        return 'Jungle Temple';
      case StructureType.witchHut:
        return 'Witch Hut';
    }
  }

  List<StructureType> _getUniqueStructureTypes() {
    return _structureResults.map((s) => s.structureType).toSet().toList();
  }

  void _copyStructureCoordinates(StructureLocation location) {
    final coordinates = '${location.x} ${location.y} ${location.z}';
    Clipboard.setData(ClipboardData(text: coordinates));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied structure coordinates: $coordinates'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}