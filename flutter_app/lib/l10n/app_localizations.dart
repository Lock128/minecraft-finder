import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja')
  ];

  /// Main app title displayed in the AppBar
  ///
  /// In en, this message translates to:
  /// **'Gem, Ore & Struct Finder'**
  String get appTitle;

  /// Full app title used in MaterialApp title property
  ///
  /// In en, this message translates to:
  /// **'Gem, Ore & Struct Finder for MC - Find Diamonds, Gold, Netherite & More'**
  String get appTitleFull;

  /// Label for the Search tab
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTab;

  /// Label for the Results tab
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultsTab;

  /// Label for the User Guide tab
  ///
  /// In en, this message translates to:
  /// **'User Guide'**
  String get guideTab;

  /// Label for the Bedwars tab
  ///
  /// In en, this message translates to:
  /// **'Bedwars'**
  String get bedwarsTab;

  /// Label for the Updates tab
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updatesTab;

  /// Tooltip for the app info button in AppBar
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get appInfoTooltip;

  /// Tooltip for switching to light theme
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightThemeTooltip;

  /// Tooltip for switching to dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkThemeTooltip;

  /// Tooltip for the language switcher button
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTooltip;

  /// Snackbar error when no search type is enabled
  ///
  /// In en, this message translates to:
  /// **'Please enable at least one search type (Ores or Structures)'**
  String get errorEnableSearchType;

  /// Snackbar error when structures enabled but none selected
  ///
  /// In en, this message translates to:
  /// **'Please select at least one structure type to search for'**
  String get errorSelectStructure;

  /// Snackbar error when ores enabled but none selected
  ///
  /// In en, this message translates to:
  /// **'Please select at least one ore type to search for'**
  String get errorSelectOre;

  /// Generic error message shown in snackbar
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorGeneric(String message);

  /// Section header for world settings card
  ///
  /// In en, this message translates to:
  /// **'World Settings'**
  String get worldSettingsTitle;

  /// Label for the world seed text field
  ///
  /// In en, this message translates to:
  /// **'World Seed'**
  String get worldSeedLabel;

  /// Hint text for the world seed text field
  ///
  /// In en, this message translates to:
  /// **'Enter your world seed'**
  String get worldSeedHint;

  /// Validation error when seed field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a world seed'**
  String get errorEmptySeed;

  /// Label for the recent seeds section
  ///
  /// In en, this message translates to:
  /// **'Recent Seeds'**
  String get recentSeeds;

  /// Section header for search center card
  ///
  /// In en, this message translates to:
  /// **'Search Center'**
  String get searchCenterTitle;

  /// Label for X coordinate field
  ///
  /// In en, this message translates to:
  /// **'X'**
  String get coordinateX;

  /// Label for Y coordinate field
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get coordinateY;

  /// Label for Z coordinate field
  ///
  /// In en, this message translates to:
  /// **'Z'**
  String get coordinateZ;

  /// Label for the search radius field
  ///
  /// In en, this message translates to:
  /// **'Search Radius (blocks)'**
  String get searchRadiusLabel;

  /// Validation error when radius field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter search radius'**
  String get errorEmptyRadius;

  /// Validation error when radius is not positive
  ///
  /// In en, this message translates to:
  /// **'Radius must be positive'**
  String get errorRadiusPositive;

  /// Validation error when radius exceeds 2000
  ///
  /// In en, this message translates to:
  /// **'Max 2000'**
  String get errorRadiusMax;

  /// Validation error for required coordinate fields
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get errorFieldRequired;

  /// Validation error for invalid coordinate values
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get errorFieldInvalid;

  /// Validation error for Y coordinate out of range
  ///
  /// In en, this message translates to:
  /// **'-64 to 320'**
  String get errorYRange;

  /// Tooltip for the coordinate sign toggle button
  ///
  /// In en, this message translates to:
  /// **'Toggle +/-'**
  String get togglePlusMinus;

  /// Section header for ore selection card
  ///
  /// In en, this message translates to:
  /// **'Ore Type'**
  String get oreTypeTitle;

  /// Toggle button label for including ores
  ///
  /// In en, this message translates to:
  /// **'Include Ores in Search'**
  String get includeOresInSearch;

  /// Checkbox label for including nether gold
  ///
  /// In en, this message translates to:
  /// **'Include Nether Gold'**
  String get includeNetherGold;

  /// Subtitle for the nether gold checkbox
  ///
  /// In en, this message translates to:
  /// **'Search for Nether Gold Ore'**
  String get searchForNetherGold;

  /// Label for the netherite toggle button
  ///
  /// In en, this message translates to:
  /// **'Netherite (Ancient Debris)'**
  String get netheriteAncientDebris;

  /// Legend label for diamond ore
  ///
  /// In en, this message translates to:
  /// **'💎 Diamond'**
  String get legendDiamond;

  /// Legend label for gold ore
  ///
  /// In en, this message translates to:
  /// **'🏅 Gold'**
  String get legendGold;

  /// Legend label for iron ore
  ///
  /// In en, this message translates to:
  /// **'⚪ Iron'**
  String get legendIron;

  /// Legend label for redstone ore
  ///
  /// In en, this message translates to:
  /// **'🔴 Redstone'**
  String get legendRedstone;

  /// Legend label for coal ore
  ///
  /// In en, this message translates to:
  /// **'⚫ Coal'**
  String get legendCoal;

  /// Legend label for lapis ore
  ///
  /// In en, this message translates to:
  /// **'🔵 Lapis'**
  String get legendLapis;

  /// Section header for structure selection card
  ///
  /// In en, this message translates to:
  /// **'Structure Search'**
  String get structureSearchTitle;

  /// Toggle button label for including structures
  ///
  /// In en, this message translates to:
  /// **'Include Structures in Search'**
  String get includeStructuresInSearch;

  /// Instruction text above structure selection chips
  ///
  /// In en, this message translates to:
  /// **'Select Structures to Find:'**
  String get selectStructuresToFind;

  /// Button label to select all structures
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// Button label to clear all structure selections
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// Count of selected structures
  ///
  /// In en, this message translates to:
  /// **'{count} structures selected'**
  String structuresSelected(int count);

  /// Label for the regular find button
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get findButton;

  /// Label for the comprehensive netherite search button
  ///
  /// In en, this message translates to:
  /// **'Find All Netherite'**
  String get findAllNetheriteButton;

  /// Label shown on search button while loading
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searchingButton;

  /// Title for the netherite search info box
  ///
  /// In en, this message translates to:
  /// **'Comprehensive Netherite Search'**
  String get comprehensiveNetheriteSearch;

  /// Body text for the netherite search info box
  ///
  /// In en, this message translates to:
  /// **'• Searches entire world (4000×4000 blocks)\n• May take 30-60 seconds\n• Shows up to 300 best locations\n• Ignores other ore selections'**
  String get comprehensiveNetheriteBody;

  /// Info text for regular search
  ///
  /// In en, this message translates to:
  /// **'Regular search shows top 250 results (all types combined)'**
  String get regularSearchInfo;

  /// Loading message during comprehensive netherite search
  ///
  /// In en, this message translates to:
  /// **'Comprehensive netherite search in progress...'**
  String get loadingNetherite;

  /// Loading message during regular search
  ///
  /// In en, this message translates to:
  /// **'Analyzing world generation...'**
  String get loadingAnalyzing;

  /// Subtitle shown during comprehensive netherite search
  ///
  /// In en, this message translates to:
  /// **'This may take 30-60 seconds'**
  String get loadingTimeMay;

  /// Empty state title when no search has been performed
  ///
  /// In en, this message translates to:
  /// **'No results yet'**
  String get noResultsYet;

  /// Empty state subtitle prompting user to search
  ///
  /// In en, this message translates to:
  /// **'Use the search tab to find ores'**
  String get useSearchTabToFind;

  /// Title when filters exclude all results
  ///
  /// In en, this message translates to:
  /// **'No results match filters'**
  String get noResultsMatchFilters;

  /// Subtitle when filters exclude all results
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filter settings'**
  String get tryAdjustingFilters;

  /// Results summary showing total, ore, and structure counts
  ///
  /// In en, this message translates to:
  /// **'{total} results  ·  {oreCount} ores  ·  {structureCount} structures'**
  String resultsCount(int total, int oreCount, int structureCount);

  /// Tooltip to hide the filter panel
  ///
  /// In en, this message translates to:
  /// **'Hide filters'**
  String get hideFilters;

  /// Tooltip to show the filter panel
  ///
  /// In en, this message translates to:
  /// **'Show filters'**
  String get showFilters;

  /// Label for the ore filter section
  ///
  /// In en, this message translates to:
  /// **'Ore Filters:'**
  String get oreFiltersLabel;

  /// Filter chip label for diamonds
  ///
  /// In en, this message translates to:
  /// **'💎 Diamonds'**
  String get filterDiamonds;

  /// Filter chip label for gold
  ///
  /// In en, this message translates to:
  /// **'🏅 Gold'**
  String get filterGold;

  /// Filter chip label for iron
  ///
  /// In en, this message translates to:
  /// **'⚪ Iron'**
  String get filterIron;

  /// Filter chip label for redstone
  ///
  /// In en, this message translates to:
  /// **'🔴 Redstone'**
  String get filterRedstone;

  /// Filter chip label for coal
  ///
  /// In en, this message translates to:
  /// **'⚫ Coal'**
  String get filterCoal;

  /// Filter chip label for lapis
  ///
  /// In en, this message translates to:
  /// **'🔵 Lapis'**
  String get filterLapis;

  /// Filter chip label for netherite
  ///
  /// In en, this message translates to:
  /// **'🔥 Netherite'**
  String get filterNetherite;

  /// Label for the structure filter section
  ///
  /// In en, this message translates to:
  /// **'Structure Filters:'**
  String get structureFiltersLabel;

  /// Label for the biome filter section
  ///
  /// In en, this message translates to:
  /// **'Biome Filters:'**
  String get biomeFiltersLabel;

  /// Title for the coordinate filter section
  ///
  /// In en, this message translates to:
  /// **'Coordinate Filters'**
  String get coordinateFiltersTitle;

  /// Label for minimum X coordinate filter
  ///
  /// In en, this message translates to:
  /// **'Min X'**
  String get minX;

  /// Label for maximum X coordinate filter
  ///
  /// In en, this message translates to:
  /// **'Max X'**
  String get maxX;

  /// Label for minimum Y coordinate filter
  ///
  /// In en, this message translates to:
  /// **'Min Y'**
  String get minY;

  /// Label for maximum Y coordinate filter
  ///
  /// In en, this message translates to:
  /// **'Max Y'**
  String get maxY;

  /// Label for minimum Z coordinate filter
  ///
  /// In en, this message translates to:
  /// **'Min Z'**
  String get minZ;

  /// Label for maximum Z coordinate filter
  ///
  /// In en, this message translates to:
  /// **'Max Z'**
  String get maxZ;

  /// Button label to clear all coordinate filters
  ///
  /// In en, this message translates to:
  /// **'Clear All Filters'**
  String get clearAllFilters;

  /// Tooltip for the copy coordinates button
  ///
  /// In en, this message translates to:
  /// **'Copy coordinates'**
  String get copyCoordinates;

  /// Snackbar message after copying coordinates
  ///
  /// In en, this message translates to:
  /// **'Copied coordinates: {coords}'**
  String copiedCoordinates(String coords);

  /// Chunk coordinates label in result cards
  ///
  /// In en, this message translates to:
  /// **'Chunk: ({chunkX}, {chunkZ})'**
  String chunkLabel(int chunkX, int chunkZ);

  /// Probability percentage label in result cards
  ///
  /// In en, this message translates to:
  /// **'Probability: {percent}%'**
  String probabilityLabel(String percent);

  /// Biome name label in result cards
  ///
  /// In en, this message translates to:
  /// **'Biome: {biome}'**
  String biomeLabel(String biome);

  /// Guide card title for diamond generation
  ///
  /// In en, this message translates to:
  /// **'Diamond Generation'**
  String get guideDiamondTitle;

  /// Diamond generation intro text
  ///
  /// In en, this message translates to:
  /// **'Diamonds spawn in the Overworld between Y -64 and Y 16.'**
  String get guideDiamondIntro;

  /// Diamond optimal Y levels subheading
  ///
  /// In en, this message translates to:
  /// **'🎯 Optimal Y Levels:'**
  String get guideDiamondOptimal;

  /// Diamond peak layer description
  ///
  /// In en, this message translates to:
  /// **'• Y -64 to -54: Peak diamond layer (80% base probability)'**
  String get guideDiamondLevel1;

  /// Diamond good layer description
  ///
  /// In en, this message translates to:
  /// **'• Y -53 to -48: Good diamond layer (60% base probability)'**
  String get guideDiamondLevel2;

  /// Diamond decent layer description
  ///
  /// In en, this message translates to:
  /// **'• Y -47 to -32: Decent diamond layer (40% base probability)'**
  String get guideDiamondLevel3;

  /// Diamond lower layer description
  ///
  /// In en, this message translates to:
  /// **'• Y -31 to 16: Lower diamond layer (20% base probability)'**
  String get guideDiamondLevel4;

  /// Guide card title for gold generation
  ///
  /// In en, this message translates to:
  /// **'Gold Generation'**
  String get guideGoldTitle;

  /// Gold generation intro text
  ///
  /// In en, this message translates to:
  /// **'Gold has different generation patterns based on biome and dimension.'**
  String get guideGoldIntro;

  /// Gold overworld subheading
  ///
  /// In en, this message translates to:
  /// **'🌍 Overworld Gold (Y -64 to 32):'**
  String get guideGoldOverworld;

  /// Gold peak layer description
  ///
  /// In en, this message translates to:
  /// **'• Y -47 to -16: Peak gold layer (60% base probability)'**
  String get guideGoldLevel1;

  /// Gold lower levels description
  ///
  /// In en, this message translates to:
  /// **'• Y -64 to -48: Lower levels (40% base probability)'**
  String get guideGoldLevel2;

  /// Gold higher levels description
  ///
  /// In en, this message translates to:
  /// **'• Y -15 to 32: Higher levels (30% base probability)'**
  String get guideGoldLevel3;

  /// Gold badlands subheading
  ///
  /// In en, this message translates to:
  /// **'🏜️ Badlands/Mesa Biome (BONUS!):'**
  String get guideGoldBadlands;

  /// Gold badlands level description
  ///
  /// In en, this message translates to:
  /// **'• Y 32 to 80: Excellent surface gold (90% base probability)'**
  String get guideGoldBadlandsLevel;

  /// Gold badlands bonus description
  ///
  /// In en, this message translates to:
  /// **'• 6x more gold than regular biomes!'**
  String get guideGoldBadlandsBonus;

  /// Guide card title for netherite generation
  ///
  /// In en, this message translates to:
  /// **'Netherite (Ancient Debris)'**
  String get guideNetheriteTitle;

  /// Netherite generation intro text
  ///
  /// In en, this message translates to:
  /// **'Ancient Debris is the rarest ore, found only in the Nether.'**
  String get guideNetheriteIntro;

  /// Netherite optimal Y levels subheading
  ///
  /// In en, this message translates to:
  /// **'🎯 Nether Y Levels (Y 8 to 22):'**
  String get guideNetheriteOptimal;

  /// Netherite peak layer description
  ///
  /// In en, this message translates to:
  /// **'• Y 13 to 17: Peak ancient debris layer (90% base probability)'**
  String get guideNetheriteLevel1;

  /// Netherite good layer description
  ///
  /// In en, this message translates to:
  /// **'• Y 10 to 19: Good ancient debris layer (70% base probability)'**
  String get guideNetheriteLevel2;

  /// Netherite decent layer description
  ///
  /// In en, this message translates to:
  /// **'• Y 8 to 22: Decent ancient debris layer (50% base probability)'**
  String get guideNetheriteLevel3;

  /// Netherite search modes subheading
  ///
  /// In en, this message translates to:
  /// **'🔍 Search Modes:'**
  String get guideNetheriteSearch;

  /// Netherite regular search description
  ///
  /// In en, this message translates to:
  /// **'• Regular Search: Uses minimum 15% probability threshold'**
  String get guideNetheriteRegular;

  /// Netherite comprehensive search description
  ///
  /// In en, this message translates to:
  /// **'• Comprehensive Search: Uses 5% threshold, covers 4000x4000 blocks'**
  String get guideNetheriteComprehensive;

  /// Guide card title for iron generation
  ///
  /// In en, this message translates to:
  /// **'Iron Generation'**
  String get guideIronTitle;

  /// Iron generation intro text
  ///
  /// In en, this message translates to:
  /// **'Iron is one of the most versatile and common ores.'**
  String get guideIronIntro;

  /// Iron optimal Y levels subheading
  ///
  /// In en, this message translates to:
  /// **'🎯 Optimal Y Levels:'**
  String get guideIronOptimal;

  /// Iron mountain level description
  ///
  /// In en, this message translates to:
  /// **'• Y 128 to 256: Mountain iron generation (peaks at Y 232)'**
  String get guideIronLevel1;

  /// Iron underground level description
  ///
  /// In en, this message translates to:
  /// **'• Y -24 to 56: Underground iron generation (peaks at Y 15)'**
  String get guideIronLevel2;

  /// Iron general availability description
  ///
  /// In en, this message translates to:
  /// **'• Y -64 to 72: General iron availability (40% base probability)'**
  String get guideIronLevel3;

  /// Guide card title for redstone generation
  ///
  /// In en, this message translates to:
  /// **'Redstone Generation'**
  String get guideRedstoneTitle;

  /// Redstone generation intro text
  ///
  /// In en, this message translates to:
  /// **'Redstone is the key to automation and complex contraptions.'**
  String get guideRedstoneIntro;

  /// Redstone optimal Y levels subheading
  ///
  /// In en, this message translates to:
  /// **'🎯 Optimal Y Levels (Y -64 to 15):'**
  String get guideRedstoneOptimal;

  /// Redstone peak layer description
  ///
  /// In en, this message translates to:
  /// **'• Y -64 to -59: Peak redstone layer (90% base probability)'**
  String get guideRedstoneLevel1;

  /// Redstone good layer description
  ///
  /// In en, this message translates to:
  /// **'• Y -58 to -48: Good redstone layer (70% base probability)'**
  String get guideRedstoneLevel2;

  /// Redstone decent layer description
  ///
  /// In en, this message translates to:
  /// **'• Y -47 to -32: Decent redstone layer (50% base probability)'**
  String get guideRedstoneLevel3;

  /// Redstone lower layer description
  ///
  /// In en, this message translates to:
  /// **'• Y -31 to 15: Lower redstone layer (30% base probability)'**
  String get guideRedstoneLevel4;

  /// Guide card title for coal generation
  ///
  /// In en, this message translates to:
  /// **'Coal Generation'**
  String get guideCoalTitle;

  /// Coal generation intro text
  ///
  /// In en, this message translates to:
  /// **'Coal is the most common ore and primary fuel source.'**
  String get guideCoalIntro;

  /// Coal optimal Y levels subheading
  ///
  /// In en, this message translates to:
  /// **'🎯 Optimal Y Levels (Y 0 to 256):'**
  String get guideCoalOptimal;

  /// Coal peak layer description
  ///
  /// In en, this message translates to:
  /// **'• Y 80 to 136: Peak coal generation (peaks at Y 96)'**
  String get guideCoalLevel1;

  /// Coal general availability description
  ///
  /// In en, this message translates to:
  /// **'• Y 0 to 256: General coal availability (60% base probability)'**
  String get guideCoalLevel2;

  /// Guide card title for lapis generation
  ///
  /// In en, this message translates to:
  /// **'Lapis Lazuli Generation'**
  String get guideLapisTitle;

  /// Lapis generation intro text
  ///
  /// In en, this message translates to:
  /// **'Lapis Lazuli spawns in the Overworld between Y -64 and Y 64.'**
  String get guideLapisIntro;

  /// Lapis optimal Y levels subheading
  ///
  /// In en, this message translates to:
  /// **'🎯 Optimal Y Levels:'**
  String get guideLapisOptimal;

  /// Lapis peak layer description
  ///
  /// In en, this message translates to:
  /// **'• Y 0 to 32: Peak lapis layer (enhanced generation)'**
  String get guideLapisLevel1;

  /// Lapis lower levels description
  ///
  /// In en, this message translates to:
  /// **'• Y -64 to -1: Lower levels (standard generation)'**
  String get guideLapisLevel2;

  /// Lapis higher levels description
  ///
  /// In en, this message translates to:
  /// **'• Y 33 to 64: Higher levels (reduced generation)'**
  String get guideLapisLevel3;

  /// Guide card title for structure generation
  ///
  /// In en, this message translates to:
  /// **'Structure Generation'**
  String get guideStructureTitle;

  /// Structure generation intro text
  ///
  /// In en, this message translates to:
  /// **'Structures are generated based on biome compatibility and rarity.'**
  String get guideStructureIntro;

  /// Common structures subheading
  ///
  /// In en, this message translates to:
  /// **'🏘️ Common Structures (High Spawn Rate):'**
  String get guideStructureCommon;

  /// Village spawn info
  ///
  /// In en, this message translates to:
  /// **'• Villages: Plains, desert, savanna, taiga biomes'**
  String get guideStructureVillages;

  /// Pillager outpost spawn info
  ///
  /// In en, this message translates to:
  /// **'• Pillager Outposts: Same biomes as villages'**
  String get guideStructureOutposts;

  /// Ruined portal spawn info
  ///
  /// In en, this message translates to:
  /// **'• Ruined Portals: Can spawn in any dimension'**
  String get guideStructurePortals;

  /// Rare structures subheading
  ///
  /// In en, this message translates to:
  /// **'🏛️ Rare Structures (Low Spawn Rate):'**
  String get guideStructureRare;

  /// Stronghold spawn info
  ///
  /// In en, this message translates to:
  /// **'• Strongholds: Underground, only 128 per world'**
  String get guideStructureStrongholds;

  /// End city spawn info
  ///
  /// In en, this message translates to:
  /// **'• End Cities: End dimension outer islands'**
  String get guideStructureEndCities;

  /// Ocean monument spawn info
  ///
  /// In en, this message translates to:
  /// **'• Ocean Monuments: Deep ocean biomes'**
  String get guideStructureMonuments;

  /// Ancient city spawn info
  ///
  /// In en, this message translates to:
  /// **'• Ancient Cities: Deep dark biome (Y -52)'**
  String get guideStructureAncientCities;

  /// Title for the pro tip section in the guide
  ///
  /// In en, this message translates to:
  /// **'Pro Tip'**
  String get proTipTitle;

  /// Body text for the pro tip section
  ///
  /// In en, this message translates to:
  /// **'This tool provides statistical predictions based on block game generation algorithms. Use the coordinates as starting points for your mining expeditions, and always explore the surrounding areas once you find ore veins!'**
  String get proTipBody;

  /// Bedwars skill tier label for beginners
  ///
  /// In en, this message translates to:
  /// **'Starters'**
  String get bedwarsTierStarters;

  /// Bedwars skill tier label for intermediate players
  ///
  /// In en, this message translates to:
  /// **'Practitioners'**
  String get bedwarsTierPractitioners;

  /// Bedwars skill tier label for advanced players
  ///
  /// In en, this message translates to:
  /// **'Experts'**
  String get bedwarsTierExperts;

  /// Bedwars starters section title
  ///
  /// In en, this message translates to:
  /// **'Game Objective & Rules'**
  String get bedwarsGameObjectiveTitle;

  /// Bedwars game objective line 1
  ///
  /// In en, this message translates to:
  /// **'Protect your bed while trying to destroy enemy beds.'**
  String get bedwarsGameObjective1;

  /// Bedwars game objective line 2
  ///
  /// In en, this message translates to:
  /// **'Once your bed is destroyed, you can no longer respawn.'**
  String get bedwarsGameObjective2;

  /// Bedwars game objective line 3
  ///
  /// In en, this message translates to:
  /// **'The last team with a surviving player wins the game.'**
  String get bedwarsGameObjective3;

  /// Bedwars game objective line 4
  ///
  /// In en, this message translates to:
  /// **'Collect resources from generators to buy gear and blocks.'**
  String get bedwarsGameObjective4;

  /// Bedwars starters section title
  ///
  /// In en, this message translates to:
  /// **'Basic Resource Gathering'**
  String get bedwarsResourceGatheringTitle;

  /// Resource gathering line 1
  ///
  /// In en, this message translates to:
  /// **'Iron and gold spawn automatically at your island generator.'**
  String get bedwarsResourceGathering1;

  /// Resource gathering line 2
  ///
  /// In en, this message translates to:
  /// **'Stay near your generator between fights to collect resources.'**
  String get bedwarsResourceGathering2;

  /// Resource gathering line 3
  ///
  /// In en, this message translates to:
  /// **'Iron is used for basic blocks and tools from the shop.'**
  String get bedwarsResourceGathering3;

  /// Resource gathering line 4
  ///
  /// In en, this message translates to:
  /// **'Gold buys stronger armor, weapons, and utility items.'**
  String get bedwarsResourceGathering4;

  /// Bedwars starters section title
  ///
  /// In en, this message translates to:
  /// **'Purchasing Essential Items'**
  String get bedwarsPurchasingTitle;

  /// Purchasing line 1
  ///
  /// In en, this message translates to:
  /// **'Buy wool or endstone early for bridging and bed defense.'**
  String get bedwarsPurchasing1;

  /// Purchasing line 2
  ///
  /// In en, this message translates to:
  /// **'A stone sword is a cheap early upgrade over the wooden one.'**
  String get bedwarsPurchasing2;

  /// Purchasing line 3
  ///
  /// In en, this message translates to:
  /// **'Iron armor gives a solid defense boost for the first fights.'**
  String get bedwarsPurchasing3;

  /// Purchasing line 4
  ///
  /// In en, this message translates to:
  /// **'Pick up shears to cut through wool defenses quickly.'**
  String get bedwarsPurchasing4;

  /// Bedwars starters section title
  ///
  /// In en, this message translates to:
  /// **'Basic Bed Defense'**
  String get bedwarsBedDefenseTitle;

  /// Bed defense line 1
  ///
  /// In en, this message translates to:
  /// **'Cover your bed with wool as soon as the game starts.'**
  String get bedwarsBedDefense1;

  /// Bed defense line 2
  ///
  /// In en, this message translates to:
  /// **'Add a second layer of endstone around the wool for extra protection.'**
  String get bedwarsBedDefense2;

  /// Bed defense line 3
  ///
  /// In en, this message translates to:
  /// **'Never leave your bed completely unguarded in the early game.'**
  String get bedwarsBedDefense3;

  /// Bed defense line 4
  ///
  /// In en, this message translates to:
  /// **'Place blocks on all sides including the top of the bed.'**
  String get bedwarsBedDefense4;

  /// Bedwars starters section title
  ///
  /// In en, this message translates to:
  /// **'Basic Combat Tips'**
  String get bedwarsCombatTipsTitle;

  /// Combat tips line 1
  ///
  /// In en, this message translates to:
  /// **'Always sprint before hitting an opponent for extra knockback.'**
  String get bedwarsCombatTips1;

  /// Combat tips line 2
  ///
  /// In en, this message translates to:
  /// **'Block-hit by alternating attack and block to reduce damage taken.'**
  String get bedwarsCombatTips2;

  /// Combat tips line 3
  ///
  /// In en, this message translates to:
  /// **'Aim for critical hits by attacking while falling from a jump.'**
  String get bedwarsCombatTips3;

  /// Combat tips line 4
  ///
  /// In en, this message translates to:
  /// **'Avoid fighting on narrow bridges where knockback is deadly.'**
  String get bedwarsCombatTips4;

  /// Bedwars practitioners section title
  ///
  /// In en, this message translates to:
  /// **'Efficient Resource Management & Upgrades'**
  String get bedwarsResourceManagementTitle;

  /// Resource management line 1
  ///
  /// In en, this message translates to:
  /// **'Visit diamond and emerald generators on the center islands regularly.'**
  String get bedwarsResourceManagement1;

  /// Resource management line 2
  ///
  /// In en, this message translates to:
  /// **'Prioritize team upgrades like sharpness, protection, and forge upgrades.'**
  String get bedwarsResourceManagement2;

  /// Resource management line 3
  ///
  /// In en, this message translates to:
  /// **'Split resource collection duties with teammates for faster progression.'**
  String get bedwarsResourceManagement3;

  /// Resource management line 4
  ///
  /// In en, this message translates to:
  /// **'Save emeralds for powerful items like diamond armor or ender pearls.'**
  String get bedwarsResourceManagement4;

  /// Bedwars practitioners section title
  ///
  /// In en, this message translates to:
  /// **'Intermediate Bed Defense'**
  String get bedwarsIntermediateDefenseTitle;

  /// Intermediate defense line 1
  ///
  /// In en, this message translates to:
  /// **'Layer your bed defense: wool inside, endstone middle, wood or glass outside.'**
  String get bedwarsIntermediateDefense1;

  /// Intermediate defense line 2
  ///
  /// In en, this message translates to:
  /// **'Use blast-proof glass to counter TNT attacks on your bed.'**
  String get bedwarsIntermediateDefense2;

  /// Intermediate defense line 3
  ///
  /// In en, this message translates to:
  /// **'Add water buckets near your bed to slow down attackers.'**
  String get bedwarsIntermediateDefense3;

  /// Intermediate defense line 4
  ///
  /// In en, this message translates to:
  /// **'Consider placing obsidian as the innermost layer for maximum durability.'**
  String get bedwarsIntermediateDefense4;

  /// Bedwars practitioners section title
  ///
  /// In en, this message translates to:
  /// **'Team Coordination Strategies'**
  String get bedwarsTeamCoordinationTitle;

  /// Team coordination line 1
  ///
  /// In en, this message translates to:
  /// **'Assign roles: one player defends while others rush or gather resources.'**
  String get bedwarsTeamCoordination1;

  /// Team coordination line 2
  ///
  /// In en, this message translates to:
  /// **'Communicate enemy positions and incoming attacks to your team.'**
  String get bedwarsTeamCoordination2;

  /// Team coordination line 3
  ///
  /// In en, this message translates to:
  /// **'Coordinate simultaneous attacks on enemy bases for maximum pressure.'**
  String get bedwarsTeamCoordination3;

  /// Team coordination line 4
  ///
  /// In en, this message translates to:
  /// **'Share resources with teammates who need specific upgrades.'**
  String get bedwarsTeamCoordination4;

  /// Bedwars practitioners section title
  ///
  /// In en, this message translates to:
  /// **'Bridge-Building Techniques'**
  String get bedwarsBridgeBuildingTitle;

  /// Bridge building line 1
  ///
  /// In en, this message translates to:
  /// **'Practice speed-bridging by shifting at the edge and placing blocks quickly.'**
  String get bedwarsBridgeBuilding1;

  /// Bridge building line 2
  ///
  /// In en, this message translates to:
  /// **'Build bridges with slight zigzag patterns to avoid easy bow shots.'**
  String get bedwarsBridgeBuilding2;

  /// Bridge building line 3
  ///
  /// In en, this message translates to:
  /// **'Use blocks that are hard to break like endstone for permanent bridges.'**
  String get bedwarsBridgeBuilding3;

  /// Bridge building line 4
  ///
  /// In en, this message translates to:
  /// **'Always carry enough blocks before starting a bridge to an enemy island.'**
  String get bedwarsBridgeBuilding4;

  /// Bedwars practitioners section title
  ///
  /// In en, this message translates to:
  /// **'Mid-Game Combat Tactics'**
  String get bedwarsMidGameCombatTitle;

  /// Mid-game combat line 1
  ///
  /// In en, this message translates to:
  /// **'Use knockback sticks to push enemies off bridges and islands.'**
  String get bedwarsMidGameCombat1;

  /// Mid-game combat line 2
  ///
  /// In en, this message translates to:
  /// **'Carry a bow for ranged pressure while approaching enemy bases.'**
  String get bedwarsMidGameCombat2;

  /// Mid-game combat line 3
  ///
  /// In en, this message translates to:
  /// **'Use fireballs to blast through defenses and knock players into the void.'**
  String get bedwarsMidGameCombat3;

  /// Mid-game combat line 4
  ///
  /// In en, this message translates to:
  /// **'Always eat a golden apple before engaging in a tough fight.'**
  String get bedwarsMidGameCombat4;

  /// Bedwars experts section title
  ///
  /// In en, this message translates to:
  /// **'Advanced PvP Combat'**
  String get bedwarsAdvancedPvpTitle;

  /// Advanced PvP line 1
  ///
  /// In en, this message translates to:
  /// **'Master W-tap combos by releasing and re-pressing forward between hits.'**
  String get bedwarsAdvancedPvp1;

  /// Advanced PvP line 2
  ///
  /// In en, this message translates to:
  /// **'Use fishing rods to pull enemies closer and reset their sprint.'**
  String get bedwarsAdvancedPvp2;

  /// Advanced PvP line 3
  ///
  /// In en, this message translates to:
  /// **'Strafe in unpredictable patterns to make yourself harder to hit.'**
  String get bedwarsAdvancedPvp3;

  /// Advanced PvP line 4
  ///
  /// In en, this message translates to:
  /// **'Combine rod pulls with immediate sword swings for devastating combos.'**
  String get bedwarsAdvancedPvp4;

  /// Bedwars experts section title
  ///
  /// In en, this message translates to:
  /// **'Speed-Bridging & Advanced Movement'**
  String get bedwarsSpeedBridgingTitle;

  /// Speed bridging line 1
  ///
  /// In en, this message translates to:
  /// **'Learn ninja-bridging to place blocks while moving forward without shifting.'**
  String get bedwarsSpeedBridging1;

  /// Speed bridging line 2
  ///
  /// In en, this message translates to:
  /// **'Practice breezily bridging for the fastest straight-line bridge speed.'**
  String get bedwarsSpeedBridging2;

  /// Speed bridging line 3
  ///
  /// In en, this message translates to:
  /// **'Use block clutches to save yourself from falling into the void.'**
  String get bedwarsSpeedBridging3;

  /// Speed bridging line 4
  ///
  /// In en, this message translates to:
  /// **'Master jump-bridging to cover gaps quickly during rushes.'**
  String get bedwarsSpeedBridging4;

  /// Bedwars experts section title
  ///
  /// In en, this message translates to:
  /// **'Rush Strategies & Timing'**
  String get bedwarsRushStrategiesTitle;

  /// Rush strategies line 1
  ///
  /// In en, this message translates to:
  /// **'Rush the nearest enemy base within the first 30 seconds for an early advantage.'**
  String get bedwarsRushStrategies1;

  /// Rush strategies line 2
  ///
  /// In en, this message translates to:
  /// **'Buy TNT and a pickaxe for a fast bed break on defended bases.'**
  String get bedwarsRushStrategies2;

  /// Rush strategies line 3
  ///
  /// In en, this message translates to:
  /// **'Time your rushes when enemies leave their base to gather resources.'**
  String get bedwarsRushStrategies3;

  /// Rush strategies line 4
  ///
  /// In en, this message translates to:
  /// **'Use invisibility potions for surprise attacks on well-defended beds.'**
  String get bedwarsRushStrategies4;

  /// Bedwars experts section title
  ///
  /// In en, this message translates to:
  /// **'Endgame Tactics & Resource Prioritization'**
  String get bedwarsEndgameTitle;

  /// Endgame line 1
  ///
  /// In en, this message translates to:
  /// **'Stockpile ender pearls for quick escapes and surprise engagements.'**
  String get bedwarsEndgame1;

  /// Endgame line 2
  ///
  /// In en, this message translates to:
  /// **'Prioritize diamond armor and sharpness upgrades for final fights.'**
  String get bedwarsEndgame2;

  /// Endgame line 3
  ///
  /// In en, this message translates to:
  /// **'Control the center map generators to deny resources to remaining teams.'**
  String get bedwarsEndgame3;

  /// Endgame line 4
  ///
  /// In en, this message translates to:
  /// **'Keep emergency blocks and golden apples ready for clutch moments.'**
  String get bedwarsEndgame4;

  /// Bedwars experts section title
  ///
  /// In en, this message translates to:
  /// **'Counter-Strategies Against Common Plays'**
  String get bedwarsCounterStrategiesTitle;

  /// Counter strategies line 1
  ///
  /// In en, this message translates to:
  /// **'Counter bridge rushers by placing void traps or using bows at range.'**
  String get bedwarsCounterStrategies1;

  /// Counter strategies line 2
  ///
  /// In en, this message translates to:
  /// **'Against TNT attacks, use blast-proof glass and obsidian layers.'**
  String get bedwarsCounterStrategies2;

  /// Counter strategies line 3
  ///
  /// In en, this message translates to:
  /// **'Counter invisible players by watching for armor particles and footstep sounds.'**
  String get bedwarsCounterStrategies3;

  /// Counter strategies line 4
  ///
  /// In en, this message translates to:
  /// **'Against fireball spam, carry a water bucket to extinguish fires and block knockback.'**
  String get bedwarsCounterStrategies4;

  /// Title of the about dialog
  ///
  /// In en, this message translates to:
  /// **'About Gem, Ore & Struct Finder'**
  String get aboutTitle;

  /// Section title in about dialog
  ///
  /// In en, this message translates to:
  /// **'🎯 What This App Does'**
  String get aboutWhatTitle;

  /// Description card title in about dialog
  ///
  /// In en, this message translates to:
  /// **'Advanced Minecraft Ore & Structure Discovery'**
  String get aboutDescTitle;

  /// Description card body in about dialog
  ///
  /// In en, this message translates to:
  /// **'Enter your world seed and search coordinates to discover exact locations of diamonds, gold, netherite, villages, strongholds, and more.'**
  String get aboutDescBody;

  /// Section title for supported resources
  ///
  /// In en, this message translates to:
  /// **'⛏️ Supported Resources'**
  String get aboutResourcesTitle;

  /// Section title for supported structures
  ///
  /// In en, this message translates to:
  /// **'🏘️ Supported Structures'**
  String get aboutStructuresTitle;

  /// Section title for how it works
  ///
  /// In en, this message translates to:
  /// **'🔍 How It Works'**
  String get aboutHowItWorksTitle;

  /// Section title for key features
  ///
  /// In en, this message translates to:
  /// **'✨ Key Features'**
  String get aboutFeaturesTitle;

  /// Section title for support section
  ///
  /// In en, this message translates to:
  /// **'☕ Support Development'**
  String get aboutSupportTitle;

  /// Diamond resource name in about dialog
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get aboutResourceDiamond;

  /// Gold resource name in about dialog
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get aboutResourceGold;

  /// Netherite resource name in about dialog
  ///
  /// In en, this message translates to:
  /// **'Netherite'**
  String get aboutResourceNetherite;

  /// Iron resource name in about dialog
  ///
  /// In en, this message translates to:
  /// **'Iron'**
  String get aboutResourceIron;

  /// Redstone resource name in about dialog
  ///
  /// In en, this message translates to:
  /// **'Redstone'**
  String get aboutResourceRedstone;

  /// Coal resource name in about dialog
  ///
  /// In en, this message translates to:
  /// **'Coal'**
  String get aboutResourceCoal;

  /// Lapis resource name in about dialog
  ///
  /// In en, this message translates to:
  /// **'Lapis'**
  String get aboutResourceLapis;

  /// Village structure chip in about dialog
  ///
  /// In en, this message translates to:
  /// **'Villages 🏘️'**
  String get aboutStructureVillages;

  /// Stronghold structure chip in about dialog
  ///
  /// In en, this message translates to:
  /// **'Strongholds 🏰'**
  String get aboutStructureStrongholds;

  /// Dungeon structure chip in about dialog
  ///
  /// In en, this message translates to:
  /// **'Dungeons 🕳️'**
  String get aboutStructureDungeons;

  /// Mineshaft structure chip in about dialog
  ///
  /// In en, this message translates to:
  /// **'Mineshafts ⛏️'**
  String get aboutStructureMineshafts;

  /// Desert temple structure chip in about dialog
  ///
  /// In en, this message translates to:
  /// **'Desert Temples 🏜️'**
  String get aboutStructureDesertTemples;

  /// Jungle temple structure chip in about dialog
  ///
  /// In en, this message translates to:
  /// **'Jungle Temples 🌿'**
  String get aboutStructureJungleTemples;

  /// Ocean monument structure chip in about dialog
  ///
  /// In en, this message translates to:
  /// **'Ocean Monuments 🌊'**
  String get aboutStructureOceanMonuments;

  /// Woodland mansion structure chip in about dialog
  ///
  /// In en, this message translates to:
  /// **'Woodland Mansions 🏚️'**
  String get aboutStructureWoodlandMansions;

  /// Pillager outpost structure chip in about dialog
  ///
  /// In en, this message translates to:
  /// **'Pillager Outposts ⚔️'**
  String get aboutStructurePillagerOutposts;

  /// Ruined portal structure chip in about dialog
  ///
  /// In en, this message translates to:
  /// **'Ruined Portals 🌀'**
  String get aboutStructureRuinedPortals;

  /// How it works step 1
  ///
  /// In en, this message translates to:
  /// **'Enter your world seed in the Search tab'**
  String get aboutStep1;

  /// How it works step 2
  ///
  /// In en, this message translates to:
  /// **'Set your search center coordinates (X, Y, Z)'**
  String get aboutStep2;

  /// How it works step 3
  ///
  /// In en, this message translates to:
  /// **'Choose your search radius'**
  String get aboutStep3;

  /// How it works step 4
  ///
  /// In en, this message translates to:
  /// **'Select which ores and structures to find'**
  String get aboutStep4;

  /// How it works step 5
  ///
  /// In en, this message translates to:
  /// **'Tap \"Find\" to discover nearby resources'**
  String get aboutStep5;

  /// How it works step 6
  ///
  /// In en, this message translates to:
  /// **'View results with exact coordinates'**
  String get aboutStep6;

  /// Key feature 1
  ///
  /// In en, this message translates to:
  /// **'Recent Seeds History — Quick access to last 5 seeds'**
  String get aboutFeature1;

  /// Key feature 2
  ///
  /// In en, this message translates to:
  /// **'Auto Parameter Saving — Never lose search settings'**
  String get aboutFeature2;

  /// Key feature 3
  ///
  /// In en, this message translates to:
  /// **'Probability Results — Find the most likely locations'**
  String get aboutFeature3;

  /// Key feature 4
  ///
  /// In en, this message translates to:
  /// **'Cross-Platform — Web, mobile, and desktop'**
  String get aboutFeature4;

  /// Key feature 5
  ///
  /// In en, this message translates to:
  /// **'Dark/Light Theme — Choose your vibe'**
  String get aboutFeature5;

  /// Buy me a coffee title in support section
  ///
  /// In en, this message translates to:
  /// **'Buy Me a Coffee'**
  String get aboutBuyMeCoffee;

  /// Support section body text
  ///
  /// In en, this message translates to:
  /// **'Help keep this app free and improving! Your support enables new features and ongoing development.'**
  String get aboutSupportBody;

  /// Support development button label
  ///
  /// In en, this message translates to:
  /// **'Support Development'**
  String get aboutSupportButton;

  /// Footer tip text in about dialog
  ///
  /// In en, this message translates to:
  /// **'Use Recent Seeds to quickly switch between worlds!'**
  String get aboutFooterTip;

  /// Got it button label in about dialog footer
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get aboutGotIt;

  /// Release notes page header
  ///
  /// In en, this message translates to:
  /// **'Release Notes — v1.0.51'**
  String get releaseNotesHeader;

  /// Release notes bedwars section header
  ///
  /// In en, this message translates to:
  /// **'🎮 Bedwars Strategy Guide — NEW!'**
  String get releaseNotesBedwarsSection;

  /// Bedwars guide feature title
  ///
  /// In en, this message translates to:
  /// **'Complete Bedwars Guide'**
  String get releaseNotesBedwarsGuideTitle;

  /// Bedwars guide feature body
  ///
  /// In en, this message translates to:
  /// **'A dedicated tab with in-depth strategies for Bedwars. Covers early game rushing, mid game defense, and late game tactics to help you dominate every match.'**
  String get releaseNotesBedwarsGuideBody;

  /// Resource strategies feature title
  ///
  /// In en, this message translates to:
  /// **'Resource & Shop Strategies'**
  String get releaseNotesResourceStrategiesTitle;

  /// Resource strategies feature body
  ///
  /// In en, this message translates to:
  /// **'Detailed breakdowns of resource priorities, optimal shop purchases at every stage, and team coordination tips for 2s, 3s, and 4s modes.'**
  String get releaseNotesResourceStrategiesBody;

  /// Defense attack feature title
  ///
  /// In en, this message translates to:
  /// **'Defense & Attack Patterns'**
  String get releaseNotesDefenseAttackTitle;

  /// Defense attack feature body
  ///
  /// In en, this message translates to:
  /// **'Learn bed defense layouts, bridge rushing techniques, fireball strategies, and how to counter common enemy tactics.'**
  String get releaseNotesDefenseAttackBody;

  /// Release notes UI section header
  ///
  /// In en, this message translates to:
  /// **'🎨 Modern Gamer UI Overhaul'**
  String get releaseNotesUiSection;

  /// Neon aesthetic feature title
  ///
  /// In en, this message translates to:
  /// **'Neon Gamer Aesthetic'**
  String get releaseNotesNeonTitle;

  /// Neon aesthetic feature body
  ///
  /// In en, this message translates to:
  /// **'Complete visual redesign with a neon-on-dark color palette. Vibrant green, cyan, and purple accents with subtle glow effects for a modern gaming feel.'**
  String get releaseNotesNeonBody;

  /// Light mode feature title
  ///
  /// In en, this message translates to:
  /// **'Improved Light Mode'**
  String get releaseNotesLightModeTitle;

  /// Light mode feature body
  ///
  /// In en, this message translates to:
  /// **'Fully readable light theme with darker accent variants. Every text element now meets contrast requirements on both light and dark backgrounds.'**
  String get releaseNotesLightModeBody;

  /// Cards redesign feature title
  ///
  /// In en, this message translates to:
  /// **'Redesigned Cards & Buttons'**
  String get releaseNotesCardsTitle;

  /// Cards redesign feature body
  ///
  /// In en, this message translates to:
  /// **'Flat cards with neon border accents, gradient action buttons with glow shadows, and a cleaner tab bar with neon indicators replace the old Material green theme.'**
  String get releaseNotesCardsBody;

  /// Release notes algorithm section header
  ///
  /// In en, this message translates to:
  /// **'⛏️ Ore Finding Algorithm Improvements'**
  String get releaseNotesAlgorithmSection;

  /// Noise generation feature title
  ///
  /// In en, this message translates to:
  /// **'Enhanced Noise Generation'**
  String get releaseNotesNoiseTitle;

  /// Noise generation feature body
  ///
  /// In en, this message translates to:
  /// **'Improved Perlin noise implementation for more accurate ore probability calculations that better match actual in-game world generation patterns.'**
  String get releaseNotesNoiseBody;

  /// Biome awareness feature title
  ///
  /// In en, this message translates to:
  /// **'Better Biome Awareness'**
  String get releaseNotesBiomeTitle;

  /// Biome awareness feature body
  ///
  /// In en, this message translates to:
  /// **'Refined biome detection and ore distribution modeling. Gold in badlands, diamonds at deep levels, and netherite in the nether are all more precisely predicted.'**
  String get releaseNotesBiomeBody;

  /// Search performance feature title
  ///
  /// In en, this message translates to:
  /// **'Optimized Search Performance'**
  String get releaseNotesPerformanceTitle;

  /// Search performance feature body
  ///
  /// In en, this message translates to:
  /// **'Faster search execution with improved chunk scanning. Comprehensive netherite search and large-radius queries complete more efficiently.'**
  String get releaseNotesPerformanceBody;

  /// Release notes highlights section header
  ///
  /// In en, this message translates to:
  /// **'🎯 Highlights'**
  String get releaseNotesHighlightsSection;

  /// Highlight bullet 1
  ///
  /// In en, this message translates to:
  /// **'Bedwars Guide: Full strategy guide with early/mid/late game tactics'**
  String get releaseNotesHighlight1;

  /// Highlight bullet 2
  ///
  /// In en, this message translates to:
  /// **'Gamer UI: Neon accents, glow effects, and modern dark theme'**
  String get releaseNotesHighlight2;

  /// Highlight bullet 3
  ///
  /// In en, this message translates to:
  /// **'Light Mode Fix: All text now readable on light backgrounds'**
  String get releaseNotesHighlight3;

  /// Highlight bullet 4
  ///
  /// In en, this message translates to:
  /// **'Better Ore Finding: More accurate predictions across all ore types'**
  String get releaseNotesHighlight4;

  /// Highlight bullet 5
  ///
  /// In en, this message translates to:
  /// **'Faster Searches: Optimized algorithms for quicker results'**
  String get releaseNotesHighlight5;

  /// Highlight bullet 6
  ///
  /// In en, this message translates to:
  /// **'5-Tab Layout: Search, Results, Guide, Bedwars, and Updates'**
  String get releaseNotesHighlight6;

  /// Highlight bullet 7
  ///
  /// In en, this message translates to:
  /// **'Edition & Version: Java/Bedrock edition and Legacy/Modern version support'**
  String get releaseNotesHighlight7;

  /// Release notes technical section header
  ///
  /// In en, this message translates to:
  /// **'🔧 Technical Improvements'**
  String get releaseNotesTechnicalSection;

  /// Technical improvement 1
  ///
  /// In en, this message translates to:
  /// **'Centralized theme system with adaptive light/dark color helpers'**
  String get releaseNotesTechnical1;

  /// Technical improvement 2
  ///
  /// In en, this message translates to:
  /// **'Reusable GamerCard and GamerSectionHeader components'**
  String get releaseNotesTechnical2;

  /// Technical improvement 3
  ///
  /// In en, this message translates to:
  /// **'Improved Perlin noise for ore generation modeling'**
  String get releaseNotesTechnical3;

  /// Technical improvement 4
  ///
  /// In en, this message translates to:
  /// **'Better chunk-level probability calculations'**
  String get releaseNotesTechnical4;

  /// Technical improvement 5
  ///
  /// In en, this message translates to:
  /// **'Reduced widget rebuilds for smoother scrolling'**
  String get releaseNotesTechnical5;

  /// Technical improvement 6
  ///
  /// In en, this message translates to:
  /// **'GameRandom strategy pattern for edition-aware RNG across all ore calculations'**
  String get releaseNotesTechnical6;

  /// Release notes previous updates section header
  ///
  /// In en, this message translates to:
  /// **'📋 Previous Updates'**
  String get releaseNotesPreviousSection;

  /// Version 1.0.42 title
  ///
  /// In en, this message translates to:
  /// **'v1.0.42 — Lapis Lazuli + UI'**
  String get releaseNotesV1042Title;

  /// Version 1.0.42 body
  ///
  /// In en, this message translates to:
  /// **'Added Lapis Lazuli ore finding. All 7 major ores supported. Enhanced 4-tab navigation layout.'**
  String get releaseNotesV1042Body;

  /// Version 1.0.41 title
  ///
  /// In en, this message translates to:
  /// **'v1.0.41 — Recent Seeds History'**
  String get releaseNotesV1041Title;

  /// Version 1.0.41 body
  ///
  /// In en, this message translates to:
  /// **'Automatic seed history with quick access to last 5 seeds.'**
  String get releaseNotesV1041Body;

  /// Version 1.0.36 title
  ///
  /// In en, this message translates to:
  /// **'v1.0.36 — Complete Search Memory'**
  String get releaseNotesV1036Title;

  /// Version 1.0.36 body
  ///
  /// In en, this message translates to:
  /// **'Comprehensive search parameter persistence.'**
  String get releaseNotesV1036Body;

  /// Version 1.0.27 title
  ///
  /// In en, this message translates to:
  /// **'v1.0.27 — Visual Improvements'**
  String get releaseNotesV1027Title;

  /// Version 1.0.27 body
  ///
  /// In en, this message translates to:
  /// **'Updated splash screen and icons.'**
  String get releaseNotesV1027Body;

  /// Version 1.0.22 title
  ///
  /// In en, this message translates to:
  /// **'v1.0.22 — Extended Ore Discovery'**
  String get releaseNotesV1022Title;

  /// Version 1.0.22 body
  ///
  /// In en, this message translates to:
  /// **'Added Iron, Redstone, Coal, and Lapis Lazuli.'**
  String get releaseNotesV1022Body;

  /// Version 1.0.15 title
  ///
  /// In en, this message translates to:
  /// **'v1.0.15 — Structure Discovery'**
  String get releaseNotesV1015Title;

  /// Version 1.0.15 body
  ///
  /// In en, this message translates to:
  /// **'Villages, strongholds, dungeons, temples, and more.'**
  String get releaseNotesV1015Body;

  /// Version 1.0.10 title
  ///
  /// In en, this message translates to:
  /// **'v1.0.10 — Foundation Release'**
  String get releaseNotesV1010Title;

  /// Version 1.0.10 body
  ///
  /// In en, this message translates to:
  /// **'Core diamond, gold, and netherite finding.'**
  String get releaseNotesV1010Body;

  /// Release notes timeline section header
  ///
  /// In en, this message translates to:
  /// **'🏆 Version Timeline'**
  String get releaseNotesTimelineSection;

  /// Timeline badge for current version
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get releaseNotesTimelineCurrent;

  /// Timeline badge for previous version
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get releaseNotesTimelinePrevious;

  /// Timeline badge for earlier versions
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get releaseNotesTimelineEarlier;

  /// Timeline highlight for v1.0.50
  ///
  /// In en, this message translates to:
  /// **'Bedwars + UI'**
  String get releaseNotesTimelineBedwarsUi;

  /// Timeline highlight for v1.0.42
  ///
  /// In en, this message translates to:
  /// **'Lapis + UI'**
  String get releaseNotesTimelineLapisUi;

  /// Timeline highlight for v1.0.41
  ///
  /// In en, this message translates to:
  /// **'Recent Seeds'**
  String get releaseNotesTimelineRecentSeeds;

  /// Timeline highlight for v1.0.36
  ///
  /// In en, this message translates to:
  /// **'Search Memory'**
  String get releaseNotesTimelineSearchMemory;

  /// Timeline highlight for v1.0.27
  ///
  /// In en, this message translates to:
  /// **'Visual Updates'**
  String get releaseNotesTimelineVisualUpdates;

  /// Timeline highlight for v1.0.22
  ///
  /// In en, this message translates to:
  /// **'Extended Ores'**
  String get releaseNotesTimelineExtendedOres;

  /// Timeline highlight for v1.0.15
  ///
  /// In en, this message translates to:
  /// **'Structures'**
  String get releaseNotesTimelineStructures;

  /// Timeline highlight for v1.0.10
  ///
  /// In en, this message translates to:
  /// **'Core Features'**
  String get releaseNotesTimelineCoreFeatures;

  /// Footer info text on release notes page
  ///
  /// In en, this message translates to:
  /// **'New: Edition & version selection, Bedwars guide, gamer UI, and improved ore finding!'**
  String get releaseNotesFooter;

  /// Header title for the v1.0.41 release notes dialog
  ///
  /// In en, this message translates to:
  /// **'Release Notes - Version 1.0.41'**
  String get dialogReleaseNotesHeader;

  /// Section header for recent seeds in dialog
  ///
  /// In en, this message translates to:
  /// **'🌱 Recent Seeds History - NEW!'**
  String get dialogRecentSeedsSection;

  /// Feature title in dialog
  ///
  /// In en, this message translates to:
  /// **'Quick Seed Access'**
  String get dialogQuickSeedAccessTitle;

  /// Feature body in dialog
  ///
  /// In en, this message translates to:
  /// **'Never lose track of your favorite world seeds! The app now automatically saves your last 5 searched seeds and displays them as clickable options below the seed input field. Simply tap any recent seed to instantly use it again.'**
  String get dialogQuickSeedAccessBody;

  /// Feature title in dialog
  ///
  /// In en, this message translates to:
  /// **'Smart Seed Management'**
  String get dialogSmartSeedTitle;

  /// Feature body in dialog
  ///
  /// In en, this message translates to:
  /// **'Recent seeds are automatically managed - when you search a seed again, it moves to the top of the list. The oldest seed is automatically removed when you reach the 5-seed limit. All seed digits are fully visible with improved monospace formatting for better readability.'**
  String get dialogSmartSeedBody;

  /// Feature title in dialog
  ///
  /// In en, this message translates to:
  /// **'Enhanced User Experience'**
  String get dialogEnhancedUxTitle;

  /// Feature body in dialog
  ///
  /// In en, this message translates to:
  /// **'Perfect for players who test multiple seeds or return to favorite worlds. No more manually typing long seed numbers - just click and search! Seeds persist across app sessions, so your history is always available.'**
  String get dialogEnhancedUxBody;

  /// Section header for search memory in dialog
  ///
  /// In en, this message translates to:
  /// **'💾 Complete Search Memory Feature'**
  String get dialogSearchMemorySection;

  /// Feature title in dialog
  ///
  /// In en, this message translates to:
  /// **'Automatic Parameter Saving'**
  String get dialogAutoSaveTitle;

  /// Feature body in dialog
  ///
  /// In en, this message translates to:
  /// **'The app remembers ALL your search parameters including world seed, X/Y/Z coordinates, and search radius. Everything is automatically saved when you type and restored when you restart the app.'**
  String get dialogAutoSaveBody;

  /// Feature title in dialog
  ///
  /// In en, this message translates to:
  /// **'Seamless Workflow'**
  String get dialogSeamlessTitle;

  /// Feature body in dialog
  ///
  /// In en, this message translates to:
  /// **'Continue your ore hunting sessions exactly where you left off. No more re-entering coordinates or adjusting search settings. Focus on finding ores instead of configuring search settings!'**
  String get dialogSeamlessBody;

  /// Section header in dialog
  ///
  /// In en, this message translates to:
  /// **'🎯 Enhanced User Experience'**
  String get dialogEnhancedUxSection;

  /// UX bullet point 1
  ///
  /// In en, this message translates to:
  /// **'Recent Seeds: Quick access to your last 5 searched world seeds'**
  String get dialogUxBullet1;

  /// UX bullet point 2
  ///
  /// In en, this message translates to:
  /// **'Time Saving: Eliminates the need to remember and re-enter search parameters'**
  String get dialogUxBullet2;

  /// UX bullet point 3
  ///
  /// In en, this message translates to:
  /// **'Better Productivity: Focus purely on ore discovery'**
  String get dialogUxBullet3;

  /// UX bullet point 4
  ///
  /// In en, this message translates to:
  /// **'Cross-Platform: Works consistently across all supported platforms'**
  String get dialogUxBullet4;

  /// UX bullet point 5
  ///
  /// In en, this message translates to:
  /// **'Smart Defaults: Falls back to sensible defaults for new users'**
  String get dialogUxBullet5;

  /// UX bullet point 6
  ///
  /// In en, this message translates to:
  /// **'Improved Readability: Monospace font for better seed number visibility'**
  String get dialogUxBullet6;

  /// Section header in dialog
  ///
  /// In en, this message translates to:
  /// **'🔧 Technical Improvements'**
  String get dialogTechSection;

  /// Tech bullet point 1
  ///
  /// In en, this message translates to:
  /// **'Recent Seeds Storage: Persistent seed history with automatic management'**
  String get dialogTechBullet1;

  /// Tech bullet point 2
  ///
  /// In en, this message translates to:
  /// **'Offline Font Support: Improved performance without internet connection'**
  String get dialogTechBullet2;

  /// Tech bullet point 3
  ///
  /// In en, this message translates to:
  /// **'Comprehensive Persistence: All text input fields are automatically saved'**
  String get dialogTechBullet3;

  /// Tech bullet point 4
  ///
  /// In en, this message translates to:
  /// **'Efficient Storage: Uses platform-native storage for optimal performance'**
  String get dialogTechBullet4;

  /// Tech bullet point 5
  ///
  /// In en, this message translates to:
  /// **'Enhanced Stability: Better error handling and user experience'**
  String get dialogTechBullet5;

  /// Tech bullet point 6
  ///
  /// In en, this message translates to:
  /// **'Full Seed Visibility: Complete seed numbers displayed without truncation'**
  String get dialogTechBullet6;

  /// Section header in dialog
  ///
  /// In en, this message translates to:
  /// **'📋 Previous Updates'**
  String get dialogPreviousSection;

  /// Version title in dialog
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.36 - Search Memory'**
  String get dialogV1036Title;

  /// Version body in dialog
  ///
  /// In en, this message translates to:
  /// **'Complete search parameter persistence including world seed, coordinates, and radius.'**
  String get dialogV1036Body;

  /// Version title in dialog
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.27 - Minor Update'**
  String get dialogV1027Title;

  /// Version body in dialog
  ///
  /// In en, this message translates to:
  /// **'Updated splash screen and icons for better visual consistency.'**
  String get dialogV1027Body;

  /// Version title in dialog
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.22 - Extended Ore Discovery'**
  String get dialogV1022Title;

  /// Version body in dialog
  ///
  /// In en, this message translates to:
  /// **'⚪ Iron Ore (Y -64 to 256, peaks at Y 15 & Y 232)\n🔴 Redstone Ore (Y -64 to 15, 90% at Y -64 to -59)\n⚫ Coal Ore (Y 0 to 256, peaks at Y 96)\n🔵 Lapis Lazuli (Y -64 to 64, enhanced at Y 0-32)\nEnhanced UI with compact ore selection and visual legend'**
  String get dialogV1022Body;

  /// Section header in dialog
  ///
  /// In en, this message translates to:
  /// **'🎯 Perfect for All Players'**
  String get dialogPlayersSection;

  /// Player bullet point 1
  ///
  /// In en, this message translates to:
  /// **'Seed Explorers: Quickly switch between favorite world seeds'**
  String get dialogPlayerBullet1;

  /// Player bullet point 2
  ///
  /// In en, this message translates to:
  /// **'Speedrunners: Quick access to essential ores with saved parameters'**
  String get dialogPlayerBullet2;

  /// Player bullet point 3
  ///
  /// In en, this message translates to:
  /// **'Builders: Iron for tools, redstone for mechanisms'**
  String get dialogPlayerBullet3;

  /// Player bullet point 4
  ///
  /// In en, this message translates to:
  /// **'Regular Players: Seamless continuation of mining sessions'**
  String get dialogPlayerBullet4;

  /// Player bullet point 5
  ///
  /// In en, this message translates to:
  /// **'New Players: Learn optimal mining levels with persistent settings'**
  String get dialogPlayerBullet5;

  /// Player bullet point 6
  ///
  /// In en, this message translates to:
  /// **'Content Creators: Easy seed management for showcasing different worlds'**
  String get dialogPlayerBullet6;

  /// Footer text in dialog
  ///
  /// In en, this message translates to:
  /// **'NEW: Recent seeds history + all search parameters automatically saved!'**
  String get dialogFooter;

  /// Got it button in dialog
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get dialogGotIt;

  /// Release notes edition section header
  ///
  /// In en, this message translates to:
  /// **'🎮 Edition & Version Selection — NEW!'**
  String get releaseNotesEditionSection;

  /// Edition selector feature title
  ///
  /// In en, this message translates to:
  /// **'Java & Bedrock Edition Support'**
  String get releaseNotesEditionSelectorTitle;

  /// Edition selector feature body
  ///
  /// In en, this message translates to:
  /// **'Choose between Java Edition and Bedrock Edition. The app uses the correct random number generator for each edition, so ore predictions match your actual world.'**
  String get releaseNotesEditionSelectorBody;

  /// Version era feature title
  ///
  /// In en, this message translates to:
  /// **'Legacy & Modern Version Eras'**
  String get releaseNotesVersionEraTitle;

  /// Version era feature body
  ///
  /// In en, this message translates to:
  /// **'Switch between Pre-1.18 (Legacy) with classic uniform ore distribution and fixed Y ranges, or 1.18+ (Modern) with triangular distributions and expanded -64 to 320 world depth.'**
  String get releaseNotesVersionEraBody;

  /// Bedrock RNG feature title
  ///
  /// In en, this message translates to:
  /// **'Bedrock RNG Engine'**
  String get releaseNotesBedrockRngTitle;

  /// Bedrock RNG feature body
  ///
  /// In en, this message translates to:
  /// **'A dedicated Mersenne Twister RNG replicates Bedrock Edition\'s C++ engine. Contextual info boxes let you know when predictions are approximate.'**
  String get releaseNotesBedrockRngBody;

  /// Version 1.0.50 title
  ///
  /// In en, this message translates to:
  /// **'v1.0.50 — Bedwars + UI'**
  String get releaseNotesV1050Title;

  /// Version 1.0.50 body
  ///
  /// In en, this message translates to:
  /// **'Complete Bedwars strategy guide. Modern gamer UI overhaul with neon aesthetic and improved light mode.'**
  String get releaseNotesV1050Body;

  /// Timeline highlight for v1.0.51
  ///
  /// In en, this message translates to:
  /// **'Editions + Eras'**
  String get releaseNotesTimelineEditionVersion;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
