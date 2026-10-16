import 'game_random.dart';
import 'ore_location.dart';
import 'structure_location.dart';
import 'worldgen/minecraft_version.dart';
import 'worldgen/version_strategy_registry.dart';

/// Single source of truth for *what content exists* in a given Minecraft
/// [VersionEra] and [MinecraftEdition].
///
/// The search algorithm is a statistical simulation (see
/// SEED_ACCURATE_WORLDGEN_SPEC.md for the planned accurate rewrite), but the
/// one thing we can — and must — get right is not offering ores/structures
/// that do not exist in the version the user selected. Before this class the
/// UI happily let a user search "Legacy" (pre-1.18) worlds for Netherite,
/// Copper, Emerald from mountains, Ancient Cities, etc. — content introduced
/// in 1.16/1.17/1.19. That made the edition/version selectors misleading.
///
/// Keep this class pure (no Flutter imports) so it can run inside the search
/// isolate and be unit-tested in isolation.
class VersionAvailability {
  const VersionAvailability._();

  /// Whether [ore] can be searched for in the given era/edition.
  ///
  /// Legacy == pre-1.18. For the purposes of this app "legacy" collapses every
  /// pre-1.18 version into one bucket, so we gate on the broad introduction
  /// boundaries that matter most:
  ///   - Netherite (Ancient Debris): 1.16 (Nether Update) — NOT in legacy.
  ///   - Copper: 1.17 (Caves & Cliffs part 1) — NOT in legacy.
  ///   - Emerald: exists since 1.3, so available in both eras.
  static bool isOreAvailable(
    OreType ore, {
    required VersionEra era,
    required MinecraftEdition edition,
  }) {
    if (era == VersionEra.legacy) {
      switch (ore) {
        case OreType.netherite:
        case OreType.copper:
          // Introduced in 1.16 / 1.17 respectively — not present pre-1.18.
          return false;
        case OreType.diamond:
        case OreType.gold:
        case OreType.redstone:
        case OreType.iron:
        case OreType.coal:
        case OreType.lapis:
        case OreType.emerald:
          return true;
      }
    }
    // Modern (1.18+): everything is available.
    return true;
  }

  /// The set of ores that make sense to offer for this era/edition, preserving
  /// the canonical display order of [OreType.values].
  static List<OreType> availableOres({
    required VersionEra era,
    required MinecraftEdition edition,
  }) {
    return OreType.values
        .where((o) => isOreAvailable(o, era: era, edition: edition))
        .toList();
  }

  /// Whether [structure] can be searched for in the given era/edition.
  ///
  /// Structure introduction boundaries that fall on the legacy/modern split or
  /// later:
  ///   - Ancient City (deep dark): 1.19 — modern only.
  ///   - Bastion Remnant: 1.16 — modern only (legacy here == pre-1.18).
  ///   - Ruined Portal: 1.16 — modern only.
  ///   - Pillager Outpost: 1.14 — available in both.
  ///   - Abandoned Camp: Third Drop 2026 — modern only (newest content).
  /// Everything else (village, stronghold, end city, nether fortress, ocean
  /// monument, woodland mansion, shipwreck, buried treasure, temples, witch
  /// hut) predates 1.16 and is available in both eras.
  static bool isStructureAvailable(
    StructureType structure, {
    required VersionEra era,
    required MinecraftEdition edition,
  }) {
    if (era == VersionEra.legacy) {
      switch (structure) {
        case StructureType.ancientCity: // 1.19
        case StructureType.bastionRemnant: // 1.16
        case StructureType.ruinedPortal: // 1.16
        case StructureType.abandonedCamp: // Third Drop 2026
          return false;
        case StructureType.village:
        case StructureType.stronghold:
        case StructureType.endCity:
        case StructureType.netherFortress:
        case StructureType.oceanMonument:
        case StructureType.woodlandMansion:
        case StructureType.pillagerOutpost:
        case StructureType.shipwreck:
        case StructureType.buriedTreasure:
        case StructureType.desertTemple:
        case StructureType.jungleTemple:
        case StructureType.witchHut:
          return true;
      }
    }
    return true;
  }

  /// The set of structures available for this era/edition, preserving the
  /// canonical order of [StructureType.values].
  static List<StructureType> availableStructures({
    required VersionEra era,
    required MinecraftEdition edition,
  }) {
    return StructureType.values
        .where((s) => isStructureAvailable(s, era: era, edition: edition))
        .toList();
  }

  // -------------------------------------------------------------------------
  // Explicit version-list API (seed-accurate worldgen).
  //
  // The era-based methods above remain the single source of truth for the
  // Simulated path and the retained gating test. These additions expose the
  // explicit per-version list sourced from the [VersionStrategyRegistry] so
  // the Accurate-mode UI version picker and content gating stay consistent.
  // -------------------------------------------------------------------------

  /// All explicit versions the [registry] supports (a strategy is registered),
  /// optionally filtered by [edition].
  static List<MinecraftVersion> supportedVersions(
    VersionStrategyRegistry registry, {
    MinecraftEdition? edition,
  }) {
    if (edition == null) return registry.supportedVersions;
    return registry.supportedVersionsFor(edition);
  }

  /// The subset of [supportedVersions] whose golden fixtures have been
  /// verified.
  static List<MinecraftVersion> verifiedVersions(
    VersionStrategyRegistry registry, {
    MinecraftEdition? edition,
  }) {
    return supportedVersions(registry, edition: edition)
        .where(registry.isVerified)
        .toList();
  }
}
