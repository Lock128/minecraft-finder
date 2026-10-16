import 'dart:convert';
import 'dart:io';

/// A single authoritative structure position in a golden fixture.
class FixtureStructure {
  const FixtureStructure({
    required this.structureType,
    required this.x,
    required this.y,
    required this.z,
    this.chunkX,
    this.chunkZ,
    this.biome,
  });

  final String structureType;
  final int x;
  final int y;
  final int z;
  final int? chunkX;
  final int? chunkZ;
  final String? biome;

  factory FixtureStructure.fromJson(Map<String, dynamic> json) {
    return FixtureStructure(
      structureType: json['structureType'] as String,
      x: json['x'] as int,
      y: json['y'] as int,
      z: json['z'] as int,
      chunkX: json['chunkX'] as int?,
      chunkZ: json['chunkZ'] as int?,
      biome: json['biome'] as String?,
    );
  }
}

/// A single biome sample at a world coordinate.
class FixtureBiomeSample {
  const FixtureBiomeSample({
    required this.x,
    required this.z,
    required this.biome,
  });

  final int x;
  final int z;
  final String biome;

  factory FixtureBiomeSample.fromJson(Map<String, dynamic> json) {
    return FixtureBiomeSample(
      x: json['x'] as int,
      z: json['z'] as int,
      biome: json['biome'] as String,
    );
  }
}

/// A single authoritative ore placement in a golden fixture.
class FixtureOre {
  const FixtureOre({
    required this.oreType,
    required this.x,
    required this.y,
    required this.z,
    required this.veinSize,
  });

  final String oreType;
  final int x;
  final int y;
  final int z;
  final int veinSize;

  factory FixtureOre.fromJson(Map<String, dynamic> json) {
    return FixtureOre(
      oreType: json['oreType'] as String,
      x: json['x'] as int,
      y: json['y'] as int,
      z: json['z'] as int,
      veinSize: json['veinSize'] as int,
    );
  }
}

/// A parsed golden-seed fixture pairing a seed with authoritative structure
/// positions, biome samples, and ore placements for one `(edition, version)`.
class WorldGenFixture {
  const WorldGenFixture({
    required this.directoryName,
    required this.edition,
    required this.version,
    required this.seed,
    required this.structures,
    required this.biomeSamples,
    required this.ores,
    this.source,
  });

  /// The `<edition>-<version>` directory name under `test/fixtures/worldgen/`.
  final String directoryName;
  final String edition;
  final String version;
  final String seed;
  final List<FixtureStructure> structures;
  final List<FixtureBiomeSample> biomeSamples;
  final List<FixtureOre> ores;

  /// Provenance marker: `"algorithm-derived"` for fixtures produced by the
  /// engine itself (pending authoritative native verification) or an
  /// externally-authoritative source (e.g. `"cubiomes"`/`"chunkbase"`). Null
  /// when unspecified.
  final String? source;

  /// Whether this fixture carries any authoritative reference data.
  bool get isNonEmpty =>
      structures.isNotEmpty || biomeSamples.isNotEmpty || ores.isNotEmpty;

  factory WorldGenFixture.fromJson(
      String directoryName, Map<String, dynamic> json) {
    return WorldGenFixture(
      directoryName: directoryName,
      edition: json['edition'] as String,
      version: json['version'] as String,
      seed: json['seed'] as String,
      source: json['source'] as String?,
      structures: ((json['structures'] as List<dynamic>?) ?? const [])
          .map((e) => FixtureStructure.fromJson(e as Map<String, dynamic>))
          .toList(),
      biomeSamples: ((json['biomeSamples'] as List<dynamic>?) ?? const [])
          .map((e) => FixtureBiomeSample.fromJson(e as Map<String, dynamic>))
          .toList(),
      ores: ((json['ores'] as List<dynamic>?) ?? const [])
          .map((e) => FixtureOre.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Discovers and loads the golden-seed fixtures under
/// `test/fixtures/worldgen/`.
class FixtureLoader {
  /// Root path of the worldgen fixtures, relative to the package root (where
  /// `flutter test` runs).
  static const String fixturesRoot = 'test/fixtures/worldgen';

  /// Returns every fixture directory (each one holds a `fixture.json`), sorted
  /// by name for deterministic ordering.
  static List<Directory> discoverDirectories() {
    final root = Directory(fixturesRoot);
    if (!root.existsSync()) return const [];
    final dirs = root
        .listSync()
        .whereType<Directory>()
        .where((d) => File('${d.path}/fixture.json').existsSync())
        .toList();
    dirs.sort((a, b) => a.path.compareTo(b.path));
    return dirs;
  }

  /// Loads and parses every discovered fixture.
  static List<WorldGenFixture> loadAll() {
    return discoverDirectories().map(loadDirectory).toList();
  }

  /// Loads a single fixture directory.
  static WorldGenFixture loadDirectory(Directory dir) {
    final file = File('${dir.path}/fixture.json');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final name = dir.path.split(Platform.pathSeparator).last;
    return WorldGenFixture.fromJson(name, json);
  }
}
