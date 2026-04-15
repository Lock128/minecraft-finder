// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Edelstein-, Erz- & Strukturfinder';

  @override
  String get appTitleFull =>
      'Edelstein-, Erz- & Strukturfinder für MC – Finde Diamanten, Gold, Netherit & mehr';

  @override
  String get searchTab => 'Suche';

  @override
  String get resultsTab => 'Ergebnisse';

  @override
  String get guideTab => 'Anleitung';

  @override
  String get bedwarsTab => 'Bedwars';

  @override
  String get updatesTab => 'Aktualisierungen';

  @override
  String get appInfoTooltip => 'App-Info';

  @override
  String get lightThemeTooltip => 'Hell';

  @override
  String get darkThemeTooltip => 'Dunkel';

  @override
  String get languageTooltip => 'Sprache';

  @override
  String get errorEnableSearchType =>
      'Bitte aktiviere mindestens einen Suchtyp (Erze oder Strukturen)';

  @override
  String get errorSelectStructure =>
      'Bitte wähle mindestens einen Strukturtyp zum Suchen aus';

  @override
  String get errorSelectOre =>
      'Bitte wähle mindestens einen Erztyp zum Suchen aus';

  @override
  String errorGeneric(String message) {
    return 'Fehler: $message';
  }

  @override
  String get worldSettingsTitle => 'Welt-Einstellungen';

  @override
  String get worldSeedLabel => 'Welt-Seed';

  @override
  String get worldSeedHint => 'Gib deinen Welt-Seed ein';

  @override
  String get errorEmptySeed => 'Bitte gib einen Welt-Seed ein';

  @override
  String get recentSeeds => 'Letzte Seeds';

  @override
  String get searchCenterTitle => 'Suchzentrum';

  @override
  String get coordinateX => 'X';

  @override
  String get coordinateY => 'Y';

  @override
  String get coordinateZ => 'Z';

  @override
  String get searchRadiusLabel => 'Suchradius (Blöcke)';

  @override
  String get errorEmptyRadius => 'Bitte gib einen Suchradius ein';

  @override
  String get errorRadiusPositive => 'Radius muss positiv sein';

  @override
  String get errorRadiusMax => 'Max. 2000';

  @override
  String get errorFieldRequired => 'Erforderlich';

  @override
  String get errorFieldInvalid => 'Ungültig';

  @override
  String get errorYRange => '-64 bis 320';

  @override
  String get togglePlusMinus => '+/- umschalten';

  @override
  String get oreTypeTitle => 'Erztyp';

  @override
  String get includeOresInSearch => 'Erze in Suche einbeziehen';

  @override
  String get includeNetherGold => 'Nethergold einbeziehen';

  @override
  String get searchForNetherGold => 'Nach Nethergolderz suchen';

  @override
  String get netheriteAncientDebris => 'Netherit (Antiker Schutt)';

  @override
  String get legendDiamond => '💎 Diamant';

  @override
  String get legendGold => '🏅 Gold';

  @override
  String get legendIron => '⚪ Eisen';

  @override
  String get legendRedstone => '🔴 Redstone';

  @override
  String get legendCoal => '⚫ Kohle';

  @override
  String get legendLapis => '🔵 Lapislazuli';

  @override
  String get structureSearchTitle => 'Struktursuche';

  @override
  String get includeStructuresInSearch => 'Strukturen in Suche einbeziehen';

  @override
  String get selectStructuresToFind => 'Strukturen zum Finden auswählen:';

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String get clearAll => 'Alle löschen';

  @override
  String structuresSelected(int count) {
    return '$count Strukturen ausgewählt';
  }

  @override
  String get findButton => 'Finden';

  @override
  String get findAllNetheriteButton => 'Alle Netherite finden';

  @override
  String get searchingButton => 'Suche läuft...';

  @override
  String get comprehensiveNetheriteSearch => 'Umfassende Netherit-Suche';

  @override
  String get comprehensiveNetheriteBody =>
      '• Durchsucht die gesamte Welt (4000×4000 Blöcke)\n• Kann 30–60 Sekunden dauern\n• Zeigt bis zu 300 beste Fundorte\n• Ignoriert andere Erzauswahlen';

  @override
  String get regularSearchInfo =>
      'Reguläre Suche zeigt die besten 250 Ergebnisse (alle Typen kombiniert)';

  @override
  String get loadingNetherite => 'Umfassende Netherit-Suche läuft...';

  @override
  String get loadingAnalyzing => 'Weltgenerierung wird analysiert...';

  @override
  String get loadingTimeMay => 'Dies kann 30–60 Sekunden dauern';

  @override
  String get noResultsYet => 'Noch keine Ergebnisse';

  @override
  String get useSearchTabToFind => 'Verwende den Suche-Tab, um Erze zu finden';

  @override
  String get noResultsMatchFilters =>
      'Keine Ergebnisse entsprechen den Filtern';

  @override
  String get tryAdjustingFilters =>
      'Versuche, deine Filtereinstellungen anzupassen';

  @override
  String resultsCount(int total, int oreCount, int structureCount) {
    return '$total Ergebnisse  ·  $oreCount Erze  ·  $structureCount Strukturen';
  }

  @override
  String get hideFilters => 'Filter ausblenden';

  @override
  String get showFilters => 'Filter anzeigen';

  @override
  String get oreFiltersLabel => 'Erzfilter:';

  @override
  String get filterDiamonds => '💎 Diamanten';

  @override
  String get filterGold => '🏅 Gold';

  @override
  String get filterIron => '⚪ Eisen';

  @override
  String get filterRedstone => '🔴 Redstone';

  @override
  String get filterCoal => '⚫ Kohle';

  @override
  String get filterLapis => '🔵 Lapislazuli';

  @override
  String get filterNetherite => '🔥 Netherit';

  @override
  String get structureFiltersLabel => 'Strukturfilter:';

  @override
  String get biomeFiltersLabel => 'Biomfilter:';

  @override
  String get coordinateFiltersTitle => 'Koordinatenfilter';

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
  String get clearAllFilters => 'Alle Filter löschen';

  @override
  String get copyCoordinates => 'Koordinaten kopieren';

  @override
  String copiedCoordinates(String coords) {
    return 'Koordinaten kopiert: $coords';
  }

  @override
  String chunkLabel(int chunkX, int chunkZ) {
    return 'Chunk: ($chunkX, $chunkZ)';
  }

  @override
  String probabilityLabel(String percent) {
    return 'Wahrscheinlichkeit: $percent%';
  }

  @override
  String biomeLabel(String biome) {
    return 'Biom: $biome';
  }

  @override
  String get guideDiamondTitle => 'Diamant-Generierung';

  @override
  String get guideDiamondIntro =>
      'Diamanten spawnen in der Oberwelt zwischen Y -64 und Y 16.';

  @override
  String get guideDiamondOptimal => '🎯 Optimale Y-Ebenen:';

  @override
  String get guideDiamondLevel1 =>
      '• Y -64 bis -54: Beste Diamantschicht (80% Basiswahrscheinlichkeit)';

  @override
  String get guideDiamondLevel2 =>
      '• Y -53 bis -48: Gute Diamantschicht (60% Basiswahrscheinlichkeit)';

  @override
  String get guideDiamondLevel3 =>
      '• Y -47 bis -32: Ordentliche Diamantschicht (40% Basiswahrscheinlichkeit)';

  @override
  String get guideDiamondLevel4 =>
      '• Y -31 bis 16: Untere Diamantschicht (20% Basiswahrscheinlichkeit)';

  @override
  String get guideGoldTitle => 'Gold-Generierung';

  @override
  String get guideGoldIntro =>
      'Gold hat unterschiedliche Generierungsmuster je nach Biom und Dimension.';

  @override
  String get guideGoldOverworld => '🌍 Oberwelt-Gold (Y -64 bis 32):';

  @override
  String get guideGoldLevel1 =>
      '• Y -47 bis -16: Beste Goldschicht (60% Basiswahrscheinlichkeit)';

  @override
  String get guideGoldLevel2 =>
      '• Y -64 bis -48: Untere Ebenen (40% Basiswahrscheinlichkeit)';

  @override
  String get guideGoldLevel3 =>
      '• Y -15 bis 32: Obere Ebenen (30% Basiswahrscheinlichkeit)';

  @override
  String get guideGoldBadlands => '🏜️ Ödland/Mesa-Biom (BONUS!):';

  @override
  String get guideGoldBadlandsLevel =>
      '• Y 32 bis 80: Hervorragendes Oberflächengold (90% Basiswahrscheinlichkeit)';

  @override
  String get guideGoldBadlandsBonus => '• 6x mehr Gold als in normalen Biomen!';

  @override
  String get guideNetheriteTitle => 'Netherit (Antiker Schutt)';

  @override
  String get guideNetheriteIntro =>
      'Antiker Schutt ist das seltenste Erz und kommt nur im Nether vor.';

  @override
  String get guideNetheriteOptimal => '🎯 Nether Y-Ebenen (Y 8 bis 22):';

  @override
  String get guideNetheriteLevel1 =>
      '• Y 13 bis 17: Beste Schicht für Antiken Schutt (90% Basiswahrscheinlichkeit)';

  @override
  String get guideNetheriteLevel2 =>
      '• Y 10 bis 19: Gute Schicht für Antiken Schutt (70% Basiswahrscheinlichkeit)';

  @override
  String get guideNetheriteLevel3 =>
      '• Y 8 bis 22: Ordentliche Schicht für Antiken Schutt (50% Basiswahrscheinlichkeit)';

  @override
  String get guideNetheriteSearch => '🔍 Suchmodi:';

  @override
  String get guideNetheriteRegular =>
      '• Reguläre Suche: Verwendet mindestens 15% Wahrscheinlichkeitsschwelle';

  @override
  String get guideNetheriteComprehensive =>
      '• Umfassende Suche: Verwendet 5% Schwelle, deckt 4000x4000 Blöcke ab';

  @override
  String get guideIronTitle => 'Eisen-Generierung';

  @override
  String get guideIronIntro =>
      'Eisen ist eines der vielseitigsten und häufigsten Erze.';

  @override
  String get guideIronOptimal => '🎯 Optimale Y-Ebenen:';

  @override
  String get guideIronLevel1 =>
      '• Y 128 bis 256: Berg-Eisengenerierung (Spitze bei Y 232)';

  @override
  String get guideIronLevel2 =>
      '• Y -24 bis 56: Unterirdische Eisengenerierung (Spitze bei Y 15)';

  @override
  String get guideIronLevel3 =>
      '• Y -64 bis 72: Allgemeine Eisenverfügbarkeit (40% Basiswahrscheinlichkeit)';

  @override
  String get guideRedstoneTitle => 'Redstone-Generierung';

  @override
  String get guideRedstoneIntro =>
      'Redstone ist der Schlüssel zu Automatisierung und komplexen Konstruktionen.';

  @override
  String get guideRedstoneOptimal => '🎯 Optimale Y-Ebenen (Y -64 bis 15):';

  @override
  String get guideRedstoneLevel1 =>
      '• Y -64 bis -59: Beste Redstone-Schicht (90% Basiswahrscheinlichkeit)';

  @override
  String get guideRedstoneLevel2 =>
      '• Y -58 bis -48: Gute Redstone-Schicht (70% Basiswahrscheinlichkeit)';

  @override
  String get guideRedstoneLevel3 =>
      '• Y -47 bis -32: Ordentliche Redstone-Schicht (50% Basiswahrscheinlichkeit)';

  @override
  String get guideRedstoneLevel4 =>
      '• Y -31 bis 15: Untere Redstone-Schicht (30% Basiswahrscheinlichkeit)';

  @override
  String get guideCoalTitle => 'Kohle-Generierung';

  @override
  String get guideCoalIntro =>
      'Kohle ist das häufigste Erz und die wichtigste Brennstoffquelle.';

  @override
  String get guideCoalOptimal => '🎯 Optimale Y-Ebenen (Y 0 bis 256):';

  @override
  String get guideCoalLevel1 =>
      '• Y 80 bis 136: Beste Kohlegenerierung (Spitze bei Y 96)';

  @override
  String get guideCoalLevel2 =>
      '• Y 0 bis 256: Allgemeine Kohleverfügbarkeit (60% Basiswahrscheinlichkeit)';

  @override
  String get guideLapisTitle => 'Lapislazuli-Generierung';

  @override
  String get guideLapisIntro =>
      'Lapislazuli spawnt in der Oberwelt zwischen Y -64 und Y 64.';

  @override
  String get guideLapisOptimal => '🎯 Optimale Y-Ebenen:';

  @override
  String get guideLapisLevel1 =>
      '• Y 0 bis 32: Beste Lapislazuli-Schicht (verbesserte Generierung)';

  @override
  String get guideLapisLevel2 =>
      '• Y -64 bis -1: Untere Ebenen (Standardgenerierung)';

  @override
  String get guideLapisLevel3 =>
      '• Y 33 bis 64: Obere Ebenen (reduzierte Generierung)';

  @override
  String get guideStructureTitle => 'Struktur-Generierung';

  @override
  String get guideStructureIntro =>
      'Strukturen werden basierend auf Biomkompatibilität und Seltenheit generiert.';

  @override
  String get guideStructureCommon => '🏘️ Häufige Strukturen (Hohe Spawnrate):';

  @override
  String get guideStructureVillages =>
      '• Dörfer: Ebenen-, Wüsten-, Savannen-, Taiga-Biome';

  @override
  String get guideStructureOutposts =>
      '• Plünderer-Außenposten: Gleiche Biome wie Dörfer';

  @override
  String get guideStructurePortals =>
      '• Zerstörte Portale: Können in jeder Dimension spawnen';

  @override
  String get guideStructureRare =>
      '🏛️ Seltene Strukturen (Niedrige Spawnrate):';

  @override
  String get guideStructureStrongholds =>
      '• Festungen: Unterirdisch, nur 128 pro Welt';

  @override
  String get guideStructureEndCities =>
      '• Endstädte: End-Dimension, äußere Inseln';

  @override
  String get guideStructureMonuments => '• Ozeanmonumente: Tiefozean-Biome';

  @override
  String get guideStructureAncientCities =>
      '• Antike Städte: Tiefes Dunkelbiom (Y -52)';

  @override
  String get proTipTitle => 'Profi-Tipp';

  @override
  String get proTipBody =>
      'Dieses Tool liefert statistische Vorhersagen basierend auf Blockspiel-Generierungsalgorithmen. Nutze die Koordinaten als Ausgangspunkte für deine Bergbau-Expeditionen und erkunde immer die umliegenden Gebiete, sobald du Erzadern findest!';

  @override
  String get bedwarsTierStarters => 'Anfänger';

  @override
  String get bedwarsTierPractitioners => 'Fortgeschrittene';

  @override
  String get bedwarsTierExperts => 'Experten';

  @override
  String get bedwarsGameObjectiveTitle => 'Spielziel & Regeln';

  @override
  String get bedwarsGameObjective1 =>
      'Beschütze dein Bett und versuche, feindliche Betten zu zerstören.';

  @override
  String get bedwarsGameObjective2 =>
      'Sobald dein Bett zerstört ist, kannst du nicht mehr respawnen.';

  @override
  String get bedwarsGameObjective3 =>
      'Das letzte Team mit einem überlebenden Spieler gewinnt das Spiel.';

  @override
  String get bedwarsGameObjective4 =>
      'Sammle Ressourcen von Generatoren, um Ausrüstung und Blöcke zu kaufen.';

  @override
  String get bedwarsResourceGatheringTitle => 'Grundlegendes Ressourcensammeln';

  @override
  String get bedwarsResourceGathering1 =>
      'Eisen und Gold spawnen automatisch an deinem Inselgenerator.';

  @override
  String get bedwarsResourceGathering2 =>
      'Bleib zwischen Kämpfen in der Nähe deines Generators, um Ressourcen zu sammeln.';

  @override
  String get bedwarsResourceGathering3 =>
      'Eisen wird für einfache Blöcke und Werkzeuge aus dem Shop verwendet.';

  @override
  String get bedwarsResourceGathering4 =>
      'Gold kauft stärkere Rüstung, Waffen und Hilfsitems.';

  @override
  String get bedwarsPurchasingTitle => 'Wichtige Gegenstände kaufen';

  @override
  String get bedwarsPurchasing1 =>
      'Kaufe früh Wolle oder Endstein zum Brückenbauen und zur Bettverteidigung.';

  @override
  String get bedwarsPurchasing2 =>
      'Ein Steinschwert ist ein günstiges frühes Upgrade gegenüber dem Holzschwert.';

  @override
  String get bedwarsPurchasing3 =>
      'Eisenrüstung gibt einen soliden Verteidigungsboost für die ersten Kämpfe.';

  @override
  String get bedwarsPurchasing4 =>
      'Besorge dir eine Schere, um Wollverteidigungen schnell zu durchschneiden.';

  @override
  String get bedwarsBedDefenseTitle => 'Grundlegende Bettverteidigung';

  @override
  String get bedwarsBedDefense1 =>
      'Bedecke dein Bett mit Wolle, sobald das Spiel beginnt.';

  @override
  String get bedwarsBedDefense2 =>
      'Füge eine zweite Schicht Endstein um die Wolle für zusätzlichen Schutz hinzu.';

  @override
  String get bedwarsBedDefense3 =>
      'Lass dein Bett im frühen Spiel niemals komplett unbewacht.';

  @override
  String get bedwarsBedDefense4 =>
      'Platziere Blöcke auf allen Seiten, einschließlich der Oberseite des Bettes.';

  @override
  String get bedwarsCombatTipsTitle => 'Grundlegende Kampftipps';

  @override
  String get bedwarsCombatTips1 =>
      'Sprinte immer, bevor du einen Gegner triffst, für zusätzlichen Rückstoß.';

  @override
  String get bedwarsCombatTips2 =>
      'Block-Hit: Wechsle zwischen Angriff und Block, um erlittenen Schaden zu reduzieren.';

  @override
  String get bedwarsCombatTips3 =>
      'Ziele auf kritische Treffer, indem du beim Fallen nach einem Sprung angreifst.';

  @override
  String get bedwarsCombatTips4 =>
      'Vermeide Kämpfe auf schmalen Brücken, wo Rückstoß tödlich ist.';

  @override
  String get bedwarsResourceManagementTitle =>
      'Effizientes Ressourcenmanagement & Upgrades';

  @override
  String get bedwarsResourceManagement1 =>
      'Besuche regelmäßig Diamant- und Smaragdgeneratoren auf den Mittelinseln.';

  @override
  String get bedwarsResourceManagement2 =>
      'Priorisiere Team-Upgrades wie Schärfe, Schutz und Schmiede-Upgrades.';

  @override
  String get bedwarsResourceManagement3 =>
      'Teile die Ressourcensammlung mit Teamkameraden für schnelleren Fortschritt auf.';

  @override
  String get bedwarsResourceManagement4 =>
      'Spare Smaragde für mächtige Items wie Diamantrüstung oder Enderperlen.';

  @override
  String get bedwarsIntermediateDefenseTitle =>
      'Fortgeschrittene Bettverteidigung';

  @override
  String get bedwarsIntermediateDefense1 =>
      'Schichte deine Bettverteidigung: Wolle innen, Endstein in der Mitte, Holz oder Glas außen.';

  @override
  String get bedwarsIntermediateDefense2 =>
      'Verwende explosionssicheres Glas, um TNT-Angriffe auf dein Bett abzuwehren.';

  @override
  String get bedwarsIntermediateDefense3 =>
      'Platziere Wassereimer in der Nähe deines Bettes, um Angreifer zu verlangsamen.';

  @override
  String get bedwarsIntermediateDefense4 =>
      'Erwäge, Obsidian als innerste Schicht für maximale Haltbarkeit zu platzieren.';

  @override
  String get bedwarsTeamCoordinationTitle => 'Teamkoordinationsstrategien';

  @override
  String get bedwarsTeamCoordination1 =>
      'Weise Rollen zu: Ein Spieler verteidigt, während andere angreifen oder Ressourcen sammeln.';

  @override
  String get bedwarsTeamCoordination2 =>
      'Kommuniziere feindliche Positionen und eingehende Angriffe an dein Team.';

  @override
  String get bedwarsTeamCoordination3 =>
      'Koordiniere gleichzeitige Angriffe auf feindliche Basen für maximalen Druck.';

  @override
  String get bedwarsTeamCoordination4 =>
      'Teile Ressourcen mit Teamkameraden, die bestimmte Upgrades benötigen.';

  @override
  String get bedwarsBridgeBuildingTitle => 'Brückenbautechniken';

  @override
  String get bedwarsBridgeBuilding1 =>
      'Übe Speed-Bridging, indem du am Rand schleichst und schnell Blöcke platzierst.';

  @override
  String get bedwarsBridgeBuilding2 =>
      'Baue Brücken mit leichten Zickzackmustern, um einfache Bogenschüsse zu vermeiden.';

  @override
  String get bedwarsBridgeBuilding3 =>
      'Verwende schwer zu brechende Blöcke wie Endstein für permanente Brücken.';

  @override
  String get bedwarsBridgeBuilding4 =>
      'Trage immer genug Blöcke bei dir, bevor du eine Brücke zu einer feindlichen Insel baust.';

  @override
  String get bedwarsMidGameCombatTitle => 'Kampftaktiken im Mittelspiel';

  @override
  String get bedwarsMidGameCombat1 =>
      'Verwende Rückstoß-Stöcke, um Feinde von Brücken und Inseln zu stoßen.';

  @override
  String get bedwarsMidGameCombat2 =>
      'Trage einen Bogen für Fernkampfdruck, während du dich feindlichen Basen näherst.';

  @override
  String get bedwarsMidGameCombat3 =>
      'Verwende Feuerbälle, um Verteidigungen zu durchbrechen und Spieler in die Leere zu schleudern.';

  @override
  String get bedwarsMidGameCombat4 =>
      'Iss immer einen goldenen Apfel, bevor du dich in einen harten Kampf begibst.';

  @override
  String get bedwarsAdvancedPvpTitle => 'Fortgeschrittener PvP-Kampf';

  @override
  String get bedwarsAdvancedPvp1 =>
      'Meistere W-Tap-Kombos, indem du zwischen Treffern Vorwärts loslässt und erneut drückst.';

  @override
  String get bedwarsAdvancedPvp2 =>
      'Verwende Angelruten, um Feinde heranzuziehen und ihren Sprint zurückzusetzen.';

  @override
  String get bedwarsAdvancedPvp3 =>
      'Bewege dich in unvorhersehbaren Mustern seitwärts, um schwerer zu treffen zu sein.';

  @override
  String get bedwarsAdvancedPvp4 =>
      'Kombiniere Angelzüge mit sofortigen Schwerthieben für verheerende Kombos.';

  @override
  String get bedwarsSpeedBridgingTitle =>
      'Speed-Bridging & Fortgeschrittene Bewegung';

  @override
  String get bedwarsSpeedBridging1 =>
      'Lerne Ninja-Bridging, um Blöcke zu platzieren, während du dich vorwärts bewegst, ohne zu schleichen.';

  @override
  String get bedwarsSpeedBridging2 =>
      'Übe Breezily-Bridging für die schnellste geradlinige Brückengeschwindigkeit.';

  @override
  String get bedwarsSpeedBridging3 =>
      'Verwende Block-Clutches, um dich vor dem Fall in die Leere zu retten.';

  @override
  String get bedwarsSpeedBridging4 =>
      'Meistere Jump-Bridging, um Lücken während Angriffen schnell zu überbrücken.';

  @override
  String get bedwarsRushStrategiesTitle => 'Rush-Strategien & Timing';

  @override
  String get bedwarsRushStrategies1 =>
      'Stürme die nächste feindliche Basis innerhalb der ersten 30 Sekunden für einen frühen Vorteil.';

  @override
  String get bedwarsRushStrategies2 =>
      'Kaufe TNT und eine Spitzhacke für einen schnellen Bettbruch bei verteidigten Basen.';

  @override
  String get bedwarsRushStrategies3 =>
      'Time deine Angriffe, wenn Feinde ihre Basis verlassen, um Ressourcen zu sammeln.';

  @override
  String get bedwarsRushStrategies4 =>
      'Verwende Unsichtbarkeitstränke für Überraschungsangriffe auf gut verteidigte Betten.';

  @override
  String get bedwarsEndgameTitle =>
      'Endspiel-Taktiken & Ressourcenpriorisierung';

  @override
  String get bedwarsEndgame1 =>
      'Hamstre Enderperlen für schnelle Fluchten und Überraschungsangriffe.';

  @override
  String get bedwarsEndgame2 =>
      'Priorisiere Diamantrüstung und Schärfe-Upgrades für die letzten Kämpfe.';

  @override
  String get bedwarsEndgame3 =>
      'Kontrolliere die Generatoren in der Kartenmitte, um verbleibenden Teams Ressourcen zu verweigern.';

  @override
  String get bedwarsEndgame4 =>
      'Halte Notfallblöcke und goldene Äpfel für entscheidende Momente bereit.';

  @override
  String get bedwarsCounterStrategiesTitle =>
      'Gegenstrategien gegen häufige Spielzüge';

  @override
  String get bedwarsCounterStrategies1 =>
      'Kontere Brücken-Rusher, indem du Leerenfallen platzierst oder Bögen auf Distanz verwendest.';

  @override
  String get bedwarsCounterStrategies2 =>
      'Gegen TNT-Angriffe verwende explosionssicheres Glas und Obsidianschichten.';

  @override
  String get bedwarsCounterStrategies3 =>
      'Kontere unsichtbare Spieler, indem du auf Rüstungspartikel und Schrittgeräusche achtest.';

  @override
  String get bedwarsCounterStrategies4 =>
      'Gegen Feuerball-Spam trage einen Wassereimer, um Feuer zu löschen und Rückstoß zu blockieren.';

  @override
  String get aboutTitle => 'Über Edelstein-, Erz- & Strukturfinder';

  @override
  String get aboutWhatTitle => '🎯 Was diese App macht';

  @override
  String get aboutDescTitle => 'Erweiterte Minecraft Erz- & Strukturentdeckung';

  @override
  String get aboutDescBody =>
      'Gib deinen Welt-Seed und Suchkoordinaten ein, um genaue Fundorte von Diamanten, Gold, Netherit, Dörfern, Festungen und mehr zu entdecken.';

  @override
  String get aboutResourcesTitle => '⛏️ Unterstützte Ressourcen';

  @override
  String get aboutStructuresTitle => '🏘️ Unterstützte Strukturen';

  @override
  String get aboutHowItWorksTitle => '🔍 So funktioniert es';

  @override
  String get aboutFeaturesTitle => '✨ Hauptfunktionen';

  @override
  String get aboutSupportTitle => '☕ Entwicklung unterstützen';

  @override
  String get aboutResourceDiamond => 'Diamant';

  @override
  String get aboutResourceGold => 'Gold';

  @override
  String get aboutResourceNetherite => 'Netherit';

  @override
  String get aboutResourceIron => 'Eisen';

  @override
  String get aboutResourceRedstone => 'Redstone';

  @override
  String get aboutResourceCoal => 'Kohle';

  @override
  String get aboutResourceLapis => 'Lapislazuli';

  @override
  String get aboutStructureVillages => 'Dörfer 🏘️';

  @override
  String get aboutStructureStrongholds => 'Festungen 🏰';

  @override
  String get aboutStructureDungeons => 'Verliese 🕳️';

  @override
  String get aboutStructureMineshafts => 'Minenschächte ⛏️';

  @override
  String get aboutStructureDesertTemples => 'Wüstentempel 🏜️';

  @override
  String get aboutStructureJungleTemples => 'Dschungeltempel 🌿';

  @override
  String get aboutStructureOceanMonuments => 'Ozeanmonumente 🌊';

  @override
  String get aboutStructureWoodlandMansions => 'Waldvillen 🏚️';

  @override
  String get aboutStructurePillagerOutposts => 'Plünderer-Außenposten ⚔️';

  @override
  String get aboutStructureRuinedPortals => 'Zerstörte Portale 🌀';

  @override
  String get aboutStep1 => 'Gib deinen Welt-Seed im Suche-Tab ein';

  @override
  String get aboutStep2 => 'Setze deine Suchzentrum-Koordinaten (X, Y, Z)';

  @override
  String get aboutStep3 => 'Wähle deinen Suchradius';

  @override
  String get aboutStep4 =>
      'Wähle aus, welche Erze und Strukturen gefunden werden sollen';

  @override
  String get aboutStep5 =>
      'Tippe auf \"Finden\", um nahegelegene Ressourcen zu entdecken';

  @override
  String get aboutStep6 => 'Sieh dir Ergebnisse mit genauen Koordinaten an';

  @override
  String get aboutFeature1 =>
      'Letzte Seeds-Verlauf — Schnellzugriff auf die letzten 5 Seeds';

  @override
  String get aboutFeature2 =>
      'Automatische Parameterspeicherung — Verliere nie deine Sucheinstellungen';

  @override
  String get aboutFeature3 =>
      'Wahrscheinlichkeitsergebnisse — Finde die wahrscheinlichsten Fundorte';

  @override
  String get aboutFeature4 => 'Plattformübergreifend — Web, Mobil und Desktop';

  @override
  String get aboutFeature5 => 'Dunkel/Hell-Design — Wähle deinen Stil';

  @override
  String get aboutBuyMeCoffee => 'Kauf mir einen Kaffee';

  @override
  String get aboutSupportBody =>
      'Hilf, diese App kostenlos und besser zu machen! Deine Unterstützung ermöglicht neue Funktionen und laufende Entwicklung.';

  @override
  String get aboutSupportButton => 'Entwicklung unterstützen';

  @override
  String get aboutFooterTip =>
      'Verwende Letzte Seeds, um schnell zwischen Welten zu wechseln!';

  @override
  String get aboutGotIt => 'Verstanden!';

  @override
  String get releaseNotesHeader => 'Versionshinweise — v1.0.51';

  @override
  String get releaseNotesBedwarsSection => '🎮 Bedwars-Strategieguide — NEU!';

  @override
  String get releaseNotesBedwarsGuideTitle => 'Kompletter Bedwars-Guide';

  @override
  String get releaseNotesBedwarsGuideBody =>
      'Ein eigener Tab mit ausführlichen Strategien für Bedwars. Deckt frühes Spiel-Rushing, Verteidigung im Mittelspiel und Taktiken im Endspiel ab, um jedes Match zu dominieren.';

  @override
  String get releaseNotesResourceStrategiesTitle =>
      'Ressourcen- & Shop-Strategien';

  @override
  String get releaseNotesResourceStrategiesBody =>
      'Detaillierte Aufschlüsselungen von Ressourcenprioritäten, optimalen Shop-Käufen in jeder Phase und Teamkoordinationstipps für 2er-, 3er- und 4er-Modi.';

  @override
  String get releaseNotesDefenseAttackTitle =>
      'Verteidigungs- & Angriffsmuster';

  @override
  String get releaseNotesDefenseAttackBody =>
      'Lerne Bettverteidigungslayouts, Brücken-Rush-Techniken, Feuerballstrategien und wie du häufige feindliche Taktiken konterst.';

  @override
  String get releaseNotesUiSection => '🎨 Modernes Gamer-UI-Redesign';

  @override
  String get releaseNotesNeonTitle => 'Neon-Gamer-Ästhetik';

  @override
  String get releaseNotesNeonBody =>
      'Komplettes visuelles Redesign mit einer Neon-auf-Dunkel-Farbpalette. Lebhafte Grün-, Cyan- und Lila-Akzente mit dezenten Leuchteffekten für ein modernes Gaming-Gefühl.';

  @override
  String get releaseNotesLightModeTitle => 'Verbesserter Hellmodus';

  @override
  String get releaseNotesLightModeBody =>
      'Vollständig lesbares helles Design mit dunkleren Akzentvarianten. Jedes Textelement erfüllt nun die Kontrastanforderungen auf hellen und dunklen Hintergründen.';

  @override
  String get releaseNotesCardsTitle => 'Neugestaltete Karten & Buttons';

  @override
  String get releaseNotesCardsBody =>
      'Flache Karten mit Neon-Randakzenten, Verlaufs-Aktionsbuttons mit Leuchtschatten und eine sauberere Tab-Leiste mit Neon-Indikatoren ersetzen das alte Material-Grün-Design.';

  @override
  String get releaseNotesAlgorithmSection =>
      '⛏️ Verbesserungen des Erzsuch-Algorithmus';

  @override
  String get releaseNotesNoiseTitle => 'Verbesserte Rauschgenerierung';

  @override
  String get releaseNotesNoiseBody =>
      'Verbesserte Perlin-Noise-Implementierung für genauere Erzwahrscheinlichkeitsberechnungen, die besser mit den tatsächlichen Weltgenerierungsmustern im Spiel übereinstimmen.';

  @override
  String get releaseNotesBiomeTitle => 'Bessere Biomerkennung';

  @override
  String get releaseNotesBiomeBody =>
      'Verfeinerte Biomerkennung und Erzverteilungsmodellierung. Gold in Ödland, Diamanten in tiefen Ebenen und Netherit im Nether werden alle präziser vorhergesagt.';

  @override
  String get releaseNotesPerformanceTitle => 'Optimierte Suchleistung';

  @override
  String get releaseNotesPerformanceBody =>
      'Schnellere Suchausführung mit verbessertem Chunk-Scanning. Umfassende Netherit-Suche und Abfragen mit großem Radius werden effizienter abgeschlossen.';

  @override
  String get releaseNotesHighlightsSection => '🎯 Highlights';

  @override
  String get releaseNotesHighlight1 =>
      'Bedwars-Guide: Vollständiger Strategieguide mit Früh-/Mittel-/Endspiel-Taktiken';

  @override
  String get releaseNotesHighlight2 =>
      'Gamer-UI: Neon-Akzente, Leuchteffekte und modernes dunkles Design';

  @override
  String get releaseNotesHighlight3 =>
      'Hellmodus-Fix: Alle Texte jetzt auf hellen Hintergründen lesbar';

  @override
  String get releaseNotesHighlight4 =>
      'Bessere Erzsuche: Genauere Vorhersagen für alle Erztypen';

  @override
  String get releaseNotesHighlight5 =>
      'Schnellere Suchen: Optimierte Algorithmen für schnellere Ergebnisse';

  @override
  String get releaseNotesHighlight6 =>
      '5-Tab-Layout: Suche, Ergebnisse, Anleitung, Bedwars und Aktualisierungen';

  @override
  String get releaseNotesHighlight7 =>
      'Editions- & Versionsauswahl: Java/Bedrock-Edition und Legacy/Modern-Unterstützung';

  @override
  String get releaseNotesTechnicalSection => '🔧 Technische Verbesserungen';

  @override
  String get releaseNotesTechnical1 =>
      'Zentralisiertes Designsystem mit adaptiven Hell/Dunkel-Farbhelfern';

  @override
  String get releaseNotesTechnical2 =>
      'Wiederverwendbare GamerCard- und GamerSectionHeader-Komponenten';

  @override
  String get releaseNotesTechnical3 =>
      'Verbessertes Perlin-Noise für Erzgenerierungsmodellierung';

  @override
  String get releaseNotesTechnical4 =>
      'Bessere Chunk-Level-Wahrscheinlichkeitsberechnungen';

  @override
  String get releaseNotesTechnical5 =>
      'Reduzierte Widget-Neuaufbauten für flüssigeres Scrollen';

  @override
  String get releaseNotesTechnical6 =>
      'GameRandom-Strategiemuster für editionsabhängige Zufallszahlen bei allen Erzberechnungen';

  @override
  String get releaseNotesPreviousSection => '📋 Frühere Aktualisierungen';

  @override
  String get releaseNotesV1042Title => 'v1.0.42 — Lapislazuli + UI';

  @override
  String get releaseNotesV1042Body =>
      'Lapislazuli-Erzsuche hinzugefügt. Alle 7 Haupterze unterstützt. Verbessertes 4-Tab-Navigationslayout.';

  @override
  String get releaseNotesV1041Title => 'v1.0.41 — Letzte Seeds-Verlauf';

  @override
  String get releaseNotesV1041Body =>
      'Automatischer Seed-Verlauf mit Schnellzugriff auf die letzten 5 Seeds.';

  @override
  String get releaseNotesV1036Title => 'v1.0.36 — Vollständiger Suchspeicher';

  @override
  String get releaseNotesV1036Body => 'Umfassende Suchparameter-Persistenz.';

  @override
  String get releaseNotesV1027Title => 'v1.0.27 — Visuelle Verbesserungen';

  @override
  String get releaseNotesV1027Body =>
      'Aktualisierter Startbildschirm und Icons.';

  @override
  String get releaseNotesV1022Title => 'v1.0.22 — Erweiterte Erzentdeckung';

  @override
  String get releaseNotesV1022Body =>
      'Eisen, Redstone, Kohle und Lapislazuli hinzugefügt.';

  @override
  String get releaseNotesV1015Title => 'v1.0.15 — Strukturentdeckung';

  @override
  String get releaseNotesV1015Body =>
      'Dörfer, Festungen, Verliese, Tempel und mehr.';

  @override
  String get releaseNotesV1010Title => 'v1.0.10 — Grundversion';

  @override
  String get releaseNotesV1010Body =>
      'Kern-Diamant-, Gold- und Netherit-Suche.';

  @override
  String get releaseNotesTimelineSection => '🏆 Versionsverlauf';

  @override
  String get releaseNotesTimelineCurrent => 'Aktuell';

  @override
  String get releaseNotesTimelinePrevious => 'Vorherige';

  @override
  String get releaseNotesTimelineEarlier => 'Früher';

  @override
  String get releaseNotesTimelineBedwarsUi => 'Bedwars + UI';

  @override
  String get releaseNotesTimelineLapisUi => 'Lapis + UI';

  @override
  String get releaseNotesTimelineRecentSeeds => 'Letzte Seeds';

  @override
  String get releaseNotesTimelineSearchMemory => 'Suchspeicher';

  @override
  String get releaseNotesTimelineVisualUpdates => 'Visuelle Updates';

  @override
  String get releaseNotesTimelineExtendedOres => 'Erweiterte Erze';

  @override
  String get releaseNotesTimelineStructures => 'Strukturen';

  @override
  String get releaseNotesTimelineCoreFeatures => 'Kernfunktionen';

  @override
  String get releaseNotesFooter =>
      'Neu: Editions- & Versionsauswahl, Bedwars-Guide, Gamer-UI und verbesserte Erzsuche!';

  @override
  String get dialogReleaseNotesHeader => 'Versionshinweise - Version 1.0.41';

  @override
  String get dialogRecentSeedsSection => '🌱 Letzte Seeds-Verlauf - NEU!';

  @override
  String get dialogQuickSeedAccessTitle => 'Schneller Seed-Zugriff';

  @override
  String get dialogQuickSeedAccessBody =>
      'Verliere nie den Überblick über deine Lieblings-Welt-Seeds! Die App speichert jetzt automatisch deine letzten 5 gesuchten Seeds und zeigt sie als anklickbare Optionen unter dem Seed-Eingabefeld an. Tippe einfach auf einen kürzlichen Seed, um ihn sofort wieder zu verwenden.';

  @override
  String get dialogSmartSeedTitle => 'Intelligente Seed-Verwaltung';

  @override
  String get dialogSmartSeedBody =>
      'Kürzliche Seeds werden automatisch verwaltet – wenn du einen Seed erneut suchst, wird er an die Spitze der Liste verschoben. Der älteste Seed wird automatisch entfernt, wenn du das 5-Seed-Limit erreichst. Alle Seed-Ziffern sind mit verbesserter Monospace-Formatierung vollständig sichtbar.';

  @override
  String get dialogEnhancedUxTitle => 'Verbesserte Benutzererfahrung';

  @override
  String get dialogEnhancedUxBody =>
      'Perfekt für Spieler, die mehrere Seeds testen oder zu Lieblingswelten zurückkehren. Kein manuelles Eintippen langer Seed-Nummern mehr – einfach klicken und suchen! Seeds bleiben über App-Sitzungen hinweg erhalten.';

  @override
  String get dialogSearchMemorySection =>
      '💾 Vollständige Suchspeicher-Funktion';

  @override
  String get dialogAutoSaveTitle => 'Automatische Parameterspeicherung';

  @override
  String get dialogAutoSaveBody =>
      'Die App merkt sich ALLE deine Suchparameter einschließlich Welt-Seed, X/Y/Z-Koordinaten und Suchradius. Alles wird automatisch beim Tippen gespeichert und beim Neustart der App wiederhergestellt.';

  @override
  String get dialogSeamlessTitle => 'Nahtloser Arbeitsablauf';

  @override
  String get dialogSeamlessBody =>
      'Setze deine Erzsuch-Sitzungen genau dort fort, wo du aufgehört hast. Kein erneutes Eingeben von Koordinaten oder Anpassen von Sucheinstellungen. Konzentriere dich auf das Finden von Erzen!';

  @override
  String get dialogEnhancedUxSection => '🎯 Verbesserte Benutzererfahrung';

  @override
  String get dialogUxBullet1 =>
      'Letzte Seeds: Schnellzugriff auf deine letzten 5 gesuchten Welt-Seeds';

  @override
  String get dialogUxBullet2 =>
      'Zeitersparnis: Kein Merken und erneutes Eingeben von Suchparametern nötig';

  @override
  String get dialogUxBullet3 =>
      'Bessere Produktivität: Konzentriere dich rein auf die Erzentdeckung';

  @override
  String get dialogUxBullet4 =>
      'Plattformübergreifend: Funktioniert konsistent auf allen unterstützten Plattformen';

  @override
  String get dialogUxBullet5 =>
      'Intelligente Standardwerte: Sinnvolle Standardwerte für neue Benutzer';

  @override
  String get dialogUxBullet6 =>
      'Verbesserte Lesbarkeit: Monospace-Schrift für bessere Seed-Nummern-Sichtbarkeit';

  @override
  String get dialogTechSection => '🔧 Technische Verbesserungen';

  @override
  String get dialogTechBullet1 =>
      'Letzte Seeds-Speicher: Persistenter Seed-Verlauf mit automatischer Verwaltung';

  @override
  String get dialogTechBullet2 =>
      'Offline-Schriftunterstützung: Verbesserte Leistung ohne Internetverbindung';

  @override
  String get dialogTechBullet3 =>
      'Umfassende Persistenz: Alle Texteingabefelder werden automatisch gespeichert';

  @override
  String get dialogTechBullet4 =>
      'Effiziente Speicherung: Verwendet plattformnative Speicherung für optimale Leistung';

  @override
  String get dialogTechBullet5 =>
      'Verbesserte Stabilität: Bessere Fehlerbehandlung und Benutzererfahrung';

  @override
  String get dialogTechBullet6 =>
      'Vollständige Seed-Sichtbarkeit: Komplette Seed-Nummern ohne Abschneidung angezeigt';

  @override
  String get dialogPreviousSection => '📋 Frühere Aktualisierungen';

  @override
  String get dialogV1036Title => 'Version 1.0.36 - Suchspeicher';

  @override
  String get dialogV1036Body =>
      'Vollständige Suchparameter-Persistenz einschließlich Welt-Seed, Koordinaten und Radius.';

  @override
  String get dialogV1027Title => 'Version 1.0.27 - Kleinere Aktualisierung';

  @override
  String get dialogV1027Body =>
      'Aktualisierter Startbildschirm und Icons für bessere visuelle Konsistenz.';

  @override
  String get dialogV1022Title => 'Version 1.0.22 - Erweiterte Erzentdeckung';

  @override
  String get dialogV1022Body =>
      '⚪ Eisenerz (Y -64 bis 256, Spitze bei Y 15 & Y 232)\n🔴 Redstoneerz (Y -64 bis 15, 90% bei Y -64 bis -59)\n⚫ Kohleerz (Y 0 bis 256, Spitze bei Y 96)\n🔵 Lapislazuli (Y -64 bis 64, verbessert bei Y 0-32)\nVerbessertes UI mit kompakter Erzauswahl und visueller Legende';

  @override
  String get dialogPlayersSection => '🎯 Perfekt für alle Spieler';

  @override
  String get dialogPlayerBullet1 =>
      'Seed-Entdecker: Schnell zwischen Lieblings-Welt-Seeds wechseln';

  @override
  String get dialogPlayerBullet2 =>
      'Speedrunner: Schneller Zugriff auf wichtige Erze mit gespeicherten Parametern';

  @override
  String get dialogPlayerBullet3 =>
      'Baumeister: Eisen für Werkzeuge, Redstone für Mechanismen';

  @override
  String get dialogPlayerBullet4 =>
      'Normale Spieler: Nahtlose Fortsetzung von Bergbau-Sitzungen';

  @override
  String get dialogPlayerBullet5 =>
      'Neue Spieler: Optimale Abbauebenen mit persistenten Einstellungen lernen';

  @override
  String get dialogPlayerBullet6 =>
      'Content Creator: Einfache Seed-Verwaltung zum Präsentieren verschiedener Welten';

  @override
  String get dialogFooter =>
      'NEU: Letzte Seeds-Verlauf + alle Suchparameter automatisch gespeichert!';

  @override
  String get dialogGotIt => 'Verstanden!';

  @override
  String get releaseNotesEditionSection =>
      '🎮 Editions- & Versionsauswahl — NEU!';

  @override
  String get releaseNotesEditionSelectorTitle =>
      'Java- & Bedrock-Edition-Unterstützung';

  @override
  String get releaseNotesEditionSelectorBody =>
      'Wähle zwischen Java-Edition und Bedrock-Edition. Die App verwendet den korrekten Zufallsgenerator für jede Edition, damit die Erzvorhersagen zu deiner Welt passen.';

  @override
  String get releaseNotesVersionEraTitle => 'Legacy- & Modern-Versionsepochen';

  @override
  String get releaseNotesVersionEraBody =>
      'Wechsle zwischen Pre-1.18 (Legacy) mit klassischer gleichmäßiger Erzverteilung und festen Y-Bereichen, oder 1.18+ (Modern) mit Dreiecksverteilungen und erweiterter Welttiefe von -64 bis 320.';

  @override
  String get releaseNotesBedrockRngTitle => 'Bedrock-RNG-Engine';

  @override
  String get releaseNotesBedrockRngBody =>
      'Ein dedizierter Mersenne-Twister-RNG repliziert die C++-Engine der Bedrock-Edition. Kontextuelle Infoboxen zeigen an, wenn Vorhersagen approximativ sind.';

  @override
  String get releaseNotesV1050Title => 'v1.0.50 — Bedwars + UI';

  @override
  String get releaseNotesV1050Body =>
      'Kompletter Bedwars-Strategieguide. Modernes Gamer-UI-Redesign mit Neon-Ästhetik und verbessertem Lichtmodus.';

  @override
  String get releaseNotesTimelineEditionVersion => 'Editionen + Epochen';
}
