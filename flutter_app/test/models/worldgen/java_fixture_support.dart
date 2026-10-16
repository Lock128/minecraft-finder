// Shared helpers for the Java golden-fixture and property suites: maps a
// fixture directory name to its VersionStrategy and parses the enum strings
// used in the fixture JSON.

import 'package:gem_ore_struct_finder_mc/models/ore_location.dart';
import 'package:gem_ore_struct_finder_mc/models/structure_location.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/java_version_strategy.dart';
import 'package:gem_ore_struct_finder_mc/models/worldgen/version_strategy.dart';

/// Resolve the concrete Java [VersionStrategy] for a fixture directory name
/// such as `java-1.20`. Returns null for non-Java directories.
VersionStrategy? strategyForDirectory(String directoryName) {
  switch (directoryName) {
    case 'java-1.18':
      return JavaVersionStrategy.java118();
    case 'java-1.19':
      return JavaVersionStrategy.java119();
    case 'java-1.20':
      return JavaVersionStrategy.java120();
    default:
      return null;
  }
}

/// Parse a [StructureType] from its `toString().split('.').last` form.
StructureType structureTypeFromString(String name) {
  return StructureType.values.firstWhere(
    (e) => e.toString().split('.').last == name,
    orElse: () => StructureType.village,
  );
}

/// Parse an [OreType] from its `toString().split('.').last` form.
OreType oreTypeFromString(String name) {
  return OreType.values.firstWhere(
    (e) => e.toString().split('.').last == name,
    orElse: () => OreType.diamond,
  );
}
