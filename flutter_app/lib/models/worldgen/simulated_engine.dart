import '../ore_finder.dart';
import '../ore_location.dart';
import '../structure_finder.dart';
import '../structure_location.dart';
import 'worldgen_engine.dart';

/// [WorldGenEngine] adapter over the existing statistical finders.
///
/// This is the "Estimate" mode engine: it delegates directly to
/// [OreFinder]/[StructureFinder], mapping the explicit [MinecraftVersion] down
/// to the legacy [VersionEra] the finders understand, and always returns
/// [EngineOk] because the simulation supports any version.
///
/// Pure Dart (no Flutter imports) so it runs inside the `compute` isolate.
class SimulatedEngine implements WorldGenEngine {
  const SimulatedEngine({
    OreFinder? oreFinder,
    StructureFinder? structureFinder,
  })  : _oreFinder = oreFinder,
        _structureFinder = structureFinder;

  final OreFinder? _oreFinder;
  final StructureFinder? _structureFinder;

  OreFinder get _ores => _oreFinder ?? OreFinder();
  StructureFinder get _structures => _structureFinder ?? StructureFinder();

  @override
  Future<EngineResult<StructureLocation>> findStructures(
      StructureQuery q) async {
    final results = await _structures.findStructures(
      seed: q.seed,
      centerX: q.centerX,
      centerZ: q.centerZ,
      radius: q.radius,
      structureTypes: q.structureTypes,
      maxResults: q.maxResults,
      edition: q.edition,
      versionEra: q.version.era,
    );
    return EngineOk<StructureLocation>(results);
  }

  @override
  Future<EngineResult<OreLocation>> findOres(OreQuery q) async {
    final results = await _ores.findOres(
      seed: q.seed,
      centerX: q.centerX,
      centerY: q.centerY,
      centerZ: q.centerZ,
      radius: q.radius,
      oreType: q.oreType,
      includeNether: q.includeNether,
      edition: q.edition,
      versionEra: q.version.era,
      maxResults: q.maxResults,
    );
    return EngineOk<OreLocation>(results);
  }
}
