// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Buscador de Gemas, Minerales y Estructuras';

  @override
  String get appTitleFull =>
      'Buscador de Gemas, Minerales y Estructuras para MC – Encuentra Diamantes, Oro, Netherita y Más';

  @override
  String get searchTab => 'Buscar';

  @override
  String get resultsTab => 'Resultados';

  @override
  String get guideTab => 'Guía';

  @override
  String get bedwarsTab => 'Bedwars';

  @override
  String get updatesTab => 'Novedades';

  @override
  String get appInfoTooltip => 'Info de la App';

  @override
  String get lightThemeTooltip => 'Claro';

  @override
  String get darkThemeTooltip => 'Oscuro';

  @override
  String get languageTooltip => 'Idioma';

  @override
  String get errorEnableSearchType =>
      'Por favor activa al menos un tipo de búsqueda (Minerales o Estructuras)';

  @override
  String get errorSelectStructure =>
      'Por favor selecciona al menos un tipo de estructura para buscar';

  @override
  String get errorSelectOre =>
      'Por favor selecciona al menos un tipo de mineral para buscar';

  @override
  String errorGeneric(String message) {
    return 'Error: $message';
  }

  @override
  String get worldSettingsTitle => 'Configuración del Mundo';

  @override
  String get worldSeedLabel => 'Semilla del Mundo';

  @override
  String get worldSeedHint => 'Ingresa tu semilla del mundo';

  @override
  String get errorEmptySeed => 'Por favor ingresa una semilla del mundo';

  @override
  String get recentSeeds => 'Semillas Recientes';

  @override
  String get searchCenterTitle => 'Centro de Búsqueda';

  @override
  String get coordinateX => 'X';

  @override
  String get coordinateY => 'Y';

  @override
  String get coordinateZ => 'Z';

  @override
  String get searchRadiusLabel => 'Radio de Búsqueda (bloques)';

  @override
  String get errorEmptyRadius => 'Por favor ingresa el radio de búsqueda';

  @override
  String get errorRadiusPositive => 'El radio debe ser positivo';

  @override
  String get errorRadiusMax => 'Máx. 2000';

  @override
  String get errorFieldRequired => 'Requerido';

  @override
  String get errorFieldInvalid => 'Inválido';

  @override
  String get errorYRange => '-64 a 320';

  @override
  String get togglePlusMinus => 'Alternar +/-';

  @override
  String get oreTypeTitle => 'Tipo de Mineral';

  @override
  String get includeOresInSearch => 'Incluir Minerales en la Búsqueda';

  @override
  String get includeNetherGold => 'Incluir Oro del Nether';

  @override
  String get searchForNetherGold => 'Buscar Mineral de Oro del Nether';

  @override
  String get netheriteAncientDebris => 'Netherita (Escombros Antiguos)';

  @override
  String get legendDiamond => '💎 Diamante';

  @override
  String get legendGold => '🏅 Oro';

  @override
  String get legendIron => '⚪ Hierro';

  @override
  String get legendRedstone => '🔴 Redstone';

  @override
  String get legendCoal => '⚫ Carbón';

  @override
  String get legendLapis => '🔵 Lapislázuli';

  @override
  String get structureSearchTitle => 'Búsqueda de Estructuras';

  @override
  String get includeStructuresInSearch => 'Incluir Estructuras en la Búsqueda';

  @override
  String get selectStructuresToFind => 'Selecciona Estructuras a Buscar:';

  @override
  String get selectAll => 'Seleccionar Todo';

  @override
  String get clearAll => 'Limpiar Todo';

  @override
  String structuresSelected(int count) {
    return '$count estructuras seleccionadas';
  }

  @override
  String get findButton => 'Buscar';

  @override
  String get findAllNetheriteButton => 'Buscar Toda la Netherita';

  @override
  String get searchingButton => 'Buscando...';

  @override
  String get comprehensiveNetheriteSearch => 'Búsqueda Completa de Netherita';

  @override
  String get comprehensiveNetheriteBody =>
      '• Busca en todo el mundo (4000×4000 bloques)\n• Puede tardar 30-60 segundos\n• Muestra hasta 300 mejores ubicaciones\n• Ignora otras selecciones de minerales';

  @override
  String get regularSearchInfo =>
      'La búsqueda regular muestra los 250 mejores resultados (todos los tipos combinados)';

  @override
  String get loadingNetherite =>
      'Búsqueda completa de netherita en progreso...';

  @override
  String get loadingAnalyzing => 'Analizando generación del mundo...';

  @override
  String get loadingTimeMay => 'Esto puede tardar 30-60 segundos';

  @override
  String get noResultsYet => 'Sin resultados aún';

  @override
  String get useSearchTabToFind =>
      'Usa la pestaña de búsqueda para encontrar minerales';

  @override
  String get noResultsMatchFilters =>
      'Ningún resultado coincide con los filtros';

  @override
  String get tryAdjustingFilters =>
      'Intenta ajustar la configuración de filtros';

  @override
  String resultsCount(int total, int oreCount, int structureCount) {
    return '$total resultados  ·  $oreCount minerales  ·  $structureCount estructuras';
  }

  @override
  String get hideFilters => 'Ocultar filtros';

  @override
  String get showFilters => 'Mostrar filtros';

  @override
  String get oreFiltersLabel => 'Filtros de Minerales:';

  @override
  String get filterDiamonds => '💎 Diamantes';

  @override
  String get filterGold => '🏅 Oro';

  @override
  String get filterIron => '⚪ Hierro';

  @override
  String get filterRedstone => '🔴 Redstone';

  @override
  String get filterCoal => '⚫ Carbón';

  @override
  String get filterLapis => '🔵 Lapislázuli';

  @override
  String get filterNetherite => '🔥 Netherita';

  @override
  String get structureFiltersLabel => 'Filtros de Estructuras:';

  @override
  String get biomeFiltersLabel => 'Filtros de Biomas:';

  @override
  String get coordinateFiltersTitle => 'Filtros de Coordenadas';

  @override
  String get minX => 'Mín X';

  @override
  String get maxX => 'Máx X';

  @override
  String get minY => 'Mín Y';

  @override
  String get maxY => 'Máx Y';

  @override
  String get minZ => 'Mín Z';

  @override
  String get maxZ => 'Máx Z';

  @override
  String get clearAllFilters => 'Limpiar Todos los Filtros';

  @override
  String get copyCoordinates => 'Copiar coordenadas';

  @override
  String copiedCoordinates(String coords) {
    return 'Coordenadas copiadas: $coords';
  }

  @override
  String chunkLabel(int chunkX, int chunkZ) {
    return 'Chunk: ($chunkX, $chunkZ)';
  }

  @override
  String probabilityLabel(String percent) {
    return 'Probabilidad: $percent%';
  }

  @override
  String biomeLabel(String biome) {
    return 'Bioma: $biome';
  }

  @override
  String get guideDiamondTitle => 'Generación de Diamantes';

  @override
  String get guideDiamondIntro =>
      'Los diamantes aparecen en el Overworld entre Y -64 e Y 16.';

  @override
  String get guideDiamondOptimal => '🎯 Niveles Y Óptimos:';

  @override
  String get guideDiamondLevel1 =>
      '• Y -64 a -54: Capa pico de diamantes (80% probabilidad base)';

  @override
  String get guideDiamondLevel2 =>
      '• Y -53 a -48: Buena capa de diamantes (60% probabilidad base)';

  @override
  String get guideDiamondLevel3 =>
      '• Y -47 a -32: Capa decente de diamantes (40% probabilidad base)';

  @override
  String get guideDiamondLevel4 =>
      '• Y -31 a 16: Capa inferior de diamantes (20% probabilidad base)';

  @override
  String get guideGoldTitle => 'Generación de Oro';

  @override
  String get guideGoldIntro =>
      'El oro tiene diferentes patrones de generación según el bioma y la dimensión.';

  @override
  String get guideGoldOverworld => '🌍 Oro del Overworld (Y -64 a 32):';

  @override
  String get guideGoldLevel1 =>
      '• Y -47 a -16: Capa pico de oro (60% probabilidad base)';

  @override
  String get guideGoldLevel2 =>
      '• Y -64 a -48: Niveles inferiores (40% probabilidad base)';

  @override
  String get guideGoldLevel3 =>
      '• Y -15 a 32: Niveles superiores (30% probabilidad base)';

  @override
  String get guideGoldBadlands => '🏜️ Bioma Badlands/Mesa (¡BONUS!):';

  @override
  String get guideGoldBadlandsLevel =>
      '• Y 32 a 80: Excelente oro superficial (90% probabilidad base)';

  @override
  String get guideGoldBadlandsBonus =>
      '• ¡6 veces más oro que en biomas regulares!';

  @override
  String get guideNetheriteTitle => 'Netherita (Escombros Antiguos)';

  @override
  String get guideNetheriteIntro =>
      'Los Escombros Antiguos son el mineral más raro, encontrado solo en el Nether.';

  @override
  String get guideNetheriteOptimal => '🎯 Niveles Y del Nether (Y 8 a 22):';

  @override
  String get guideNetheriteLevel1 =>
      '• Y 13 a 17: Capa pico de escombros antiguos (90% probabilidad base)';

  @override
  String get guideNetheriteLevel2 =>
      '• Y 10 a 19: Buena capa de escombros antiguos (70% probabilidad base)';

  @override
  String get guideNetheriteLevel3 =>
      '• Y 8 a 22: Capa decente de escombros antiguos (50% probabilidad base)';

  @override
  String get guideNetheriteSearch => '🔍 Modos de Búsqueda:';

  @override
  String get guideNetheriteRegular =>
      '• Búsqueda Regular: Usa umbral mínimo de 15% de probabilidad';

  @override
  String get guideNetheriteComprehensive =>
      '• Búsqueda Completa: Usa umbral de 5%, cubre 4000x4000 bloques';

  @override
  String get guideIronTitle => 'Generación de Hierro';

  @override
  String get guideIronIntro =>
      'El hierro es uno de los minerales más versátiles y comunes.';

  @override
  String get guideIronOptimal => '🎯 Niveles Y Óptimos:';

  @override
  String get guideIronLevel1 =>
      '• Y 128 a 256: Generación de hierro en montañas (pico en Y 232)';

  @override
  String get guideIronLevel2 =>
      '• Y -24 a 56: Generación de hierro subterráneo (pico en Y 15)';

  @override
  String get guideIronLevel3 =>
      '• Y -64 a 72: Disponibilidad general de hierro (40% probabilidad base)';

  @override
  String get guideRedstoneTitle => 'Generación de Redstone';

  @override
  String get guideRedstoneIntro =>
      'Redstone es la clave para la automatización y mecanismos complejos.';

  @override
  String get guideRedstoneOptimal => '🎯 Niveles Y Óptimos (Y -64 a 15):';

  @override
  String get guideRedstoneLevel1 =>
      '• Y -64 a -59: Capa pico de redstone (90% probabilidad base)';

  @override
  String get guideRedstoneLevel2 =>
      '• Y -58 a -48: Buena capa de redstone (70% probabilidad base)';

  @override
  String get guideRedstoneLevel3 =>
      '• Y -47 a -32: Capa decente de redstone (50% probabilidad base)';

  @override
  String get guideRedstoneLevel4 =>
      '• Y -31 a 15: Capa inferior de redstone (30% probabilidad base)';

  @override
  String get guideCoalTitle => 'Generación de Carbón';

  @override
  String get guideCoalIntro =>
      'El carbón es el mineral más común y la fuente principal de combustible.';

  @override
  String get guideCoalOptimal => '🎯 Niveles Y Óptimos (Y 0 a 256):';

  @override
  String get guideCoalLevel1 =>
      '• Y 80 a 136: Generación pico de carbón (pico en Y 96)';

  @override
  String get guideCoalLevel2 =>
      '• Y 0 a 256: Disponibilidad general de carbón (60% probabilidad base)';

  @override
  String get guideLapisTitle => 'Generación de Lapislázuli';

  @override
  String get guideLapisIntro =>
      'El Lapislázuli aparece en el Overworld entre Y -64 e Y 64.';

  @override
  String get guideLapisOptimal => '🎯 Niveles Y Óptimos:';

  @override
  String get guideLapisLevel1 =>
      '• Y 0 a 32: Capa pico de lapislázuli (generación mejorada)';

  @override
  String get guideLapisLevel2 =>
      '• Y -64 a -1: Niveles inferiores (generación estándar)';

  @override
  String get guideLapisLevel3 =>
      '• Y 33 a 64: Niveles superiores (generación reducida)';

  @override
  String get guideStructureTitle => 'Generación de Estructuras';

  @override
  String get guideStructureIntro =>
      'Las estructuras se generan según la compatibilidad del bioma y la rareza.';

  @override
  String get guideStructureCommon =>
      '🏘️ Estructuras Comunes (Alta Tasa de Aparición):';

  @override
  String get guideStructureVillages =>
      '• Aldeas: Biomas de llanura, desierto, sabana, taiga';

  @override
  String get guideStructureOutposts =>
      '• Puestos de Saqueadores: Mismos biomas que las aldeas';

  @override
  String get guideStructurePortals =>
      '• Portales en Ruinas: Pueden aparecer en cualquier dimensión';

  @override
  String get guideStructureRare =>
      '🏛️ Estructuras Raras (Baja Tasa de Aparición):';

  @override
  String get guideStructureStrongholds =>
      '• Fortalezas: Subterráneas, solo 128 por mundo';

  @override
  String get guideStructureEndCities =>
      '• Ciudades del End: Islas exteriores de la dimensión del End';

  @override
  String get guideStructureMonuments =>
      '• Monumentos Oceánicos: Biomas de océano profundo';

  @override
  String get guideStructureAncientCities =>
      '• Ciudades Antiguas: Bioma de oscuridad profunda (Y -52)';

  @override
  String get proTipTitle => 'Consejo Pro';

  @override
  String get proTipBody =>
      'Esta herramienta proporciona predicciones estadísticas basadas en algoritmos de generación del juego de bloques. ¡Usa las coordenadas como puntos de partida para tus expediciones mineras y siempre explora las áreas circundantes cuando encuentres vetas de mineral!';

  @override
  String get bedwarsTierStarters => 'Principiantes';

  @override
  String get bedwarsTierPractitioners => 'Practicantes';

  @override
  String get bedwarsTierExperts => 'Expertos';

  @override
  String get bedwarsGameObjectiveTitle => 'Objetivo del Juego y Reglas';

  @override
  String get bedwarsGameObjective1 =>
      'Protege tu cama mientras intentas destruir las camas enemigas.';

  @override
  String get bedwarsGameObjective2 =>
      'Una vez que tu cama es destruida, ya no puedes reaparecer.';

  @override
  String get bedwarsGameObjective3 =>
      'El último equipo con un jugador sobreviviente gana la partida.';

  @override
  String get bedwarsGameObjective4 =>
      'Recolecta recursos de los generadores para comprar equipo y bloques.';

  @override
  String get bedwarsResourceGatheringTitle => 'Recolección Básica de Recursos';

  @override
  String get bedwarsResourceGathering1 =>
      'El hierro y el oro aparecen automáticamente en el generador de tu isla.';

  @override
  String get bedwarsResourceGathering2 =>
      'Quédate cerca de tu generador entre peleas para recolectar recursos.';

  @override
  String get bedwarsResourceGathering3 =>
      'El hierro se usa para bloques básicos y herramientas de la tienda.';

  @override
  String get bedwarsResourceGathering4 =>
      'El oro compra armadura más fuerte, armas y objetos de utilidad.';

  @override
  String get bedwarsPurchasingTitle => 'Compra de Objetos Esenciales';

  @override
  String get bedwarsPurchasing1 =>
      'Compra lana o piedra del End temprano para hacer puentes y defender la cama.';

  @override
  String get bedwarsPurchasing2 =>
      'Una espada de piedra es una mejora barata sobre la de madera.';

  @override
  String get bedwarsPurchasing3 =>
      'La armadura de hierro da un buen impulso defensivo para las primeras peleas.';

  @override
  String get bedwarsPurchasing4 =>
      'Consigue tijeras para cortar las defensas de lana rápidamente.';

  @override
  String get bedwarsBedDefenseTitle => 'Defensa Básica de la Cama';

  @override
  String get bedwarsBedDefense1 =>
      'Cubre tu cama con lana tan pronto como empiece la partida.';

  @override
  String get bedwarsBedDefense2 =>
      'Añade una segunda capa de piedra del End alrededor de la lana para protección extra.';

  @override
  String get bedwarsBedDefense3 =>
      'Nunca dejes tu cama completamente sin vigilancia al inicio del juego.';

  @override
  String get bedwarsBedDefense4 =>
      'Coloca bloques en todos los lados incluyendo la parte superior de la cama.';

  @override
  String get bedwarsCombatTipsTitle => 'Consejos Básicos de Combate';

  @override
  String get bedwarsCombatTips1 =>
      'Siempre corre antes de golpear a un oponente para mayor retroceso.';

  @override
  String get bedwarsCombatTips2 =>
      'Golpea y bloquea alternando ataque y bloqueo para reducir el daño recibido.';

  @override
  String get bedwarsCombatTips3 =>
      'Apunta a golpes críticos atacando mientras caes de un salto.';

  @override
  String get bedwarsCombatTips4 =>
      'Evita pelear en puentes estrechos donde el retroceso es mortal.';

  @override
  String get bedwarsResourceManagementTitle =>
      'Gestión Eficiente de Recursos y Mejoras';

  @override
  String get bedwarsResourceManagement1 =>
      'Visita los generadores de diamantes y esmeraldas en las islas centrales regularmente.';

  @override
  String get bedwarsResourceManagement2 =>
      'Prioriza mejoras de equipo como filo, protección y mejoras de forja.';

  @override
  String get bedwarsResourceManagement3 =>
      'Divide las tareas de recolección de recursos con compañeros para progresar más rápido.';

  @override
  String get bedwarsResourceManagement4 =>
      'Guarda esmeraldas para objetos poderosos como armadura de diamante o perlas de ender.';

  @override
  String get bedwarsIntermediateDefenseTitle => 'Defensa Intermedia de la Cama';

  @override
  String get bedwarsIntermediateDefense1 =>
      'Haz capas en tu defensa: lana adentro, piedra del End en medio, madera o vidrio afuera.';

  @override
  String get bedwarsIntermediateDefense2 =>
      'Usa vidrio a prueba de explosiones para contrarrestar ataques de TNT en tu cama.';

  @override
  String get bedwarsIntermediateDefense3 =>
      'Añade cubos de agua cerca de tu cama para ralentizar a los atacantes.';

  @override
  String get bedwarsIntermediateDefense4 =>
      'Considera colocar obsidiana como la capa más interna para máxima durabilidad.';

  @override
  String get bedwarsTeamCoordinationTitle =>
      'Estrategias de Coordinación de Equipo';

  @override
  String get bedwarsTeamCoordination1 =>
      'Asigna roles: un jugador defiende mientras otros atacan o recolectan recursos.';

  @override
  String get bedwarsTeamCoordination2 =>
      'Comunica las posiciones enemigas y los ataques entrantes a tu equipo.';

  @override
  String get bedwarsTeamCoordination3 =>
      'Coordina ataques simultáneos a bases enemigas para máxima presión.';

  @override
  String get bedwarsTeamCoordination4 =>
      'Comparte recursos con compañeros que necesiten mejoras específicas.';

  @override
  String get bedwarsBridgeBuildingTitle =>
      'Técnicas de Construcción de Puentes';

  @override
  String get bedwarsBridgeBuilding1 =>
      'Practica la construcción rápida de puentes agachándote en el borde y colocando bloques rápidamente.';

  @override
  String get bedwarsBridgeBuilding2 =>
      'Construye puentes con patrones de zigzag ligeros para evitar disparos fáciles de arco.';

  @override
  String get bedwarsBridgeBuilding3 =>
      'Usa bloques difíciles de romper como piedra del End para puentes permanentes.';

  @override
  String get bedwarsBridgeBuilding4 =>
      'Siempre lleva suficientes bloques antes de empezar un puente hacia una isla enemiga.';

  @override
  String get bedwarsMidGameCombatTitle =>
      'Tácticas de Combate a Mitad de Partida';

  @override
  String get bedwarsMidGameCombat1 =>
      'Usa palos con retroceso para empujar enemigos fuera de puentes e islas.';

  @override
  String get bedwarsMidGameCombat2 =>
      'Lleva un arco para presión a distancia mientras te acercas a bases enemigas.';

  @override
  String get bedwarsMidGameCombat3 =>
      'Usa bolas de fuego para destruir defensas y lanzar jugadores al vacío.';

  @override
  String get bedwarsMidGameCombat4 =>
      'Siempre come una manzana dorada antes de entrar en una pelea difícil.';

  @override
  String get bedwarsAdvancedPvpTitle => 'Combate PvP Avanzado';

  @override
  String get bedwarsAdvancedPvp1 =>
      'Domina los combos W-tap soltando y volviendo a presionar adelante entre golpes.';

  @override
  String get bedwarsAdvancedPvp2 =>
      'Usa cañas de pescar para atraer enemigos y reiniciar su sprint.';

  @override
  String get bedwarsAdvancedPvp3 =>
      'Muévete lateralmente en patrones impredecibles para ser más difícil de golpear.';

  @override
  String get bedwarsAdvancedPvp4 =>
      'Combina tirones de caña con golpes inmediatos de espada para combos devastadores.';

  @override
  String get bedwarsSpeedBridgingTitle =>
      'Construcción Rápida de Puentes y Movimiento Avanzado';

  @override
  String get bedwarsSpeedBridging1 =>
      'Aprende ninja-bridging para colocar bloques mientras avanzas sin agacharte.';

  @override
  String get bedwarsSpeedBridging2 =>
      'Practica breezily bridging para la velocidad más rápida de puente en línea recta.';

  @override
  String get bedwarsSpeedBridging3 =>
      'Usa block clutches para salvarte de caer al vacío.';

  @override
  String get bedwarsSpeedBridging4 =>
      'Domina el jump-bridging para cubrir huecos rápidamente durante ataques.';

  @override
  String get bedwarsRushStrategiesTitle =>
      'Estrategias de Ataque Rápido y Timing';

  @override
  String get bedwarsRushStrategies1 =>
      'Ataca la base enemiga más cercana en los primeros 30 segundos para una ventaja temprana.';

  @override
  String get bedwarsRushStrategies2 =>
      'Compra TNT y un pico para romper camas rápidamente en bases defendidas.';

  @override
  String get bedwarsRushStrategies3 =>
      'Sincroniza tus ataques cuando los enemigos dejan su base para recolectar recursos.';

  @override
  String get bedwarsRushStrategies4 =>
      'Usa pociones de invisibilidad para ataques sorpresa en camas bien defendidas.';

  @override
  String get bedwarsEndgameTitle =>
      'Tácticas de Final de Partida y Priorización de Recursos';

  @override
  String get bedwarsEndgame1 =>
      'Acumula perlas de ender para escapes rápidos y enfrentamientos sorpresa.';

  @override
  String get bedwarsEndgame2 =>
      'Prioriza armadura de diamante y mejoras de filo para las peleas finales.';

  @override
  String get bedwarsEndgame3 =>
      'Controla los generadores del centro del mapa para negar recursos a los equipos restantes.';

  @override
  String get bedwarsEndgame4 =>
      'Mantén bloques de emergencia y manzanas doradas listas para momentos decisivos.';

  @override
  String get bedwarsCounterStrategiesTitle =>
      'Contra-Estrategias Contra Jugadas Comunes';

  @override
  String get bedwarsCounterStrategies1 =>
      'Contrarresta a los que atacan por puentes colocando trampas de vacío o usando arcos a distancia.';

  @override
  String get bedwarsCounterStrategies2 =>
      'Contra ataques de TNT, usa vidrio a prueba de explosiones y capas de obsidiana.';

  @override
  String get bedwarsCounterStrategies3 =>
      'Contrarresta jugadores invisibles observando partículas de armadura y sonidos de pasos.';

  @override
  String get bedwarsCounterStrategies4 =>
      'Contra spam de bolas de fuego, lleva un cubo de agua para apagar fuegos y bloquear retroceso.';

  @override
  String get aboutTitle =>
      'Acerca de Buscador de Gemas, Minerales y Estructuras';

  @override
  String get aboutWhatTitle => '🎯 Qué Hace Esta App';

  @override
  String get aboutDescTitle =>
      'Descubrimiento Avanzado de Minerales y Estructuras de Minecraft';

  @override
  String get aboutDescBody =>
      'Ingresa tu semilla del mundo y coordenadas de búsqueda para descubrir ubicaciones exactas de diamantes, oro, netherita, aldeas, fortalezas y más.';

  @override
  String get aboutResourcesTitle => '⛏️ Recursos Soportados';

  @override
  String get aboutStructuresTitle => '🏘️ Estructuras Soportadas';

  @override
  String get aboutHowItWorksTitle => '🔍 Cómo Funciona';

  @override
  String get aboutFeaturesTitle => '✨ Características Principales';

  @override
  String get aboutSupportTitle => '☕ Apoya el Desarrollo';

  @override
  String get aboutResourceDiamond => 'Diamante';

  @override
  String get aboutResourceGold => 'Oro';

  @override
  String get aboutResourceNetherite => 'Netherita';

  @override
  String get aboutResourceIron => 'Hierro';

  @override
  String get aboutResourceRedstone => 'Redstone';

  @override
  String get aboutResourceCoal => 'Carbón';

  @override
  String get aboutResourceLapis => 'Lapislázuli';

  @override
  String get aboutStructureVillages => 'Aldeas 🏘️';

  @override
  String get aboutStructureStrongholds => 'Fortalezas 🏰';

  @override
  String get aboutStructureDungeons => 'Mazmorras 🕳️';

  @override
  String get aboutStructureMineshafts => 'Minas Abandonadas ⛏️';

  @override
  String get aboutStructureDesertTemples => 'Templos del Desierto 🏜️';

  @override
  String get aboutStructureJungleTemples => 'Templos de la Jungla 🌿';

  @override
  String get aboutStructureOceanMonuments => 'Monumentos Oceánicos 🌊';

  @override
  String get aboutStructureWoodlandMansions => 'Mansiones del Bosque 🏚️';

  @override
  String get aboutStructurePillagerOutposts => 'Puestos de Saqueadores ⚔️';

  @override
  String get aboutStructureRuinedPortals => 'Portales en Ruinas 🌀';

  @override
  String get aboutStep1 =>
      'Ingresa tu semilla del mundo en la pestaña de Búsqueda';

  @override
  String get aboutStep2 =>
      'Establece tus coordenadas del centro de búsqueda (X, Y, Z)';

  @override
  String get aboutStep3 => 'Elige tu radio de búsqueda';

  @override
  String get aboutStep4 => 'Selecciona qué minerales y estructuras buscar';

  @override
  String get aboutStep5 => 'Toca \"Buscar\" para descubrir recursos cercanos';

  @override
  String get aboutStep6 => 'Ve los resultados con coordenadas exactas';

  @override
  String get aboutFeature1 =>
      'Historial de Semillas Recientes — Acceso rápido a las últimas 5 semillas';

  @override
  String get aboutFeature2 =>
      'Guardado Automático de Parámetros — Nunca pierdas la configuración de búsqueda';

  @override
  String get aboutFeature3 =>
      'Resultados por Probabilidad — Encuentra las ubicaciones más probables';

  @override
  String get aboutFeature4 => 'Multiplataforma — Web, móvil y escritorio';

  @override
  String get aboutFeature5 => 'Tema Oscuro/Claro — Elige tu estilo';

  @override
  String get aboutBuyMeCoffee => 'Invítame un Café';

  @override
  String get aboutSupportBody =>
      '¡Ayuda a mantener esta app gratuita y en mejora! Tu apoyo permite nuevas funciones y desarrollo continuo.';

  @override
  String get aboutSupportButton => 'Apoyar el Desarrollo';

  @override
  String get aboutFooterTip =>
      '¡Usa Semillas Recientes para cambiar rápidamente entre mundos!';

  @override
  String get aboutGotIt => '¡Entendido!';

  @override
  String get releaseNotesHeader => 'Notas de la Versión — v1.0.50';

  @override
  String get releaseNotesBedwarsSection =>
      '🎮 Guía de Estrategia Bedwars — ¡NUEVO!';

  @override
  String get releaseNotesBedwarsGuideTitle => 'Guía Completa de Bedwars';

  @override
  String get releaseNotesBedwarsGuideBody =>
      'Una pestaña dedicada con estrategias detalladas para Bedwars. Cubre ataque temprano, defensa a mitad de partida y tácticas de final para ayudarte a dominar cada partida.';

  @override
  String get releaseNotesResourceStrategiesTitle =>
      'Estrategias de Recursos y Tienda';

  @override
  String get releaseNotesResourceStrategiesBody =>
      'Desgloses detallados de prioridades de recursos, compras óptimas en la tienda en cada etapa y consejos de coordinación de equipo para modos de 2, 3 y 4 jugadores.';

  @override
  String get releaseNotesDefenseAttackTitle => 'Patrones de Defensa y Ataque';

  @override
  String get releaseNotesDefenseAttackBody =>
      'Aprende diseños de defensa de cama, técnicas de ataque por puentes, estrategias con bolas de fuego y cómo contrarrestar tácticas enemigas comunes.';

  @override
  String get releaseNotesUiSection =>
      '🎨 Renovación Moderna de la Interfaz Gamer';

  @override
  String get releaseNotesNeonTitle => 'Estética Neón Gamer';

  @override
  String get releaseNotesNeonBody =>
      'Rediseño visual completo con paleta de colores neón sobre oscuro. Acentos vibrantes en verde, cian y púrpura con efectos de brillo sutiles para una sensación moderna de juego.';

  @override
  String get releaseNotesLightModeTitle => 'Modo Claro Mejorado';

  @override
  String get releaseNotesLightModeBody =>
      'Tema claro completamente legible con variantes de acentos más oscuros. Cada elemento de texto ahora cumple con los requisitos de contraste en fondos claros y oscuros.';

  @override
  String get releaseNotesCardsTitle => 'Tarjetas y Botones Rediseñados';

  @override
  String get releaseNotesCardsBody =>
      'Tarjetas planas con bordes de acento neón, botones de acción con degradado y sombras de brillo, y una barra de pestañas más limpia con indicadores neón reemplazan el antiguo tema verde Material.';

  @override
  String get releaseNotesAlgorithmSection =>
      '⛏️ Mejoras en el Algoritmo de Búsqueda de Minerales';

  @override
  String get releaseNotesNoiseTitle => 'Generación de Ruido Mejorada';

  @override
  String get releaseNotesNoiseBody =>
      'Implementación mejorada de ruido Perlin para cálculos de probabilidad de minerales más precisos que coinciden mejor con los patrones reales de generación del mundo en el juego.';

  @override
  String get releaseNotesBiomeTitle => 'Mejor Reconocimiento de Biomas';

  @override
  String get releaseNotesBiomeBody =>
      'Detección de biomas refinada y modelado de distribución de minerales. Oro en badlands, diamantes en niveles profundos y netherita en el nether se predicen con mayor precisión.';

  @override
  String get releaseNotesPerformanceTitle =>
      'Rendimiento de Búsqueda Optimizado';

  @override
  String get releaseNotesPerformanceBody =>
      'Ejecución de búsqueda más rápida con escaneo de chunks mejorado. La búsqueda completa de netherita y consultas de gran radio se completan más eficientemente.';

  @override
  String get releaseNotesHighlightsSection => '🎯 Destacados';

  @override
  String get releaseNotesHighlight1 =>
      'Guía Bedwars: Guía completa de estrategia con tácticas de inicio/medio/final de partida';

  @override
  String get releaseNotesHighlight2 =>
      'Interfaz Gamer: Acentos neón, efectos de brillo y tema oscuro moderno';

  @override
  String get releaseNotesHighlight3 =>
      'Corrección Modo Claro: Todo el texto ahora es legible en fondos claros';

  @override
  String get releaseNotesHighlight4 =>
      'Mejor Búsqueda de Minerales: Predicciones más precisas para todos los tipos de minerales';

  @override
  String get releaseNotesHighlight5 =>
      'Búsquedas Más Rápidas: Algoritmos optimizados para resultados más rápidos';

  @override
  String get releaseNotesHighlight6 =>
      'Diseño de 5 Pestañas: Buscar, Resultados, Guía, Bedwars y Novedades';

  @override
  String get releaseNotesTechnicalSection => '🔧 Mejoras Técnicas';

  @override
  String get releaseNotesTechnical1 =>
      'Sistema de temas centralizado con ayudantes de color adaptativo claro/oscuro';

  @override
  String get releaseNotesTechnical2 =>
      'Componentes reutilizables GamerCard y GamerSectionHeader';

  @override
  String get releaseNotesTechnical3 =>
      'Ruido Perlin mejorado para modelado de generación de minerales';

  @override
  String get releaseNotesTechnical4 =>
      'Mejores cálculos de probabilidad a nivel de chunk';

  @override
  String get releaseNotesTechnical5 =>
      'Reducción de reconstrucciones de widgets para desplazamiento más fluido';

  @override
  String get releaseNotesPreviousSection => '📋 Actualizaciones Anteriores';

  @override
  String get releaseNotesV1042Title => 'v1.0.42 — Lapislázuli + Interfaz';

  @override
  String get releaseNotesV1042Body =>
      'Se añadió búsqueda de Lapislázuli. Los 7 minerales principales soportados. Diseño de navegación mejorado con 4 pestañas.';

  @override
  String get releaseNotesV1041Title =>
      'v1.0.41 — Historial de Semillas Recientes';

  @override
  String get releaseNotesV1041Body =>
      'Historial automático de semillas con acceso rápido a las últimas 5 semillas.';

  @override
  String get releaseNotesV1036Title => 'v1.0.36 — Memoria de Búsqueda Completa';

  @override
  String get releaseNotesV1036Body =>
      'Persistencia completa de parámetros de búsqueda.';

  @override
  String get releaseNotesV1027Title => 'v1.0.27 — Mejoras Visuales';

  @override
  String get releaseNotesV1027Body =>
      'Pantalla de inicio e iconos actualizados.';

  @override
  String get releaseNotesV1022Title =>
      'v1.0.22 — Descubrimiento Extendido de Minerales';

  @override
  String get releaseNotesV1022Body =>
      'Se añadieron Hierro, Redstone, Carbón y Lapislázuli.';

  @override
  String get releaseNotesV1015Title =>
      'v1.0.15 — Descubrimiento de Estructuras';

  @override
  String get releaseNotesV1015Body =>
      'Aldeas, fortalezas, mazmorras, templos y más.';

  @override
  String get releaseNotesV1010Title => 'v1.0.10 — Versión Base';

  @override
  String get releaseNotesV1010Body =>
      'Búsqueda principal de diamantes, oro y netherita.';

  @override
  String get releaseNotesTimelineSection => '🏆 Línea de Tiempo de Versiones';

  @override
  String get releaseNotesTimelineCurrent => 'Actual';

  @override
  String get releaseNotesTimelinePrevious => 'Anterior';

  @override
  String get releaseNotesTimelineEarlier => 'Anteriores';

  @override
  String get releaseNotesTimelineBedwarsUi => 'Bedwars + Interfaz';

  @override
  String get releaseNotesTimelineLapisUi => 'Lapislázuli + Interfaz';

  @override
  String get releaseNotesTimelineRecentSeeds => 'Semillas Recientes';

  @override
  String get releaseNotesTimelineSearchMemory => 'Memoria de Búsqueda';

  @override
  String get releaseNotesTimelineVisualUpdates => 'Mejoras Visuales';

  @override
  String get releaseNotesTimelineExtendedOres => 'Minerales Extendidos';

  @override
  String get releaseNotesTimelineStructures => 'Estructuras';

  @override
  String get releaseNotesTimelineCoreFeatures => 'Funciones Principales';

  @override
  String get releaseNotesFooter =>
      '¡Nuevo: Guía Bedwars, interfaz gamer y búsqueda de minerales mejorada!';

  @override
  String get dialogReleaseNotesHeader => 'Notas de la Versión - Versión 1.0.41';

  @override
  String get dialogRecentSeedsSection =>
      '🌱 Historial de Semillas Recientes - ¡NUEVO!';

  @override
  String get dialogQuickSeedAccessTitle => 'Acceso Rápido a Semillas';

  @override
  String get dialogQuickSeedAccessBody =>
      '¡Nunca pierdas el rastro de tus semillas de mundo favoritas! La app ahora guarda automáticamente tus últimas 5 semillas buscadas y las muestra como opciones clicables debajo del campo de entrada de semilla. Simplemente toca cualquier semilla reciente para usarla de nuevo al instante.';

  @override
  String get dialogSmartSeedTitle => 'Gestión Inteligente de Semillas';

  @override
  String get dialogSmartSeedBody =>
      'Las semillas recientes se gestionan automáticamente - cuando buscas una semilla de nuevo, se mueve al inicio de la lista. La semilla más antigua se elimina automáticamente cuando alcanzas el límite de 5 semillas. Todos los dígitos de la semilla son completamente visibles con formato monoespaciado mejorado.';

  @override
  String get dialogEnhancedUxTitle => 'Experiencia de Usuario Mejorada';

  @override
  String get dialogEnhancedUxBody =>
      'Perfecto para jugadores que prueban múltiples semillas o regresan a mundos favoritos. ¡No más escribir manualmente números de semilla largos - simplemente haz clic y busca! Las semillas persisten entre sesiones de la app.';

  @override
  String get dialogSearchMemorySection =>
      '💾 Función Completa de Memoria de Búsqueda';

  @override
  String get dialogAutoSaveTitle => 'Guardado Automático de Parámetros';

  @override
  String get dialogAutoSaveBody =>
      'La app recuerda TODOS tus parámetros de búsqueda incluyendo semilla del mundo, coordenadas X/Y/Z y radio de búsqueda. Todo se guarda automáticamente al escribir y se restaura al reiniciar la app.';

  @override
  String get dialogSeamlessTitle => 'Flujo de Trabajo Continuo';

  @override
  String get dialogSeamlessBody =>
      'Continúa tus sesiones de búsqueda de minerales exactamente donde las dejaste. No más reingresar coordenadas o ajustar configuraciones de búsqueda. ¡Concéntrate en encontrar minerales!';

  @override
  String get dialogEnhancedUxSection => '🎯 Experiencia de Usuario Mejorada';

  @override
  String get dialogUxBullet1 =>
      'Semillas Recientes: Acceso rápido a tus últimas 5 semillas de mundo buscadas';

  @override
  String get dialogUxBullet2 =>
      'Ahorro de Tiempo: Elimina la necesidad de recordar y reingresar parámetros de búsqueda';

  @override
  String get dialogUxBullet3 =>
      'Mejor Productividad: Concéntrate puramente en el descubrimiento de minerales';

  @override
  String get dialogUxBullet4 =>
      'Multiplataforma: Funciona consistentemente en todas las plataformas soportadas';

  @override
  String get dialogUxBullet5 =>
      'Valores Predeterminados Inteligentes: Valores predeterminados sensatos para nuevos usuarios';

  @override
  String get dialogUxBullet6 =>
      'Legibilidad Mejorada: Fuente monoespaciada para mejor visibilidad de números de semilla';

  @override
  String get dialogTechSection => '🔧 Mejoras Técnicas';

  @override
  String get dialogTechBullet1 =>
      'Almacenamiento de Semillas Recientes: Historial persistente con gestión automática';

  @override
  String get dialogTechBullet2 =>
      'Soporte de Fuentes Offline: Rendimiento mejorado sin conexión a internet';

  @override
  String get dialogTechBullet3 =>
      'Persistencia Completa: Todos los campos de texto se guardan automáticamente';

  @override
  String get dialogTechBullet4 =>
      'Almacenamiento Eficiente: Usa almacenamiento nativo de la plataforma para rendimiento óptimo';

  @override
  String get dialogTechBullet5 =>
      'Estabilidad Mejorada: Mejor manejo de errores y experiencia de usuario';

  @override
  String get dialogTechBullet6 =>
      'Visibilidad Completa de Semillas: Números de semilla completos sin truncamiento';

  @override
  String get dialogPreviousSection => '📋 Actualizaciones Anteriores';

  @override
  String get dialogV1036Title => 'Versión 1.0.36 - Memoria de Búsqueda';

  @override
  String get dialogV1036Body =>
      'Persistencia completa de parámetros de búsqueda incluyendo semilla del mundo, coordenadas y radio.';

  @override
  String get dialogV1027Title => 'Versión 1.0.27 - Actualización Menor';

  @override
  String get dialogV1027Body =>
      'Pantalla de inicio e iconos actualizados para mejor consistencia visual.';

  @override
  String get dialogV1022Title =>
      'Versión 1.0.22 - Descubrimiento Extendido de Minerales';

  @override
  String get dialogV1022Body =>
      '⚪ Mineral de Hierro (Y -64 a 256, pico en Y 15 y Y 232)\n🔴 Mineral de Redstone (Y -64 a 15, 90% en Y -64 a -59)\n⚫ Mineral de Carbón (Y 0 a 256, pico en Y 96)\n🔵 Lapislázuli (Y -64 a 64, mejorado en Y 0-32)\nUI mejorada con selección compacta de minerales y leyenda visual';

  @override
  String get dialogPlayersSection => '🎯 Perfecto para Todos los Jugadores';

  @override
  String get dialogPlayerBullet1 =>
      'Exploradores de Semillas: Cambia rápidamente entre semillas de mundo favoritas';

  @override
  String get dialogPlayerBullet2 =>
      'Speedrunners: Acceso rápido a minerales esenciales con parámetros guardados';

  @override
  String get dialogPlayerBullet3 =>
      'Constructores: Hierro para herramientas, redstone para mecanismos';

  @override
  String get dialogPlayerBullet4 =>
      'Jugadores Regulares: Continuación fluida de sesiones de minería';

  @override
  String get dialogPlayerBullet5 =>
      'Nuevos Jugadores: Aprende niveles óptimos de minería con configuraciones persistentes';

  @override
  String get dialogPlayerBullet6 =>
      'Creadores de Contenido: Gestión fácil de semillas para mostrar diferentes mundos';

  @override
  String get dialogFooter =>
      '¡NUEVO: Historial de semillas recientes + todos los parámetros de búsqueda guardados automáticamente!';

  @override
  String get dialogGotIt => '¡Entendido!';
}
