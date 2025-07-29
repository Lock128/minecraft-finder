import 'package:flutter/material.dart';
import '../models/ore_location.dart';
import '../models/structure_location.dart';
import 'world_settings_card.dart';
import 'search_center_card.dart';
import 'ore_selection_card.dart';
import 'structure_selection_card.dart';
import 'search_buttons.dart';

class SearchTab extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController seedController;
  final TextEditingController xController;
  final TextEditingController yController;
  final TextEditingController zController;
  final TextEditingController radiusController;
  final Set<OreType> selectedOreTypes;
  final bool includeNether;
  final bool includeOres;
  final bool includeStructures;
  final Set<StructureType> selectedStructures;
  final bool isLoading;
  final bool findAllNetherite;
  final bool isDarkMode;
  final Function(Set<OreType>) onOreTypesChanged;
  final Function(bool) onIncludeNetherChanged;
  final Function(bool) onIncludeOresChanged;
  final Function(bool) onIncludeStructuresChanged;
  final Function(Set<StructureType>) onStructuresChanged;
  final Function(bool) onFindOres;

  const SearchTab({
    super.key,
    required this.formKey,
    required this.seedController,
    required this.xController,
    required this.yController,
    required this.zController,
    required this.radiusController,
    required this.selectedOreTypes,
    required this.includeNether,
    required this.includeOres,
    required this.includeStructures,
    required this.selectedStructures,
    required this.isLoading,
    required this.findAllNetherite,
    required this.isDarkMode,
    required this.onOreTypesChanged,
    required this.onIncludeNetherChanged,
    required this.onIncludeOresChanged,
    required this.onIncludeStructuresChanged,
    required this.onStructuresChanged,
    required this.onFindOres,
  });

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final GlobalKey<State<WorldSettingsCard>> _worldSettingsKey = GlobalKey();

  void refreshRecentSeeds() {
    (_worldSettingsKey.currentState as dynamic)?.refreshRecentSeeds();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isDarkMode
              ? [
                  const Color(0xFF1A237E), // Dark blue
                  const Color(0xFF2E7D32), // Dark green
                ]
              : [
                  const Color(0xFF87CEEB), // Sky blue
                  const Color(0xFF98FB98), // Pale green
                ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: widget.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WorldSettingsCard(
                key: _worldSettingsKey,
                seedController: widget.seedController,
                isDarkMode: widget.isDarkMode,
              ),
              const SizedBox(height: 16),
              SearchCenterCard(
                xController: widget.xController,
                yController: widget.yController,
                zController: widget.zController,
                radiusController: widget.radiusController,
                isDarkMode: widget.isDarkMode,
              ),
              const SizedBox(height: 16),
              OreSelectionCard(
                selectedOreTypes: widget.selectedOreTypes,
                includeNether: widget.includeNether,
                includeOres: widget.includeOres,
                isDarkMode: widget.isDarkMode,
                includeStructures: widget.includeStructures,
                selectedStructures: widget.selectedStructures,
                onOreTypesChanged: widget.onOreTypesChanged,
                onIncludeNetherChanged: widget.onIncludeNetherChanged,
                onIncludeOresChanged: widget.onIncludeOresChanged,
              ),
              const SizedBox(height: 16),
              StructureSelectionCard(
                includeStructures: widget.includeStructures,
                selectedStructures: widget.selectedStructures,
                isDarkMode: widget.isDarkMode,
                onIncludeStructuresChanged: widget.onIncludeStructuresChanged,
                onStructuresChanged: widget.onStructuresChanged,
              ),
              const SizedBox(height: 24),
              SearchButtons(
                isLoading: widget.isLoading,
                findAllNetherite: widget.findAllNetherite,
                onFindOres: widget.onFindOres,
                isDarkMode: widget.isDarkMode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
