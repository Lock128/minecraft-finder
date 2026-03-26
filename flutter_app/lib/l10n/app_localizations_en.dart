// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Gem, Ore & Struct Finder';

  @override
  String get appTitleFull =>
      'Gem, Ore & Struct Finder for MC - Find Diamonds, Gold, Netherite & More';

  @override
  String get searchTab => 'Search';

  @override
  String get resultsTab => 'Results';

  @override
  String get guideTab => 'User Guide';

  @override
  String get bedwarsTab => 'Bedwars';

  @override
  String get updatesTab => 'Updates';

  @override
  String get appInfoTooltip => 'App Info';

  @override
  String get lightThemeTooltip => 'Light';

  @override
  String get darkThemeTooltip => 'Dark';

  @override
  String get languageTooltip => 'Language';

  @override
  String get errorEnableSearchType =>
      'Please enable at least one search type (Ores or Structures)';

  @override
  String get errorSelectStructure =>
      'Please select at least one structure type to search for';

  @override
  String get errorSelectOre =>
      'Please select at least one ore type to search for';

  @override
  String errorGeneric(String message) {
    return 'Error: $message';
  }

  @override
  String get worldSettingsTitle => 'World Settings';

  @override
  String get worldSeedLabel => 'World Seed';

  @override
  String get worldSeedHint => 'Enter your world seed';

  @override
  String get errorEmptySeed => 'Please enter a world seed';

  @override
  String get recentSeeds => 'Recent Seeds';

  @override
  String get searchCenterTitle => 'Search Center';

  @override
  String get coordinateX => 'X';

  @override
  String get coordinateY => 'Y';

  @override
  String get coordinateZ => 'Z';

  @override
  String get searchRadiusLabel => 'Search Radius (blocks)';

  @override
  String get errorEmptyRadius => 'Please enter search radius';

  @override
  String get errorRadiusPositive => 'Radius must be positive';

  @override
  String get errorRadiusMax => 'Max 2000';

  @override
  String get errorFieldRequired => 'Required';

  @override
  String get errorFieldInvalid => 'Invalid';

  @override
  String get errorYRange => '-64 to 320';

  @override
  String get togglePlusMinus => 'Toggle +/-';

  @override
  String get oreTypeTitle => 'Ore Type';

  @override
  String get includeOresInSearch => 'Include Ores in Search';

  @override
  String get includeNetherGold => 'Include Nether Gold';

  @override
  String get searchForNetherGold => 'Search for Nether Gold Ore';

  @override
  String get netheriteAncientDebris => 'Netherite (Ancient Debris)';

  @override
  String get legendDiamond => '💎 Diamond';

  @override
  String get legendGold => '🏅 Gold';

  @override
  String get legendIron => '⚪ Iron';

  @override
  String get legendRedstone => '🔴 Redstone';

  @override
  String get legendCoal => '⚫ Coal';

  @override
  String get legendLapis => '🔵 Lapis';

  @override
  String get structureSearchTitle => 'Structure Search';

  @override
  String get includeStructuresInSearch => 'Include Structures in Search';

  @override
  String get selectStructuresToFind => 'Select Structures to Find:';

  @override
  String get selectAll => 'Select All';

  @override
  String get clearAll => 'Clear All';

  @override
  String structuresSelected(int count) {
    return '$count structures selected';
  }

  @override
  String get findButton => 'Find';

  @override
  String get findAllNetheriteButton => 'Find All Netherite';

  @override
  String get searchingButton => 'Searching...';

  @override
  String get comprehensiveNetheriteSearch => 'Comprehensive Netherite Search';

  @override
  String get comprehensiveNetheriteBody =>
      '• Searches entire world (4000×4000 blocks)\n• May take 30-60 seconds\n• Shows up to 300 best locations\n• Ignores other ore selections';

  @override
  String get regularSearchInfo =>
      'Regular search shows top 250 results (all types combined)';

  @override
  String get loadingNetherite =>
      'Comprehensive netherite search in progress...';

  @override
  String get loadingAnalyzing => 'Analyzing world generation...';

  @override
  String get loadingTimeMay => 'This may take 30-60 seconds';

  @override
  String get noResultsYet => 'No results yet';

  @override
  String get useSearchTabToFind => 'Use the search tab to find ores';

  @override
  String get noResultsMatchFilters => 'No results match filters';

  @override
  String get tryAdjustingFilters => 'Try adjusting your filter settings';

  @override
  String resultsCount(int total, int oreCount, int structureCount) {
    return '$total results  ·  $oreCount ores  ·  $structureCount structures';
  }

  @override
  String get hideFilters => 'Hide filters';

  @override
  String get showFilters => 'Show filters';

  @override
  String get oreFiltersLabel => 'Ore Filters:';

  @override
  String get filterDiamonds => '💎 Diamonds';

  @override
  String get filterGold => '🏅 Gold';

  @override
  String get filterIron => '⚪ Iron';

  @override
  String get filterRedstone => '🔴 Redstone';

  @override
  String get filterCoal => '⚫ Coal';

  @override
  String get filterLapis => '🔵 Lapis';

  @override
  String get filterNetherite => '🔥 Netherite';

  @override
  String get structureFiltersLabel => 'Structure Filters:';

  @override
  String get biomeFiltersLabel => 'Biome Filters:';

  @override
  String get coordinateFiltersTitle => 'Coordinate Filters';

  @override
  String get minX => 'Min X';

  @override
  String get maxX => 'Max X';

  @override
  String get minY => 'Min Y';

  @override
  String get maxY => 'Max Y';

  @override
  String get minZ => 'Min Z';

  @override
  String get maxZ => 'Max Z';

  @override
  String get clearAllFilters => 'Clear All Filters';

  @override
  String get copyCoordinates => 'Copy coordinates';

  @override
  String copiedCoordinates(String coords) {
    return 'Copied coordinates: $coords';
  }

  @override
  String chunkLabel(int chunkX, int chunkZ) {
    return 'Chunk: ($chunkX, $chunkZ)';
  }

  @override
  String probabilityLabel(String percent) {
    return 'Probability: $percent%';
  }

  @override
  String biomeLabel(String biome) {
    return 'Biome: $biome';
  }

  @override
  String get guideDiamondTitle => 'Diamond Generation';

  @override
  String get guideDiamondIntro =>
      'Diamonds spawn in the Overworld between Y -64 and Y 16.';

  @override
  String get guideDiamondOptimal => '🎯 Optimal Y Levels:';

  @override
  String get guideDiamondLevel1 =>
      '• Y -64 to -54: Peak diamond layer (80% base probability)';

  @override
  String get guideDiamondLevel2 =>
      '• Y -53 to -48: Good diamond layer (60% base probability)';

  @override
  String get guideDiamondLevel3 =>
      '• Y -47 to -32: Decent diamond layer (40% base probability)';

  @override
  String get guideDiamondLevel4 =>
      '• Y -31 to 16: Lower diamond layer (20% base probability)';

  @override
  String get guideGoldTitle => 'Gold Generation';

  @override
  String get guideGoldIntro =>
      'Gold has different generation patterns based on biome and dimension.';

  @override
  String get guideGoldOverworld => '🌍 Overworld Gold (Y -64 to 32):';

  @override
  String get guideGoldLevel1 =>
      '• Y -47 to -16: Peak gold layer (60% base probability)';

  @override
  String get guideGoldLevel2 =>
      '• Y -64 to -48: Lower levels (40% base probability)';

  @override
  String get guideGoldLevel3 =>
      '• Y -15 to 32: Higher levels (30% base probability)';

  @override
  String get guideGoldBadlands => '🏜️ Badlands/Mesa Biome (BONUS!):';

  @override
  String get guideGoldBadlandsLevel =>
      '• Y 32 to 80: Excellent surface gold (90% base probability)';

  @override
  String get guideGoldBadlandsBonus => '• 6x more gold than regular biomes!';

  @override
  String get guideNetheriteTitle => 'Netherite (Ancient Debris)';

  @override
  String get guideNetheriteIntro =>
      'Ancient Debris is the rarest ore, found only in the Nether.';

  @override
  String get guideNetheriteOptimal => '🎯 Nether Y Levels (Y 8 to 22):';

  @override
  String get guideNetheriteLevel1 =>
      '• Y 13 to 17: Peak ancient debris layer (90% base probability)';

  @override
  String get guideNetheriteLevel2 =>
      '• Y 10 to 19: Good ancient debris layer (70% base probability)';

  @override
  String get guideNetheriteLevel3 =>
      '• Y 8 to 22: Decent ancient debris layer (50% base probability)';

  @override
  String get guideNetheriteSearch => '🔍 Search Modes:';

  @override
  String get guideNetheriteRegular =>
      '• Regular Search: Uses minimum 15% probability threshold';

  @override
  String get guideNetheriteComprehensive =>
      '• Comprehensive Search: Uses 5% threshold, covers 4000x4000 blocks';

  @override
  String get guideIronTitle => 'Iron Generation';

  @override
  String get guideIronIntro =>
      'Iron is one of the most versatile and common ores.';

  @override
  String get guideIronOptimal => '🎯 Optimal Y Levels:';

  @override
  String get guideIronLevel1 =>
      '• Y 128 to 256: Mountain iron generation (peaks at Y 232)';

  @override
  String get guideIronLevel2 =>
      '• Y -24 to 56: Underground iron generation (peaks at Y 15)';

  @override
  String get guideIronLevel3 =>
      '• Y -64 to 72: General iron availability (40% base probability)';

  @override
  String get guideRedstoneTitle => 'Redstone Generation';

  @override
  String get guideRedstoneIntro =>
      'Redstone is the key to automation and complex contraptions.';

  @override
  String get guideRedstoneOptimal => '🎯 Optimal Y Levels (Y -64 to 15):';

  @override
  String get guideRedstoneLevel1 =>
      '• Y -64 to -59: Peak redstone layer (90% base probability)';

  @override
  String get guideRedstoneLevel2 =>
      '• Y -58 to -48: Good redstone layer (70% base probability)';

  @override
  String get guideRedstoneLevel3 =>
      '• Y -47 to -32: Decent redstone layer (50% base probability)';

  @override
  String get guideRedstoneLevel4 =>
      '• Y -31 to 15: Lower redstone layer (30% base probability)';

  @override
  String get guideCoalTitle => 'Coal Generation';

  @override
  String get guideCoalIntro =>
      'Coal is the most common ore and primary fuel source.';

  @override
  String get guideCoalOptimal => '🎯 Optimal Y Levels (Y 0 to 256):';

  @override
  String get guideCoalLevel1 =>
      '• Y 80 to 136: Peak coal generation (peaks at Y 96)';

  @override
  String get guideCoalLevel2 =>
      '• Y 0 to 256: General coal availability (60% base probability)';

  @override
  String get guideLapisTitle => 'Lapis Lazuli Generation';

  @override
  String get guideLapisIntro =>
      'Lapis Lazuli spawns in the Overworld between Y -64 and Y 64.';

  @override
  String get guideLapisOptimal => '🎯 Optimal Y Levels:';

  @override
  String get guideLapisLevel1 =>
      '• Y 0 to 32: Peak lapis layer (enhanced generation)';

  @override
  String get guideLapisLevel2 =>
      '• Y -64 to -1: Lower levels (standard generation)';

  @override
  String get guideLapisLevel3 =>
      '• Y 33 to 64: Higher levels (reduced generation)';

  @override
  String get guideStructureTitle => 'Structure Generation';

  @override
  String get guideStructureIntro =>
      'Structures are generated based on biome compatibility and rarity.';

  @override
  String get guideStructureCommon => '🏘️ Common Structures (High Spawn Rate):';

  @override
  String get guideStructureVillages =>
      '• Villages: Plains, desert, savanna, taiga biomes';

  @override
  String get guideStructureOutposts =>
      '• Pillager Outposts: Same biomes as villages';

  @override
  String get guideStructurePortals =>
      '• Ruined Portals: Can spawn in any dimension';

  @override
  String get guideStructureRare => '🏛️ Rare Structures (Low Spawn Rate):';

  @override
  String get guideStructureStrongholds =>
      '• Strongholds: Underground, only 128 per world';

  @override
  String get guideStructureEndCities =>
      '• End Cities: End dimension outer islands';

  @override
  String get guideStructureMonuments => '• Ocean Monuments: Deep ocean biomes';

  @override
  String get guideStructureAncientCities =>
      '• Ancient Cities: Deep dark biome (Y -52)';

  @override
  String get proTipTitle => 'Pro Tip';

  @override
  String get proTipBody =>
      'This tool provides statistical predictions based on block game generation algorithms. Use the coordinates as starting points for your mining expeditions, and always explore the surrounding areas once you find ore veins!';

  @override
  String get bedwarsTierStarters => 'Starters';

  @override
  String get bedwarsTierPractitioners => 'Practitioners';

  @override
  String get bedwarsTierExperts => 'Experts';

  @override
  String get bedwarsGameObjectiveTitle => 'Game Objective & Rules';

  @override
  String get bedwarsGameObjective1 =>
      'Protect your bed while trying to destroy enemy beds.';

  @override
  String get bedwarsGameObjective2 =>
      'Once your bed is destroyed, you can no longer respawn.';

  @override
  String get bedwarsGameObjective3 =>
      'The last team with a surviving player wins the game.';

  @override
  String get bedwarsGameObjective4 =>
      'Collect resources from generators to buy gear and blocks.';

  @override
  String get bedwarsResourceGatheringTitle => 'Basic Resource Gathering';

  @override
  String get bedwarsResourceGathering1 =>
      'Iron and gold spawn automatically at your island generator.';

  @override
  String get bedwarsResourceGathering2 =>
      'Stay near your generator between fights to collect resources.';

  @override
  String get bedwarsResourceGathering3 =>
      'Iron is used for basic blocks and tools from the shop.';

  @override
  String get bedwarsResourceGathering4 =>
      'Gold buys stronger armor, weapons, and utility items.';

  @override
  String get bedwarsPurchasingTitle => 'Purchasing Essential Items';

  @override
  String get bedwarsPurchasing1 =>
      'Buy wool or endstone early for bridging and bed defense.';

  @override
  String get bedwarsPurchasing2 =>
      'A stone sword is a cheap early upgrade over the wooden one.';

  @override
  String get bedwarsPurchasing3 =>
      'Iron armor gives a solid defense boost for the first fights.';

  @override
  String get bedwarsPurchasing4 =>
      'Pick up shears to cut through wool defenses quickly.';

  @override
  String get bedwarsBedDefenseTitle => 'Basic Bed Defense';

  @override
  String get bedwarsBedDefense1 =>
      'Cover your bed with wool as soon as the game starts.';

  @override
  String get bedwarsBedDefense2 =>
      'Add a second layer of endstone around the wool for extra protection.';

  @override
  String get bedwarsBedDefense3 =>
      'Never leave your bed completely unguarded in the early game.';

  @override
  String get bedwarsBedDefense4 =>
      'Place blocks on all sides including the top of the bed.';

  @override
  String get bedwarsCombatTipsTitle => 'Basic Combat Tips';

  @override
  String get bedwarsCombatTips1 =>
      'Always sprint before hitting an opponent for extra knockback.';

  @override
  String get bedwarsCombatTips2 =>
      'Block-hit by alternating attack and block to reduce damage taken.';

  @override
  String get bedwarsCombatTips3 =>
      'Aim for critical hits by attacking while falling from a jump.';

  @override
  String get bedwarsCombatTips4 =>
      'Avoid fighting on narrow bridges where knockback is deadly.';

  @override
  String get bedwarsResourceManagementTitle =>
      'Efficient Resource Management & Upgrades';

  @override
  String get bedwarsResourceManagement1 =>
      'Visit diamond and emerald generators on the center islands regularly.';

  @override
  String get bedwarsResourceManagement2 =>
      'Prioritize team upgrades like sharpness, protection, and forge upgrades.';

  @override
  String get bedwarsResourceManagement3 =>
      'Split resource collection duties with teammates for faster progression.';

  @override
  String get bedwarsResourceManagement4 =>
      'Save emeralds for powerful items like diamond armor or ender pearls.';

  @override
  String get bedwarsIntermediateDefenseTitle => 'Intermediate Bed Defense';

  @override
  String get bedwarsIntermediateDefense1 =>
      'Layer your bed defense: wool inside, endstone middle, wood or glass outside.';

  @override
  String get bedwarsIntermediateDefense2 =>
      'Use blast-proof glass to counter TNT attacks on your bed.';

  @override
  String get bedwarsIntermediateDefense3 =>
      'Add water buckets near your bed to slow down attackers.';

  @override
  String get bedwarsIntermediateDefense4 =>
      'Consider placing obsidian as the innermost layer for maximum durability.';

  @override
  String get bedwarsTeamCoordinationTitle => 'Team Coordination Strategies';

  @override
  String get bedwarsTeamCoordination1 =>
      'Assign roles: one player defends while others rush or gather resources.';

  @override
  String get bedwarsTeamCoordination2 =>
      'Communicate enemy positions and incoming attacks to your team.';

  @override
  String get bedwarsTeamCoordination3 =>
      'Coordinate simultaneous attacks on enemy bases for maximum pressure.';

  @override
  String get bedwarsTeamCoordination4 =>
      'Share resources with teammates who need specific upgrades.';

  @override
  String get bedwarsBridgeBuildingTitle => 'Bridge-Building Techniques';

  @override
  String get bedwarsBridgeBuilding1 =>
      'Practice speed-bridging by shifting at the edge and placing blocks quickly.';

  @override
  String get bedwarsBridgeBuilding2 =>
      'Build bridges with slight zigzag patterns to avoid easy bow shots.';

  @override
  String get bedwarsBridgeBuilding3 =>
      'Use blocks that are hard to break like endstone for permanent bridges.';

  @override
  String get bedwarsBridgeBuilding4 =>
      'Always carry enough blocks before starting a bridge to an enemy island.';

  @override
  String get bedwarsMidGameCombatTitle => 'Mid-Game Combat Tactics';

  @override
  String get bedwarsMidGameCombat1 =>
      'Use knockback sticks to push enemies off bridges and islands.';

  @override
  String get bedwarsMidGameCombat2 =>
      'Carry a bow for ranged pressure while approaching enemy bases.';

  @override
  String get bedwarsMidGameCombat3 =>
      'Use fireballs to blast through defenses and knock players into the void.';

  @override
  String get bedwarsMidGameCombat4 =>
      'Always eat a golden apple before engaging in a tough fight.';

  @override
  String get bedwarsAdvancedPvpTitle => 'Advanced PvP Combat';

  @override
  String get bedwarsAdvancedPvp1 =>
      'Master W-tap combos by releasing and re-pressing forward between hits.';

  @override
  String get bedwarsAdvancedPvp2 =>
      'Use fishing rods to pull enemies closer and reset their sprint.';

  @override
  String get bedwarsAdvancedPvp3 =>
      'Strafe in unpredictable patterns to make yourself harder to hit.';

  @override
  String get bedwarsAdvancedPvp4 =>
      'Combine rod pulls with immediate sword swings for devastating combos.';

  @override
  String get bedwarsSpeedBridgingTitle => 'Speed-Bridging & Advanced Movement';

  @override
  String get bedwarsSpeedBridging1 =>
      'Learn ninja-bridging to place blocks while moving forward without shifting.';

  @override
  String get bedwarsSpeedBridging2 =>
      'Practice breezily bridging for the fastest straight-line bridge speed.';

  @override
  String get bedwarsSpeedBridging3 =>
      'Use block clutches to save yourself from falling into the void.';

  @override
  String get bedwarsSpeedBridging4 =>
      'Master jump-bridging to cover gaps quickly during rushes.';

  @override
  String get bedwarsRushStrategiesTitle => 'Rush Strategies & Timing';

  @override
  String get bedwarsRushStrategies1 =>
      'Rush the nearest enemy base within the first 30 seconds for an early advantage.';

  @override
  String get bedwarsRushStrategies2 =>
      'Buy TNT and a pickaxe for a fast bed break on defended bases.';

  @override
  String get bedwarsRushStrategies3 =>
      'Time your rushes when enemies leave their base to gather resources.';

  @override
  String get bedwarsRushStrategies4 =>
      'Use invisibility potions for surprise attacks on well-defended beds.';

  @override
  String get bedwarsEndgameTitle => 'Endgame Tactics & Resource Prioritization';

  @override
  String get bedwarsEndgame1 =>
      'Stockpile ender pearls for quick escapes and surprise engagements.';

  @override
  String get bedwarsEndgame2 =>
      'Prioritize diamond armor and sharpness upgrades for final fights.';

  @override
  String get bedwarsEndgame3 =>
      'Control the center map generators to deny resources to remaining teams.';

  @override
  String get bedwarsEndgame4 =>
      'Keep emergency blocks and golden apples ready for clutch moments.';

  @override
  String get bedwarsCounterStrategiesTitle =>
      'Counter-Strategies Against Common Plays';

  @override
  String get bedwarsCounterStrategies1 =>
      'Counter bridge rushers by placing void traps or using bows at range.';

  @override
  String get bedwarsCounterStrategies2 =>
      'Against TNT attacks, use blast-proof glass and obsidian layers.';

  @override
  String get bedwarsCounterStrategies3 =>
      'Counter invisible players by watching for armor particles and footstep sounds.';

  @override
  String get bedwarsCounterStrategies4 =>
      'Against fireball spam, carry a water bucket to extinguish fires and block knockback.';

  @override
  String get aboutTitle => 'About Gem, Ore & Struct Finder';

  @override
  String get aboutWhatTitle => '🎯 What This App Does';

  @override
  String get aboutDescTitle => 'Advanced Minecraft Ore & Structure Discovery';

  @override
  String get aboutDescBody =>
      'Enter your world seed and search coordinates to discover exact locations of diamonds, gold, netherite, villages, strongholds, and more.';

  @override
  String get aboutResourcesTitle => '⛏️ Supported Resources';

  @override
  String get aboutStructuresTitle => '🏘️ Supported Structures';

  @override
  String get aboutHowItWorksTitle => '🔍 How It Works';

  @override
  String get aboutFeaturesTitle => '✨ Key Features';

  @override
  String get aboutSupportTitle => '☕ Support Development';

  @override
  String get aboutResourceDiamond => 'Diamond';

  @override
  String get aboutResourceGold => 'Gold';

  @override
  String get aboutResourceNetherite => 'Netherite';

  @override
  String get aboutResourceIron => 'Iron';

  @override
  String get aboutResourceRedstone => 'Redstone';

  @override
  String get aboutResourceCoal => 'Coal';

  @override
  String get aboutResourceLapis => 'Lapis';

  @override
  String get aboutStructureVillages => 'Villages 🏘️';

  @override
  String get aboutStructureStrongholds => 'Strongholds 🏰';

  @override
  String get aboutStructureDungeons => 'Dungeons 🕳️';

  @override
  String get aboutStructureMineshafts => 'Mineshafts ⛏️';

  @override
  String get aboutStructureDesertTemples => 'Desert Temples 🏜️';

  @override
  String get aboutStructureJungleTemples => 'Jungle Temples 🌿';

  @override
  String get aboutStructureOceanMonuments => 'Ocean Monuments 🌊';

  @override
  String get aboutStructureWoodlandMansions => 'Woodland Mansions 🏚️';

  @override
  String get aboutStructurePillagerOutposts => 'Pillager Outposts ⚔️';

  @override
  String get aboutStructureRuinedPortals => 'Ruined Portals 🌀';

  @override
  String get aboutStep1 => 'Enter your world seed in the Search tab';

  @override
  String get aboutStep2 => 'Set your search center coordinates (X, Y, Z)';

  @override
  String get aboutStep3 => 'Choose your search radius';

  @override
  String get aboutStep4 => 'Select which ores and structures to find';

  @override
  String get aboutStep5 => 'Tap \"Find\" to discover nearby resources';

  @override
  String get aboutStep6 => 'View results with exact coordinates';

  @override
  String get aboutFeature1 =>
      'Recent Seeds History — Quick access to last 5 seeds';

  @override
  String get aboutFeature2 =>
      'Auto Parameter Saving — Never lose search settings';

  @override
  String get aboutFeature3 =>
      'Probability Results — Find the most likely locations';

  @override
  String get aboutFeature4 => 'Cross-Platform — Web, mobile, and desktop';

  @override
  String get aboutFeature5 => 'Dark/Light Theme — Choose your vibe';

  @override
  String get aboutBuyMeCoffee => 'Buy Me a Coffee';

  @override
  String get aboutSupportBody =>
      'Help keep this app free and improving! Your support enables new features and ongoing development.';

  @override
  String get aboutSupportButton => 'Support Development';

  @override
  String get aboutFooterTip =>
      'Use Recent Seeds to quickly switch between worlds!';

  @override
  String get aboutGotIt => 'Got it!';

  @override
  String get releaseNotesHeader => 'Release Notes — v1.0.50';

  @override
  String get releaseNotesBedwarsSection => '🎮 Bedwars Strategy Guide — NEW!';

  @override
  String get releaseNotesBedwarsGuideTitle => 'Complete Bedwars Guide';

  @override
  String get releaseNotesBedwarsGuideBody =>
      'A dedicated tab with in-depth strategies for Bedwars. Covers early game rushing, mid game defense, and late game tactics to help you dominate every match.';

  @override
  String get releaseNotesResourceStrategiesTitle =>
      'Resource & Shop Strategies';

  @override
  String get releaseNotesResourceStrategiesBody =>
      'Detailed breakdowns of resource priorities, optimal shop purchases at every stage, and team coordination tips for 2s, 3s, and 4s modes.';

  @override
  String get releaseNotesDefenseAttackTitle => 'Defense & Attack Patterns';

  @override
  String get releaseNotesDefenseAttackBody =>
      'Learn bed defense layouts, bridge rushing techniques, fireball strategies, and how to counter common enemy tactics.';

  @override
  String get releaseNotesUiSection => '🎨 Modern Gamer UI Overhaul';

  @override
  String get releaseNotesNeonTitle => 'Neon Gamer Aesthetic';

  @override
  String get releaseNotesNeonBody =>
      'Complete visual redesign with a neon-on-dark color palette. Vibrant green, cyan, and purple accents with subtle glow effects for a modern gaming feel.';

  @override
  String get releaseNotesLightModeTitle => 'Improved Light Mode';

  @override
  String get releaseNotesLightModeBody =>
      'Fully readable light theme with darker accent variants. Every text element now meets contrast requirements on both light and dark backgrounds.';

  @override
  String get releaseNotesCardsTitle => 'Redesigned Cards & Buttons';

  @override
  String get releaseNotesCardsBody =>
      'Flat cards with neon border accents, gradient action buttons with glow shadows, and a cleaner tab bar with neon indicators replace the old Material green theme.';

  @override
  String get releaseNotesAlgorithmSection =>
      '⛏️ Ore Finding Algorithm Improvements';

  @override
  String get releaseNotesNoiseTitle => 'Enhanced Noise Generation';

  @override
  String get releaseNotesNoiseBody =>
      'Improved Perlin noise implementation for more accurate ore probability calculations that better match actual in-game world generation patterns.';

  @override
  String get releaseNotesBiomeTitle => 'Better Biome Awareness';

  @override
  String get releaseNotesBiomeBody =>
      'Refined biome detection and ore distribution modeling. Gold in badlands, diamonds at deep levels, and netherite in the nether are all more precisely predicted.';

  @override
  String get releaseNotesPerformanceTitle => 'Optimized Search Performance';

  @override
  String get releaseNotesPerformanceBody =>
      'Faster search execution with improved chunk scanning. Comprehensive netherite search and large-radius queries complete more efficiently.';

  @override
  String get releaseNotesHighlightsSection => '🎯 Highlights';

  @override
  String get releaseNotesHighlight1 =>
      'Bedwars Guide: Full strategy guide with early/mid/late game tactics';

  @override
  String get releaseNotesHighlight2 =>
      'Gamer UI: Neon accents, glow effects, and modern dark theme';

  @override
  String get releaseNotesHighlight3 =>
      'Light Mode Fix: All text now readable on light backgrounds';

  @override
  String get releaseNotesHighlight4 =>
      'Better Ore Finding: More accurate predictions across all ore types';

  @override
  String get releaseNotesHighlight5 =>
      'Faster Searches: Optimized algorithms for quicker results';

  @override
  String get releaseNotesHighlight6 =>
      '5-Tab Layout: Search, Results, Guide, Bedwars, and Updates';

  @override
  String get releaseNotesTechnicalSection => '🔧 Technical Improvements';

  @override
  String get releaseNotesTechnical1 =>
      'Centralized theme system with adaptive light/dark color helpers';

  @override
  String get releaseNotesTechnical2 =>
      'Reusable GamerCard and GamerSectionHeader components';

  @override
  String get releaseNotesTechnical3 =>
      'Improved Perlin noise for ore generation modeling';

  @override
  String get releaseNotesTechnical4 =>
      'Better chunk-level probability calculations';

  @override
  String get releaseNotesTechnical5 =>
      'Reduced widget rebuilds for smoother scrolling';

  @override
  String get releaseNotesPreviousSection => '📋 Previous Updates';

  @override
  String get releaseNotesV1042Title => 'v1.0.42 — Lapis Lazuli + UI';

  @override
  String get releaseNotesV1042Body =>
      'Added Lapis Lazuli ore finding. All 7 major ores supported. Enhanced 4-tab navigation layout.';

  @override
  String get releaseNotesV1041Title => 'v1.0.41 — Recent Seeds History';

  @override
  String get releaseNotesV1041Body =>
      'Automatic seed history with quick access to last 5 seeds.';

  @override
  String get releaseNotesV1036Title => 'v1.0.36 — Complete Search Memory';

  @override
  String get releaseNotesV1036Body =>
      'Comprehensive search parameter persistence.';

  @override
  String get releaseNotesV1027Title => 'v1.0.27 — Visual Improvements';

  @override
  String get releaseNotesV1027Body => 'Updated splash screen and icons.';

  @override
  String get releaseNotesV1022Title => 'v1.0.22 — Extended Ore Discovery';

  @override
  String get releaseNotesV1022Body =>
      'Added Iron, Redstone, Coal, and Lapis Lazuli.';

  @override
  String get releaseNotesV1015Title => 'v1.0.15 — Structure Discovery';

  @override
  String get releaseNotesV1015Body =>
      'Villages, strongholds, dungeons, temples, and more.';

  @override
  String get releaseNotesV1010Title => 'v1.0.10 — Foundation Release';

  @override
  String get releaseNotesV1010Body =>
      'Core diamond, gold, and netherite finding.';

  @override
  String get releaseNotesTimelineSection => '🏆 Version Timeline';

  @override
  String get releaseNotesTimelineCurrent => 'Current';

  @override
  String get releaseNotesTimelinePrevious => 'Previous';

  @override
  String get releaseNotesTimelineEarlier => 'Earlier';

  @override
  String get releaseNotesTimelineBedwarsUi => 'Bedwars + UI';

  @override
  String get releaseNotesTimelineLapisUi => 'Lapis + UI';

  @override
  String get releaseNotesTimelineRecentSeeds => 'Recent Seeds';

  @override
  String get releaseNotesTimelineSearchMemory => 'Search Memory';

  @override
  String get releaseNotesTimelineVisualUpdates => 'Visual Updates';

  @override
  String get releaseNotesTimelineExtendedOres => 'Extended Ores';

  @override
  String get releaseNotesTimelineStructures => 'Structures';

  @override
  String get releaseNotesTimelineCoreFeatures => 'Core Features';

  @override
  String get releaseNotesFooter =>
      'New: Bedwars guide, gamer UI, and improved ore finding!';

  @override
  String get dialogReleaseNotesHeader => 'Release Notes - Version 1.0.41';

  @override
  String get dialogRecentSeedsSection => '🌱 Recent Seeds History - NEW!';

  @override
  String get dialogQuickSeedAccessTitle => 'Quick Seed Access';

  @override
  String get dialogQuickSeedAccessBody =>
      'Never lose track of your favorite world seeds! The app now automatically saves your last 5 searched seeds and displays them as clickable options below the seed input field. Simply tap any recent seed to instantly use it again.';

  @override
  String get dialogSmartSeedTitle => 'Smart Seed Management';

  @override
  String get dialogSmartSeedBody =>
      'Recent seeds are automatically managed - when you search a seed again, it moves to the top of the list. The oldest seed is automatically removed when you reach the 5-seed limit. All seed digits are fully visible with improved monospace formatting for better readability.';

  @override
  String get dialogEnhancedUxTitle => 'Enhanced User Experience';

  @override
  String get dialogEnhancedUxBody =>
      'Perfect for players who test multiple seeds or return to favorite worlds. No more manually typing long seed numbers - just click and search! Seeds persist across app sessions, so your history is always available.';

  @override
  String get dialogSearchMemorySection => '💾 Complete Search Memory Feature';

  @override
  String get dialogAutoSaveTitle => 'Automatic Parameter Saving';

  @override
  String get dialogAutoSaveBody =>
      'The app remembers ALL your search parameters including world seed, X/Y/Z coordinates, and search radius. Everything is automatically saved when you type and restored when you restart the app.';

  @override
  String get dialogSeamlessTitle => 'Seamless Workflow';

  @override
  String get dialogSeamlessBody =>
      'Continue your ore hunting sessions exactly where you left off. No more re-entering coordinates or adjusting search settings. Focus on finding ores instead of configuring search settings!';

  @override
  String get dialogEnhancedUxSection => '🎯 Enhanced User Experience';

  @override
  String get dialogUxBullet1 =>
      'Recent Seeds: Quick access to your last 5 searched world seeds';

  @override
  String get dialogUxBullet2 =>
      'Time Saving: Eliminates the need to remember and re-enter search parameters';

  @override
  String get dialogUxBullet3 =>
      'Better Productivity: Focus purely on ore discovery';

  @override
  String get dialogUxBullet4 =>
      'Cross-Platform: Works consistently across all supported platforms';

  @override
  String get dialogUxBullet5 =>
      'Smart Defaults: Falls back to sensible defaults for new users';

  @override
  String get dialogUxBullet6 =>
      'Improved Readability: Monospace font for better seed number visibility';

  @override
  String get dialogTechSection => '🔧 Technical Improvements';

  @override
  String get dialogTechBullet1 =>
      'Recent Seeds Storage: Persistent seed history with automatic management';

  @override
  String get dialogTechBullet2 =>
      'Offline Font Support: Improved performance without internet connection';

  @override
  String get dialogTechBullet3 =>
      'Comprehensive Persistence: All text input fields are automatically saved';

  @override
  String get dialogTechBullet4 =>
      'Efficient Storage: Uses platform-native storage for optimal performance';

  @override
  String get dialogTechBullet5 =>
      'Enhanced Stability: Better error handling and user experience';

  @override
  String get dialogTechBullet6 =>
      'Full Seed Visibility: Complete seed numbers displayed without truncation';

  @override
  String get dialogPreviousSection => '📋 Previous Updates';

  @override
  String get dialogV1036Title => 'Version 1.0.36 - Search Memory';

  @override
  String get dialogV1036Body =>
      'Complete search parameter persistence including world seed, coordinates, and radius.';

  @override
  String get dialogV1027Title => 'Version 1.0.27 - Minor Update';

  @override
  String get dialogV1027Body =>
      'Updated splash screen and icons for better visual consistency.';

  @override
  String get dialogV1022Title => 'Version 1.0.22 - Extended Ore Discovery';

  @override
  String get dialogV1022Body =>
      '⚪ Iron Ore (Y -64 to 256, peaks at Y 15 & Y 232)\n🔴 Redstone Ore (Y -64 to 15, 90% at Y -64 to -59)\n⚫ Coal Ore (Y 0 to 256, peaks at Y 96)\n🔵 Lapis Lazuli (Y -64 to 64, enhanced at Y 0-32)\nEnhanced UI with compact ore selection and visual legend';

  @override
  String get dialogPlayersSection => '🎯 Perfect for All Players';

  @override
  String get dialogPlayerBullet1 =>
      'Seed Explorers: Quickly switch between favorite world seeds';

  @override
  String get dialogPlayerBullet2 =>
      'Speedrunners: Quick access to essential ores with saved parameters';

  @override
  String get dialogPlayerBullet3 =>
      'Builders: Iron for tools, redstone for mechanisms';

  @override
  String get dialogPlayerBullet4 =>
      'Regular Players: Seamless continuation of mining sessions';

  @override
  String get dialogPlayerBullet5 =>
      'New Players: Learn optimal mining levels with persistent settings';

  @override
  String get dialogPlayerBullet6 =>
      'Content Creators: Easy seed management for showcasing different worlds';

  @override
  String get dialogFooter =>
      'NEW: Recent seeds history + all search parameters automatically saved!';

  @override
  String get dialogGotIt => 'Got it!';
}
