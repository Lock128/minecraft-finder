import 'package:flutter/foundation.dart';

import 'game_random.dart';
import 'ore_finder.dart';
import 'ore_location.dart';
import 'structure_finder.dart';
import 'structure_location.dart';

/// Runs the search algorithms on a background isolate via [compute] so the
/// heavy nested loops never block the UI thread. Keeping the work off the main
/// isolate is what lets the search spinner animate and the app stay responsive
/// while a search runs.
///
/// The param/result objects below only hold primitives, enums, and lists of
/// model objects (whose fields are primitives/enums/strings), so they are safe
/// to send across the isolate boundary.

/// Bundles a result list with the total number of qualifying candidates found
/// before the display cap was applied.
class SearchOutput<T> {
  const SearchOutput(this.results, this.totalFound);
  final List<T> results;
  final int totalFound;
}

// ---------------------------------------------------------------------------
// Ore search
// ---------------------------------------------------------------------------

class OreSearchParams {
  const OreSearchParams({
    required this.seed,
    required this.centerX,
    required this.centerY,
    required this.centerZ,
    required this.radius,
    required this.oreType,
    required this.includeNether,
    required this.edition,
    required this.versionEra,
    required this.maxResults,
  });

  final String seed;
  final int centerX;
  final int centerY;
  final int centerZ;
  final int radius;
  final OreType oreType;
  final bool includeNether;
  final MinecraftEdition edition;
  final VersionEra versionEra;
  final int maxResults;
}

class NetheriteSearchParams {
  const NetheriteSearchParams({
    required this.seed,
    required this.centerX,
    required this.centerZ,
    required this.edition,
    required this.versionEra,
    required this.maxResults,
  });

  final String seed;
  final int centerX;
  final int centerZ;
  final MinecraftEdition edition;
  final VersionEra versionEra;
  final int maxResults;
}

class StructureSearchParams {
  const StructureSearchParams({
    required this.seed,
    required this.centerX,
    required this.centerZ,
    required this.radius,
    required this.structureTypes,
    required this.maxResults,
  });

  final String seed;
  final int centerX;
  final int centerZ;
  final int radius;
  final Set<StructureType> structureTypes;
  final int maxResults;
}

// ---------------------------------------------------------------------------
// Top-level isolate entry points (required by compute()).
// ---------------------------------------------------------------------------

Future<SearchOutput<OreLocation>> _runOreSearch(OreSearchParams p) async {
  final finder = OreFinder();
  int total = 0;
  final results = await finder.findOres(
    seed: p.seed,
    centerX: p.centerX,
    centerY: p.centerY,
    centerZ: p.centerZ,
    radius: p.radius,
    oreType: p.oreType,
    includeNether: p.includeNether,
    edition: p.edition,
    versionEra: p.versionEra,
    maxResults: p.maxResults,
    onTotalFound: (n) => total += n,
  );
  return SearchOutput<OreLocation>(results, total);
}

Future<SearchOutput<OreLocation>> _runNetheriteSearch(
    NetheriteSearchParams p) async {
  final finder = OreFinder();
  int total = 0;
  final results = await finder.findAllNetherite(
    seed: p.seed,
    centerX: p.centerX,
    centerZ: p.centerZ,
    edition: p.edition,
    versionEra: p.versionEra,
    maxResults: p.maxResults,
    onTotalFound: (n) => total += n,
  );
  return SearchOutput<OreLocation>(results, total);
}

Future<SearchOutput<StructureLocation>> _runStructureSearch(
    StructureSearchParams p) async {
  final finder = StructureFinder();
  int total = 0;
  final results = await finder.findStructures(
    seed: p.seed,
    centerX: p.centerX,
    centerZ: p.centerZ,
    radius: p.radius,
    structureTypes: p.structureTypes,
    maxResults: p.maxResults,
    onTotalFound: (n) => total += n,
  );
  return SearchOutput<StructureLocation>(results, total);
}

/// Public helpers that dispatch each search to a background isolate.
class SearchRunner {
  const SearchRunner._();

  static Future<SearchOutput<OreLocation>> findOres(OreSearchParams params) {
    return compute(_runOreSearch, params);
  }

  static Future<SearchOutput<OreLocation>> findAllNetherite(
      NetheriteSearchParams params) {
    return compute(_runNetheriteSearch, params);
  }

  static Future<SearchOutput<StructureLocation>> findStructures(
      StructureSearchParams params) {
    return compute(_runStructureSearch, params);
  }
}
