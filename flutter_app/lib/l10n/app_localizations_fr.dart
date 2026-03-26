// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Chercheur de Gemmes, Minerais & Structures';

  @override
  String get appTitleFull =>
      'Chercheur de Gemmes, Minerais & Structures pour MC – Trouvez Diamants, Or, Netherite & Plus';

  @override
  String get searchTab => 'Recherche';

  @override
  String get resultsTab => 'Résultats';

  @override
  String get guideTab => 'Guide';

  @override
  String get bedwarsTab => 'Bedwars';

  @override
  String get updatesTab => 'Mises à jour';

  @override
  String get appInfoTooltip => 'Infos sur l\'appli';

  @override
  String get lightThemeTooltip => 'Clair';

  @override
  String get darkThemeTooltip => 'Sombre';

  @override
  String get languageTooltip => 'Langue';

  @override
  String get errorEnableSearchType =>
      'Veuillez activer au moins un type de recherche (Minerais ou Structures)';

  @override
  String get errorSelectStructure =>
      'Veuillez sélectionner au moins un type de structure à rechercher';

  @override
  String get errorSelectOre =>
      'Veuillez sélectionner au moins un type de minerai à rechercher';

  @override
  String errorGeneric(String message) {
    return 'Erreur : $message';
  }

  @override
  String get worldSettingsTitle => 'Paramètres du monde';

  @override
  String get worldSeedLabel => 'Graine du monde';

  @override
  String get worldSeedHint => 'Entrez votre graine de monde';

  @override
  String get errorEmptySeed => 'Veuillez entrer une graine de monde';

  @override
  String get recentSeeds => 'Graines récentes';

  @override
  String get searchCenterTitle => 'Centre de recherche';

  @override
  String get coordinateX => 'X';

  @override
  String get coordinateY => 'Y';

  @override
  String get coordinateZ => 'Z';

  @override
  String get searchRadiusLabel => 'Rayon de recherche (blocs)';

  @override
  String get errorEmptyRadius => 'Veuillez entrer un rayon de recherche';

  @override
  String get errorRadiusPositive => 'Le rayon doit être positif';

  @override
  String get errorRadiusMax => 'Max 2000';

  @override
  String get errorFieldRequired => 'Requis';

  @override
  String get errorFieldInvalid => 'Invalide';

  @override
  String get errorYRange => '-64 à 320';

  @override
  String get togglePlusMinus => 'Basculer +/-';

  @override
  String get oreTypeTitle => 'Type de minerai';

  @override
  String get includeOresInSearch => 'Inclure les minerais dans la recherche';

  @override
  String get includeNetherGold => 'Inclure l\'or du Nether';

  @override
  String get searchForNetherGold => 'Rechercher le minerai d\'or du Nether';

  @override
  String get netheriteAncientDebris => 'Netherite (Débris antiques)';

  @override
  String get legendDiamond => '💎 Diamant';

  @override
  String get legendGold => '🏅 Or';

  @override
  String get legendIron => '⚪ Fer';

  @override
  String get legendRedstone => '🔴 Redstone';

  @override
  String get legendCoal => '⚫ Charbon';

  @override
  String get legendLapis => '🔵 Lapis';

  @override
  String get structureSearchTitle => 'Recherche de structures';

  @override
  String get includeStructuresInSearch =>
      'Inclure les structures dans la recherche';

  @override
  String get selectStructuresToFind =>
      'Sélectionner les structures à trouver :';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String structuresSelected(int count) {
    return '$count structures sélectionnées';
  }

  @override
  String get findButton => 'Trouver';

  @override
  String get findAllNetheriteButton => 'Trouver toute la Netherite';

  @override
  String get searchingButton => 'Recherche en cours...';

  @override
  String get comprehensiveNetheriteSearch => 'Recherche complète de Netherite';

  @override
  String get comprehensiveNetheriteBody =>
      '• Recherche dans le monde entier (4000×4000 blocs)\n• Peut prendre 30 à 60 secondes\n• Affiche jusqu\'à 300 meilleurs emplacements\n• Ignore les autres sélections de minerais';

  @override
  String get regularSearchInfo =>
      'La recherche normale affiche les 250 meilleurs résultats (tous types combinés)';

  @override
  String get loadingNetherite => 'Recherche complète de Netherite en cours...';

  @override
  String get loadingAnalyzing => 'Analyse de la génération du monde...';

  @override
  String get loadingTimeMay => 'Cela peut prendre 30 à 60 secondes';

  @override
  String get noResultsYet => 'Aucun résultat pour l\'instant';

  @override
  String get useSearchTabToFind =>
      'Utilisez l\'onglet Recherche pour trouver des minerais';

  @override
  String get noResultsMatchFilters =>
      'Aucun résultat ne correspond aux filtres';

  @override
  String get tryAdjustingFilters =>
      'Essayez d\'ajuster vos paramètres de filtre';

  @override
  String resultsCount(int total, int oreCount, int structureCount) {
    return '$total résultats  ·  $oreCount minerais  ·  $structureCount structures';
  }

  @override
  String get hideFilters => 'Masquer les filtres';

  @override
  String get showFilters => 'Afficher les filtres';

  @override
  String get oreFiltersLabel => 'Filtres de minerais :';

  @override
  String get filterDiamonds => '💎 Diamants';

  @override
  String get filterGold => '🏅 Or';

  @override
  String get filterIron => '⚪ Fer';

  @override
  String get filterRedstone => '🔴 Redstone';

  @override
  String get filterCoal => '⚫ Charbon';

  @override
  String get filterLapis => '🔵 Lapis';

  @override
  String get filterNetherite => '🔥 Netherite';

  @override
  String get structureFiltersLabel => 'Filtres de structures :';

  @override
  String get biomeFiltersLabel => 'Filtres de biomes :';

  @override
  String get coordinateFiltersTitle => 'Filtres de coordonnées';

  @override
  String get minX => 'X min';

  @override
  String get maxX => 'X max';

  @override
  String get minY => 'Y min';

  @override
  String get maxY => 'Y max';

  @override
  String get minZ => 'Z min';

  @override
  String get maxZ => 'Z max';

  @override
  String get clearAllFilters => 'Effacer tous les filtres';

  @override
  String get copyCoordinates => 'Copier les coordonnées';

  @override
  String copiedCoordinates(String coords) {
    return 'Coordonnées copiées : $coords';
  }

  @override
  String chunkLabel(int chunkX, int chunkZ) {
    return 'Chunk : ($chunkX, $chunkZ)';
  }

  @override
  String probabilityLabel(String percent) {
    return 'Probabilité : $percent%';
  }

  @override
  String biomeLabel(String biome) {
    return 'Biome : $biome';
  }

  @override
  String get guideDiamondTitle => 'Génération de diamants';

  @override
  String get guideDiamondIntro =>
      'Les diamants apparaissent dans le monde normal entre Y -64 et Y 16.';

  @override
  String get guideDiamondOptimal => '🎯 Niveaux Y optimaux :';

  @override
  String get guideDiamondLevel1 =>
      '• Y -64 à -54 : Couche de diamants maximale (80% de probabilité de base)';

  @override
  String get guideDiamondLevel2 =>
      '• Y -53 à -48 : Bonne couche de diamants (60% de probabilité de base)';

  @override
  String get guideDiamondLevel3 =>
      '• Y -47 à -32 : Couche de diamants correcte (40% de probabilité de base)';

  @override
  String get guideDiamondLevel4 =>
      '• Y -31 à 16 : Couche de diamants inférieure (20% de probabilité de base)';

  @override
  String get guideGoldTitle => 'Génération d\'or';

  @override
  String get guideGoldIntro =>
      'L\'or a des schémas de génération différents selon le biome et la dimension.';

  @override
  String get guideGoldOverworld => '🌍 Or du monde normal (Y -64 à 32) :';

  @override
  String get guideGoldLevel1 =>
      '• Y -47 à -16 : Couche d\'or maximale (60% de probabilité de base)';

  @override
  String get guideGoldLevel2 =>
      '• Y -64 à -48 : Niveaux inférieurs (40% de probabilité de base)';

  @override
  String get guideGoldLevel3 =>
      '• Y -15 à 32 : Niveaux supérieurs (30% de probabilité de base)';

  @override
  String get guideGoldBadlands => '🏜️ Biome Badlands/Mesa (BONUS !) :';

  @override
  String get guideGoldBadlandsLevel =>
      '• Y 32 à 80 : Excellent or de surface (90% de probabilité de base)';

  @override
  String get guideGoldBadlandsBonus =>
      '• 6x plus d\'or que dans les biomes normaux !';

  @override
  String get guideNetheriteTitle => 'Netherite (Débris antiques)';

  @override
  String get guideNetheriteIntro =>
      'Les débris antiques sont le minerai le plus rare, trouvé uniquement dans le Nether.';

  @override
  String get guideNetheriteOptimal => '🎯 Niveaux Y du Nether (Y 8 à 22) :';

  @override
  String get guideNetheriteLevel1 =>
      '• Y 13 à 17 : Couche maximale de débris antiques (90% de probabilité de base)';

  @override
  String get guideNetheriteLevel2 =>
      '• Y 10 à 19 : Bonne couche de débris antiques (70% de probabilité de base)';

  @override
  String get guideNetheriteLevel3 =>
      '• Y 8 à 22 : Couche correcte de débris antiques (50% de probabilité de base)';

  @override
  String get guideNetheriteSearch => '🔍 Modes de recherche :';

  @override
  String get guideNetheriteRegular =>
      '• Recherche normale : Utilise un seuil de probabilité minimum de 15%';

  @override
  String get guideNetheriteComprehensive =>
      '• Recherche complète : Utilise un seuil de 5%, couvre 4000x4000 blocs';

  @override
  String get guideIronTitle => 'Génération de fer';

  @override
  String get guideIronIntro =>
      'Le fer est l\'un des minerais les plus polyvalents et les plus courants.';

  @override
  String get guideIronOptimal => '🎯 Niveaux Y optimaux :';

  @override
  String get guideIronLevel1 =>
      '• Y 128 à 256 : Génération de fer en montagne (pic à Y 232)';

  @override
  String get guideIronLevel2 =>
      '• Y -24 à 56 : Génération de fer souterraine (pic à Y 15)';

  @override
  String get guideIronLevel3 =>
      '• Y -64 à 72 : Disponibilité générale du fer (40% de probabilité de base)';

  @override
  String get guideRedstoneTitle => 'Génération de redstone';

  @override
  String get guideRedstoneIntro =>
      'La redstone est la clé de l\'automatisation et des constructions complexes.';

  @override
  String get guideRedstoneOptimal => '🎯 Niveaux Y optimaux (Y -64 à 15) :';

  @override
  String get guideRedstoneLevel1 =>
      '• Y -64 à -59 : Couche de redstone maximale (90% de probabilité de base)';

  @override
  String get guideRedstoneLevel2 =>
      '• Y -58 à -48 : Bonne couche de redstone (70% de probabilité de base)';

  @override
  String get guideRedstoneLevel3 =>
      '• Y -47 à -32 : Couche de redstone correcte (50% de probabilité de base)';

  @override
  String get guideRedstoneLevel4 =>
      '• Y -31 à 15 : Couche de redstone inférieure (30% de probabilité de base)';

  @override
  String get guideCoalTitle => 'Génération de charbon';

  @override
  String get guideCoalIntro =>
      'Le charbon est le minerai le plus courant et la principale source de combustible.';

  @override
  String get guideCoalOptimal => '🎯 Niveaux Y optimaux (Y 0 à 256) :';

  @override
  String get guideCoalLevel1 =>
      '• Y 80 à 136 : Génération maximale de charbon (pic à Y 96)';

  @override
  String get guideCoalLevel2 =>
      '• Y 0 à 256 : Disponibilité générale du charbon (60% de probabilité de base)';

  @override
  String get guideLapisTitle => 'Génération de lapis-lazuli';

  @override
  String get guideLapisIntro =>
      'Le lapis-lazuli apparaît dans le monde normal entre Y -64 et Y 64.';

  @override
  String get guideLapisOptimal => '🎯 Niveaux Y optimaux :';

  @override
  String get guideLapisLevel1 =>
      '• Y 0 à 32 : Couche maximale de lapis (génération améliorée)';

  @override
  String get guideLapisLevel2 =>
      '• Y -64 à -1 : Niveaux inférieurs (génération standard)';

  @override
  String get guideLapisLevel3 =>
      '• Y 33 à 64 : Niveaux supérieurs (génération réduite)';

  @override
  String get guideStructureTitle => 'Génération de structures';

  @override
  String get guideStructureIntro =>
      'Les structures sont générées en fonction de la compatibilité des biomes et de la rareté.';

  @override
  String get guideStructureCommon =>
      '🏘️ Structures courantes (Taux d\'apparition élevé) :';

  @override
  String get guideStructureVillages =>
      '• Villages : Biomes plaines, désert, savane, taïga';

  @override
  String get guideStructureOutposts =>
      '• Avant-postes de pillards : Mêmes biomes que les villages';

  @override
  String get guideStructurePortals =>
      '• Portails en ruine : Peuvent apparaître dans n\'importe quelle dimension';

  @override
  String get guideStructureRare =>
      '🏛️ Structures rares (Taux d\'apparition faible) :';

  @override
  String get guideStructureStrongholds =>
      '• Forteresses : Souterraines, seulement 128 par monde';

  @override
  String get guideStructureEndCities =>
      '• Cités de l\'End : Dimension de l\'End, îles extérieures';

  @override
  String get guideStructureMonuments =>
      '• Monuments océaniques : Biomes d\'océan profond';

  @override
  String get guideStructureAncientCities =>
      '• Cités antiques : Biome des abîmes (Y -52)';

  @override
  String get proTipTitle => 'Astuce de pro';

  @override
  String get proTipBody =>
      'Cet outil fournit des prédictions statistiques basées sur les algorithmes de génération du jeu. Utilisez les coordonnées comme points de départ pour vos expéditions minières, et explorez toujours les zones environnantes une fois que vous trouvez des filons de minerai !';

  @override
  String get bedwarsTierStarters => 'Débutants';

  @override
  String get bedwarsTierPractitioners => 'Intermédiaires';

  @override
  String get bedwarsTierExperts => 'Experts';

  @override
  String get bedwarsGameObjectiveTitle => 'Objectif du jeu & Règles';

  @override
  String get bedwarsGameObjective1 =>
      'Protégez votre lit tout en essayant de détruire les lits ennemis.';

  @override
  String get bedwarsGameObjective2 =>
      'Une fois votre lit détruit, vous ne pouvez plus réapparaître.';

  @override
  String get bedwarsGameObjective3 =>
      'La dernière équipe avec un joueur survivant remporte la partie.';

  @override
  String get bedwarsGameObjective4 =>
      'Collectez des ressources aux générateurs pour acheter de l\'équipement et des blocs.';

  @override
  String get bedwarsResourceGatheringTitle => 'Collecte de ressources de base';

  @override
  String get bedwarsResourceGathering1 =>
      'Le fer et l\'or apparaissent automatiquement à votre générateur d\'île.';

  @override
  String get bedwarsResourceGathering2 =>
      'Restez près de votre générateur entre les combats pour collecter des ressources.';

  @override
  String get bedwarsResourceGathering3 =>
      'Le fer sert à acheter des blocs et outils de base à la boutique.';

  @override
  String get bedwarsResourceGathering4 =>
      'L\'or permet d\'acheter une armure, des armes et des objets utilitaires plus puissants.';

  @override
  String get bedwarsPurchasingTitle => 'Achat d\'objets essentiels';

  @override
  String get bedwarsPurchasing1 =>
      'Achetez de la laine ou de la pierre de l\'End tôt pour les ponts et la défense du lit.';

  @override
  String get bedwarsPurchasing2 =>
      'Une épée en pierre est une amélioration bon marché par rapport à l\'épée en bois.';

  @override
  String get bedwarsPurchasing3 =>
      'L\'armure en fer offre un bon bonus de défense pour les premiers combats.';

  @override
  String get bedwarsPurchasing4 =>
      'Procurez-vous des cisailles pour couper rapidement les défenses en laine.';

  @override
  String get bedwarsBedDefenseTitle => 'Défense de lit de base';

  @override
  String get bedwarsBedDefense1 =>
      'Couvrez votre lit avec de la laine dès le début de la partie.';

  @override
  String get bedwarsBedDefense2 =>
      'Ajoutez une deuxième couche de pierre de l\'End autour de la laine pour une protection supplémentaire.';

  @override
  String get bedwarsBedDefense3 =>
      'Ne laissez jamais votre lit complètement sans surveillance en début de partie.';

  @override
  String get bedwarsBedDefense4 =>
      'Placez des blocs sur tous les côtés, y compris le dessus du lit.';

  @override
  String get bedwarsCombatTipsTitle => 'Conseils de combat de base';

  @override
  String get bedwarsCombatTips1 =>
      'Sprintez toujours avant de frapper un adversaire pour un recul supplémentaire.';

  @override
  String get bedwarsCombatTips2 =>
      'Alternez entre attaque et blocage pour réduire les dégâts subis.';

  @override
  String get bedwarsCombatTips3 =>
      'Visez les coups critiques en attaquant pendant la chute après un saut.';

  @override
  String get bedwarsCombatTips4 =>
      'Évitez de combattre sur des ponts étroits où le recul est mortel.';

  @override
  String get bedwarsResourceManagementTitle =>
      'Gestion efficace des ressources & Améliorations';

  @override
  String get bedwarsResourceManagement1 =>
      'Visitez régulièrement les générateurs de diamants et d\'émeraudes sur les îles centrales.';

  @override
  String get bedwarsResourceManagement2 =>
      'Priorisez les améliorations d\'équipe comme le tranchant, la protection et les améliorations de forge.';

  @override
  String get bedwarsResourceManagement3 =>
      'Répartissez la collecte de ressources avec vos coéquipiers pour une progression plus rapide.';

  @override
  String get bedwarsResourceManagement4 =>
      'Économisez les émeraudes pour des objets puissants comme l\'armure en diamant ou les perles de l\'Ender.';

  @override
  String get bedwarsIntermediateDefenseTitle => 'Défense de lit intermédiaire';

  @override
  String get bedwarsIntermediateDefense1 =>
      'Superposez votre défense de lit : laine à l\'intérieur, pierre de l\'End au milieu, bois ou verre à l\'extérieur.';

  @override
  String get bedwarsIntermediateDefense2 =>
      'Utilisez du verre anti-explosion pour contrer les attaques TNT sur votre lit.';

  @override
  String get bedwarsIntermediateDefense3 =>
      'Placez des seaux d\'eau près de votre lit pour ralentir les attaquants.';

  @override
  String get bedwarsIntermediateDefense4 =>
      'Envisagez de placer de l\'obsidienne comme couche intérieure pour une durabilité maximale.';

  @override
  String get bedwarsTeamCoordinationTitle =>
      'Stratégies de coordination d\'équipe';

  @override
  String get bedwarsTeamCoordination1 =>
      'Attribuez des rôles : un joueur défend pendant que les autres attaquent ou collectent des ressources.';

  @override
  String get bedwarsTeamCoordination2 =>
      'Communiquez les positions ennemies et les attaques entrantes à votre équipe.';

  @override
  String get bedwarsTeamCoordination3 =>
      'Coordonnez des attaques simultanées sur les bases ennemies pour une pression maximale.';

  @override
  String get bedwarsTeamCoordination4 =>
      'Partagez les ressources avec les coéquipiers qui ont besoin d\'améliorations spécifiques.';

  @override
  String get bedwarsBridgeBuildingTitle =>
      'Techniques de construction de ponts';

  @override
  String get bedwarsBridgeBuilding1 =>
      'Entraînez-vous au speed-bridging en vous accroupissant au bord et en plaçant des blocs rapidement.';

  @override
  String get bedwarsBridgeBuilding2 =>
      'Construisez des ponts en léger zigzag pour éviter les tirs à l\'arc faciles.';

  @override
  String get bedwarsBridgeBuilding3 =>
      'Utilisez des blocs difficiles à casser comme la pierre de l\'End pour les ponts permanents.';

  @override
  String get bedwarsBridgeBuilding4 =>
      'Ayez toujours assez de blocs avant de commencer un pont vers une île ennemie.';

  @override
  String get bedwarsMidGameCombatTitle =>
      'Tactiques de combat en milieu de partie';

  @override
  String get bedwarsMidGameCombat1 =>
      'Utilisez des bâtons de recul pour pousser les ennemis des ponts et des îles.';

  @override
  String get bedwarsMidGameCombat2 =>
      'Portez un arc pour exercer une pression à distance en approchant des bases ennemies.';

  @override
  String get bedwarsMidGameCombat3 =>
      'Utilisez des boules de feu pour percer les défenses et projeter les joueurs dans le vide.';

  @override
  String get bedwarsMidGameCombat4 =>
      'Mangez toujours une pomme dorée avant de vous engager dans un combat difficile.';

  @override
  String get bedwarsAdvancedPvpTitle => 'Combat PvP avancé';

  @override
  String get bedwarsAdvancedPvp1 =>
      'Maîtrisez les combos W-tap en relâchant et en rappuyant sur avancer entre les coups.';

  @override
  String get bedwarsAdvancedPvp2 =>
      'Utilisez des cannes à pêche pour attirer les ennemis et réinitialiser leur sprint.';

  @override
  String get bedwarsAdvancedPvp3 =>
      'Déplacez-vous latéralement de manière imprévisible pour être plus difficile à toucher.';

  @override
  String get bedwarsAdvancedPvp4 =>
      'Combinez les tirages à la canne avec des coups d\'épée immédiats pour des combos dévastateurs.';

  @override
  String get bedwarsSpeedBridgingTitle => 'Speed-Bridging & Mouvements avancés';

  @override
  String get bedwarsSpeedBridging1 =>
      'Apprenez le ninja-bridging pour placer des blocs en avançant sans vous accroupir.';

  @override
  String get bedwarsSpeedBridging2 =>
      'Entraînez-vous au breezily bridging pour la vitesse de pont en ligne droite la plus rapide.';

  @override
  String get bedwarsSpeedBridging3 =>
      'Utilisez les block clutches pour vous sauver d\'une chute dans le vide.';

  @override
  String get bedwarsSpeedBridging4 =>
      'Maîtrisez le jump-bridging pour franchir les écarts rapidement pendant les rushes.';

  @override
  String get bedwarsRushStrategiesTitle => 'Stratégies de rush & Timing';

  @override
  String get bedwarsRushStrategies1 =>
      'Foncez sur la base ennemie la plus proche dans les 30 premières secondes pour un avantage précoce.';

  @override
  String get bedwarsRushStrategies2 =>
      'Achetez de la TNT et une pioche pour casser rapidement un lit défendu.';

  @override
  String get bedwarsRushStrategies3 =>
      'Chronométrez vos rushes quand les ennemis quittent leur base pour collecter des ressources.';

  @override
  String get bedwarsRushStrategies4 =>
      'Utilisez des potions d\'invisibilité pour des attaques surprises sur les lits bien défendus.';

  @override
  String get bedwarsEndgameTitle =>
      'Tactiques de fin de partie & Priorisation des ressources';

  @override
  String get bedwarsEndgame1 =>
      'Accumulez des perles de l\'Ender pour des évasions rapides et des engagements surprises.';

  @override
  String get bedwarsEndgame2 =>
      'Priorisez l\'armure en diamant et les améliorations de tranchant pour les combats finaux.';

  @override
  String get bedwarsEndgame3 =>
      'Contrôlez les générateurs au centre de la carte pour priver les équipes restantes de ressources.';

  @override
  String get bedwarsEndgame4 =>
      'Gardez des blocs d\'urgence et des pommes dorées prêts pour les moments décisifs.';

  @override
  String get bedwarsCounterStrategiesTitle =>
      'Contre-stratégies face aux tactiques courantes';

  @override
  String get bedwarsCounterStrategies1 =>
      'Contrez les rushers de ponts en plaçant des pièges du vide ou en utilisant des arcs à distance.';

  @override
  String get bedwarsCounterStrategies2 =>
      'Contre les attaques TNT, utilisez du verre anti-explosion et des couches d\'obsidienne.';

  @override
  String get bedwarsCounterStrategies3 =>
      'Contrez les joueurs invisibles en surveillant les particules d\'armure et les bruits de pas.';

  @override
  String get bedwarsCounterStrategies4 =>
      'Contre le spam de boules de feu, portez un seau d\'eau pour éteindre les feux et bloquer le recul.';

  @override
  String get aboutTitle =>
      'À propos de Chercheur de Gemmes, Minerais & Structures';

  @override
  String get aboutWhatTitle => '🎯 Ce que fait cette appli';

  @override
  String get aboutDescTitle =>
      'Découverte avancée de minerais & structures Minecraft';

  @override
  String get aboutDescBody =>
      'Entrez votre graine de monde et vos coordonnées de recherche pour découvrir les emplacements exacts de diamants, or, netherite, villages, forteresses et plus encore.';

  @override
  String get aboutResourcesTitle => '⛏️ Ressources prises en charge';

  @override
  String get aboutStructuresTitle => '🏘️ Structures prises en charge';

  @override
  String get aboutHowItWorksTitle => '🔍 Comment ça marche';

  @override
  String get aboutFeaturesTitle => '✨ Fonctionnalités clés';

  @override
  String get aboutSupportTitle => '☕ Soutenir le développement';

  @override
  String get aboutResourceDiamond => 'Diamant';

  @override
  String get aboutResourceGold => 'Or';

  @override
  String get aboutResourceNetherite => 'Netherite';

  @override
  String get aboutResourceIron => 'Fer';

  @override
  String get aboutResourceRedstone => 'Redstone';

  @override
  String get aboutResourceCoal => 'Charbon';

  @override
  String get aboutResourceLapis => 'Lapis';

  @override
  String get aboutStructureVillages => 'Villages 🏘️';

  @override
  String get aboutStructureStrongholds => 'Forteresses 🏰';

  @override
  String get aboutStructureDungeons => 'Donjons 🕳️';

  @override
  String get aboutStructureMineshafts => 'Mines abandonnées ⛏️';

  @override
  String get aboutStructureDesertTemples => 'Temples du désert 🏜️';

  @override
  String get aboutStructureJungleTemples => 'Temples de la jungle 🌿';

  @override
  String get aboutStructureOceanMonuments => 'Monuments océaniques 🌊';

  @override
  String get aboutStructureWoodlandMansions => 'Manoirs des bois 🏚️';

  @override
  String get aboutStructurePillagerOutposts => 'Avant-postes de pillards ⚔️';

  @override
  String get aboutStructureRuinedPortals => 'Portails en ruine 🌀';

  @override
  String get aboutStep1 =>
      'Entrez votre graine de monde dans l\'onglet Recherche';

  @override
  String get aboutStep2 =>
      'Définissez vos coordonnées de centre de recherche (X, Y, Z)';

  @override
  String get aboutStep3 => 'Choisissez votre rayon de recherche';

  @override
  String get aboutStep4 => 'Sélectionnez les minerais et structures à trouver';

  @override
  String get aboutStep5 =>
      'Appuyez sur \"Trouver\" pour découvrir les ressources à proximité';

  @override
  String get aboutStep6 =>
      'Consultez les résultats avec les coordonnées exactes';

  @override
  String get aboutFeature1 =>
      'Historique des graines récentes — Accès rapide aux 5 dernières graines';

  @override
  String get aboutFeature2 =>
      'Sauvegarde automatique des paramètres — Ne perdez jamais vos réglages de recherche';

  @override
  String get aboutFeature3 =>
      'Résultats par probabilité — Trouvez les emplacements les plus probables';

  @override
  String get aboutFeature4 => 'Multiplateforme — Web, mobile et bureau';

  @override
  String get aboutFeature5 => 'Thème sombre/clair — Choisissez votre ambiance';

  @override
  String get aboutBuyMeCoffee => 'Offrez-moi un café';

  @override
  String get aboutSupportBody =>
      'Aidez à garder cette appli gratuite et en amélioration ! Votre soutien permet de nouvelles fonctionnalités et un développement continu.';

  @override
  String get aboutSupportButton => 'Soutenir le développement';

  @override
  String get aboutFooterTip =>
      'Utilisez les graines récentes pour basculer rapidement entre les mondes !';

  @override
  String get aboutGotIt => 'Compris !';

  @override
  String get releaseNotesHeader => 'Notes de version — v1.0.50';

  @override
  String get releaseNotesBedwarsSection =>
      '🎮 Guide stratégique Bedwars — NOUVEAU !';

  @override
  String get releaseNotesBedwarsGuideTitle => 'Guide Bedwars complet';

  @override
  String get releaseNotesBedwarsGuideBody =>
      'Un onglet dédié avec des stratégies approfondies pour Bedwars. Couvre le rush en début de partie, la défense en milieu de partie et les tactiques de fin de partie pour dominer chaque match.';

  @override
  String get releaseNotesResourceStrategiesTitle =>
      'Stratégies de ressources & boutique';

  @override
  String get releaseNotesResourceStrategiesBody =>
      'Analyses détaillées des priorités de ressources, achats optimaux en boutique à chaque étape, et conseils de coordination d\'équipe pour les modes 2v2, 3v3 et 4v4.';

  @override
  String get releaseNotesDefenseAttackTitle =>
      'Schémas de défense & d\'attaque';

  @override
  String get releaseNotesDefenseAttackBody =>
      'Apprenez les dispositions de défense de lit, les techniques de rush par pont, les stratégies de boules de feu et comment contrer les tactiques ennemies courantes.';

  @override
  String get releaseNotesUiSection =>
      '🎨 Refonte moderne de l\'interface gamer';

  @override
  String get releaseNotesNeonTitle => 'Esthétique gamer néon';

  @override
  String get releaseNotesNeonBody =>
      'Refonte visuelle complète avec une palette de couleurs néon sur fond sombre. Accents verts, cyan et violets vibrants avec des effets de lueur subtils pour un look gaming moderne.';

  @override
  String get releaseNotesLightModeTitle => 'Mode clair amélioré';

  @override
  String get releaseNotesLightModeBody =>
      'Thème clair entièrement lisible avec des variantes d\'accent plus foncées. Chaque élément de texte respecte désormais les exigences de contraste sur les fonds clairs et sombres.';

  @override
  String get releaseNotesCardsTitle => 'Cartes & boutons redessinés';

  @override
  String get releaseNotesCardsBody =>
      'Cartes plates avec bordures néon, boutons d\'action en dégradé avec ombres lumineuses, et une barre d\'onglets plus épurée avec indicateurs néon remplacent l\'ancien thème Material vert.';

  @override
  String get releaseNotesAlgorithmSection =>
      '⛏️ Améliorations de l\'algorithme de recherche de minerais';

  @override
  String get releaseNotesNoiseTitle => 'Génération de bruit améliorée';

  @override
  String get releaseNotesNoiseBody =>
      'Implémentation améliorée du bruit de Perlin pour des calculs de probabilité de minerai plus précis, correspondant mieux aux schémas réels de génération du monde en jeu.';

  @override
  String get releaseNotesBiomeTitle => 'Meilleure détection des biomes';

  @override
  String get releaseNotesBiomeBody =>
      'Détection de biome et modélisation de distribution de minerai affinées. L\'or dans les badlands, les diamants en profondeur et la netherite dans le Nether sont tous prédits plus précisément.';

  @override
  String get releaseNotesPerformanceTitle =>
      'Performance de recherche optimisée';

  @override
  String get releaseNotesPerformanceBody =>
      'Exécution de recherche plus rapide avec un scan de chunks amélioré. La recherche complète de netherite et les requêtes à grand rayon se terminent plus efficacement.';

  @override
  String get releaseNotesHighlightsSection => '🎯 Points forts';

  @override
  String get releaseNotesHighlight1 =>
      'Guide Bedwars : Guide stratégique complet avec tactiques début/milieu/fin de partie';

  @override
  String get releaseNotesHighlight2 =>
      'Interface gamer : Accents néon, effets de lueur et thème sombre moderne';

  @override
  String get releaseNotesHighlight3 =>
      'Correction du mode clair : Tous les textes désormais lisibles sur fonds clairs';

  @override
  String get releaseNotesHighlight4 =>
      'Meilleure recherche de minerais : Prédictions plus précises pour tous les types de minerais';

  @override
  String get releaseNotesHighlight5 =>
      'Recherches plus rapides : Algorithmes optimisés pour des résultats plus rapides';

  @override
  String get releaseNotesHighlight6 =>
      'Disposition à 5 onglets : Recherche, Résultats, Guide, Bedwars et Mises à jour';

  @override
  String get releaseNotesTechnicalSection => '🔧 Améliorations techniques';

  @override
  String get releaseNotesTechnical1 =>
      'Système de thème centralisé avec aides de couleur adaptatives clair/sombre';

  @override
  String get releaseNotesTechnical2 =>
      'Composants GamerCard et GamerSectionHeader réutilisables';

  @override
  String get releaseNotesTechnical3 =>
      'Bruit de Perlin amélioré pour la modélisation de génération de minerai';

  @override
  String get releaseNotesTechnical4 =>
      'Meilleurs calculs de probabilité au niveau des chunks';

  @override
  String get releaseNotesTechnical5 =>
      'Reconstructions de widgets réduites pour un défilement plus fluide';

  @override
  String get releaseNotesPreviousSection => '📋 Mises à jour précédentes';

  @override
  String get releaseNotesV1042Title => 'v1.0.42 — Lapis-lazuli + Interface';

  @override
  String get releaseNotesV1042Body =>
      'Ajout de la recherche de lapis-lazuli. Les 7 minerais principaux sont pris en charge. Disposition de navigation à 4 onglets améliorée.';

  @override
  String get releaseNotesV1041Title =>
      'v1.0.41 — Historique des graines récentes';

  @override
  String get releaseNotesV1041Body =>
      'Historique automatique des graines avec accès rapide aux 5 dernières graines.';

  @override
  String get releaseNotesV1036Title =>
      'v1.0.36 — Mémoire de recherche complète';

  @override
  String get releaseNotesV1036Body =>
      'Persistance complète des paramètres de recherche.';

  @override
  String get releaseNotesV1027Title => 'v1.0.27 — Améliorations visuelles';

  @override
  String get releaseNotesV1027Body =>
      'Écran de démarrage et icônes mis à jour.';

  @override
  String get releaseNotesV1022Title =>
      'v1.0.22 — Découverte de minerais étendue';

  @override
  String get releaseNotesV1022Body =>
      'Ajout du fer, de la redstone, du charbon et du lapis-lazuli.';

  @override
  String get releaseNotesV1015Title => 'v1.0.15 — Découverte de structures';

  @override
  String get releaseNotesV1015Body =>
      'Villages, forteresses, donjons, temples et plus encore.';

  @override
  String get releaseNotesV1010Title => 'v1.0.10 — Version de base';

  @override
  String get releaseNotesV1010Body =>
      'Recherche de base de diamants, or et netherite.';

  @override
  String get releaseNotesTimelineSection => '🏆 Chronologie des versions';

  @override
  String get releaseNotesTimelineCurrent => 'Actuelle';

  @override
  String get releaseNotesTimelinePrevious => 'Précédente';

  @override
  String get releaseNotesTimelineEarlier => 'Antérieure';

  @override
  String get releaseNotesTimelineBedwarsUi => 'Bedwars + Interface';

  @override
  String get releaseNotesTimelineLapisUi => 'Lapis + Interface';

  @override
  String get releaseNotesTimelineRecentSeeds => 'Graines récentes';

  @override
  String get releaseNotesTimelineSearchMemory => 'Mémoire de recherche';

  @override
  String get releaseNotesTimelineVisualUpdates => 'Mises à jour visuelles';

  @override
  String get releaseNotesTimelineExtendedOres => 'Minerais étendus';

  @override
  String get releaseNotesTimelineStructures => 'Structures';

  @override
  String get releaseNotesTimelineCoreFeatures => 'Fonctionnalités de base';

  @override
  String get releaseNotesFooter =>
      'Nouveau : Guide Bedwars, interface gamer et recherche de minerais améliorée !';

  @override
  String get dialogReleaseNotesHeader => 'Notes de version - Version 1.0.41';

  @override
  String get dialogRecentSeedsSection =>
      '🌱 Historique des graines récentes - NOUVEAU !';

  @override
  String get dialogQuickSeedAccessTitle => 'Accès rapide aux graines';

  @override
  String get dialogQuickSeedAccessBody =>
      'Ne perdez plus jamais la trace de vos graines de monde préférées ! L\'appli sauvegarde maintenant automatiquement vos 5 dernières graines recherchées et les affiche comme options cliquables sous le champ de saisie. Appuyez simplement sur une graine récente pour la réutiliser instantanément.';

  @override
  String get dialogSmartSeedTitle => 'Gestion intelligente des graines';

  @override
  String get dialogSmartSeedBody =>
      'Les graines récentes sont gérées automatiquement - quand vous recherchez une graine à nouveau, elle remonte en haut de la liste. La graine la plus ancienne est automatiquement supprimée quand vous atteignez la limite de 5 graines. Tous les chiffres sont entièrement visibles avec un formatage monospace amélioré.';

  @override
  String get dialogEnhancedUxTitle => 'Expérience utilisateur améliorée';

  @override
  String get dialogEnhancedUxBody =>
      'Parfait pour les joueurs qui testent plusieurs graines ou reviennent à des mondes favoris. Plus besoin de taper manuellement de longs numéros de graine - cliquez et cherchez ! Les graines persistent entre les sessions de l\'appli.';

  @override
  String get dialogSearchMemorySection =>
      '💾 Fonction complète de mémoire de recherche';

  @override
  String get dialogAutoSaveTitle => 'Sauvegarde automatique des paramètres';

  @override
  String get dialogAutoSaveBody =>
      'L\'appli mémorise TOUS vos paramètres de recherche incluant la graine du monde, les coordonnées X/Y/Z et le rayon de recherche. Tout est automatiquement sauvegardé lors de la saisie et restauré au redémarrage de l\'appli.';

  @override
  String get dialogSeamlessTitle => 'Flux de travail fluide';

  @override
  String get dialogSeamlessBody =>
      'Reprenez vos sessions de recherche de minerais exactement là où vous les avez laissées. Plus besoin de ressaisir les coordonnées ou d\'ajuster les paramètres de recherche. Concentrez-vous sur la découverte de minerais !';

  @override
  String get dialogEnhancedUxSection => '🎯 Expérience utilisateur améliorée';

  @override
  String get dialogUxBullet1 =>
      'Graines récentes : Accès rapide à vos 5 dernières graines de monde recherchées';

  @override
  String get dialogUxBullet2 =>
      'Gain de temps : Élimine le besoin de mémoriser et ressaisir les paramètres de recherche';

  @override
  String get dialogUxBullet3 =>
      'Meilleure productivité : Concentrez-vous uniquement sur la découverte de minerais';

  @override
  String get dialogUxBullet4 =>
      'Multiplateforme : Fonctionne de manière cohérente sur toutes les plateformes supportées';

  @override
  String get dialogUxBullet5 =>
      'Valeurs par défaut intelligentes : Valeurs par défaut sensées pour les nouveaux utilisateurs';

  @override
  String get dialogUxBullet6 =>
      'Lisibilité améliorée : Police monospace pour une meilleure visibilité des numéros de graine';

  @override
  String get dialogTechSection => '🔧 Améliorations techniques';

  @override
  String get dialogTechBullet1 =>
      'Stockage des graines récentes : Historique persistant avec gestion automatique';

  @override
  String get dialogTechBullet2 =>
      'Support des polices hors ligne : Performance améliorée sans connexion internet';

  @override
  String get dialogTechBullet3 =>
      'Persistance complète : Tous les champs de texte sont automatiquement sauvegardés';

  @override
  String get dialogTechBullet4 =>
      'Stockage efficace : Utilise le stockage natif de la plateforme pour des performances optimales';

  @override
  String get dialogTechBullet5 =>
      'Stabilité améliorée : Meilleure gestion des erreurs et expérience utilisateur';

  @override
  String get dialogTechBullet6 =>
      'Visibilité complète des graines : Numéros de graine complets affichés sans troncature';

  @override
  String get dialogPreviousSection => '📋 Mises à jour précédentes';

  @override
  String get dialogV1036Title => 'Version 1.0.36 - Mémoire de recherche';

  @override
  String get dialogV1036Body =>
      'Persistance complète des paramètres de recherche incluant graine du monde, coordonnées et rayon.';

  @override
  String get dialogV1027Title => 'Version 1.0.27 - Mise à jour mineure';

  @override
  String get dialogV1027Body =>
      'Écran de démarrage et icônes mis à jour pour une meilleure cohérence visuelle.';

  @override
  String get dialogV1022Title =>
      'Version 1.0.22 - Découverte de minerais étendue';

  @override
  String get dialogV1022Body =>
      '⚪ Minerai de fer (Y -64 à 256, pic à Y 15 & Y 232)\n🔴 Minerai de redstone (Y -64 à 15, 90% à Y -64 à -59)\n⚫ Minerai de charbon (Y 0 à 256, pic à Y 96)\n🔵 Lapis-lazuli (Y -64 à 64, amélioré à Y 0-32)\nInterface améliorée avec sélection compacte de minerais et légende visuelle';

  @override
  String get dialogPlayersSection => '🎯 Parfait pour tous les joueurs';

  @override
  String get dialogPlayerBullet1 =>
      'Explorateurs de graines : Basculez rapidement entre vos graines de monde préférées';

  @override
  String get dialogPlayerBullet2 =>
      'Speedrunners : Accès rapide aux minerais essentiels avec paramètres sauvegardés';

  @override
  String get dialogPlayerBullet3 =>
      'Constructeurs : Fer pour les outils, redstone pour les mécanismes';

  @override
  String get dialogPlayerBullet4 =>
      'Joueurs réguliers : Continuation fluide des sessions de minage';

  @override
  String get dialogPlayerBullet5 =>
      'Nouveaux joueurs : Apprenez les niveaux de minage optimaux avec des paramètres persistants';

  @override
  String get dialogPlayerBullet6 =>
      'Créateurs de contenu : Gestion facile des graines pour présenter différents mondes';

  @override
  String get dialogFooter =>
      'NOUVEAU : Historique des graines récentes + tous les paramètres de recherche sauvegardés automatiquement !';

  @override
  String get dialogGotIt => 'Compris !';
}
