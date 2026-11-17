import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/game_random.dart';
import '../models/ore_location.dart';
import '../models/structure_location.dart';
import '../models/version_availability.dart';
import '../providers/monetization_config.dart';
import '../providers/pro_status_provider.dart';
import '../providers/search_state.dart';
import '../theme/gamer_theme.dart';
import '../utils/structure_utils.dart';

/// The only place where the user picks what to search for.
///
/// Ores and structures are plain filter chips. There is no separate
/// "include ores" / "include structures" switch: a group is searched exactly
/// when at least one of its chips is selected. Only content that exists in the
/// selected edition and version era is offered.
///
/// The card reads and writes [SearchState] itself and rebuilds only when the
/// slice of state it displays changes.
class WhatToFindCard extends StatefulWidget {
  final bool isDarkMode;

  const WhatToFindCard({super.key, required this.isDarkMode});

  @override
  State<WhatToFindCard> createState() => _WhatToFindCardState();
}

class _WhatToFindCardState extends State<WhatToFindCard> {
  late bool _structuresOpen;

  @override
  void initState() {
    super.initState();
    final state = context.read<SearchState>();
    _structuresOpen =
        state.includeStructures && state.selectedStructures.isNotEmpty;
  }

  bool get _isDark => widget.isDarkMode;

  /// The localized filter names start with an emoji. The chip shows a colored
  /// dot instead, so drop the leading emoji and spaces.
  String _oreLabel(AppLocalizations l10n, OreType ore) => _rawOreLabel(
    l10n,
    ore,
  ).replaceFirst(RegExp(r'^[^\p{L}\p{N}]+', unicode: true), '');

  String _rawOreLabel(AppLocalizations l10n, OreType ore) {
    switch (ore) {
      case OreType.diamond:
        return l10n.filterDiamonds;
      case OreType.gold:
        return l10n.filterGold;
      case OreType.iron:
        return l10n.filterIron;
      case OreType.redstone:
        return l10n.filterRedstone;
      case OreType.coal:
        return l10n.filterCoal;
      case OreType.lapis:
        return l10n.filterLapis;
      case OreType.netherite:
        return l10n.filterNetherite;
      case OreType.copper:
        return l10n.filterCopper;
      case OreType.emerald:
        return l10n.filterEmerald;
    }
  }

  Color _oreColor(OreType ore) {
    switch (ore) {
      case OreType.diamond:
        return GamerColors.diamondText(_isDark);
      case OreType.gold:
        return GamerColors.goldText(_isDark);
      case OreType.iron:
        return GamerColors.ironText(_isDark);
      case OreType.redstone:
        return GamerColors.redstoneText(_isDark);
      case OreType.coal:
        return GamerColors.coalText(_isDark);
      case OreType.lapis:
        return GamerColors.lapisText(_isDark);
      case OreType.netherite:
        return GamerColors.netheriteText(_isDark);
      case OreType.copper:
        return GamerColors.orangeText(_isDark);
      case OreType.emerald:
        return GamerColors.greenText(_isDark);
    }
  }

  void _toggleOre(
    SearchState state,
    OreType ore,
    bool selected,
    Set<OreType> current,
  ) {
    final updated = Set<OreType>.from(current);
    selected ? updated.add(ore) : updated.remove(ore);
    state.setOreTypes(updated);
    state.setIncludeOres(updated.isNotEmpty);
  }

  void _toggleStructure(
    SearchState state,
    StructureType type,
    bool selected,
    Set<StructureType> current,
  ) {
    final updated = Set<StructureType>.from(current);
    selected ? updated.add(type) : updated.remove(type);
    state.setSelectedStructures(updated);
    state.setIncludeStructures(updated.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.read<SearchState>();
    final d = context.select<SearchState, _Slice>(
      (s) => (
        ores: s.selectedOreTypes,
        includeOres: s.includeOres,
        includeNether: s.includeNether,
        structures: s.selectedStructures,
        includeStructures: s.includeStructures,
        edition: s.selectedEdition,
        era: s.selectedVersionEra,
      ),
    );

    final availableOres = VersionAvailability.availableOres(
      era: d.era,
      edition: d.edition,
    );
    final hiddenOres = OreType.values.length - availableOres.length;
    final availableStructures = VersionAvailability.availableStructures(
      era: d.era,
      edition: d.edition,
    );
    final hiddenStructures =
        StructureType.values.length - availableStructures.length;

    final selectedOres = d.includeOres ? d.ores : const <OreType>{};
    final selectedStructures = d.includeStructures
        ? d.structures
        : const <StructureType>{};

    final structureInfo = StructureUtils.getAllStructures()
        .where((s) => availableStructures.contains(s['type'] as StructureType))
        .toList();

    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );

    return GamerCard(
      isDarkMode: _isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GamerSectionHeader(
            icon: Icons.diamond_outlined,
            title: l10n.whatToFindTitle,
            isDarkMode: _isDark,
          ),
          const SizedBox(height: 16),
          Text(l10n.groupOres, style: labelStyle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ore in availableOres)
                FilterChip(
                  avatar: _Dot(color: _oreColor(ore)),
                  label: Text(_oreLabel(l10n, ore)),
                  selected: selectedOres.contains(ore),
                  onSelected: (v) => _toggleOre(state, ore, v, selectedOres),
                ),
            ],
          ),
          if (hiddenOres > 0) ...[
            const SizedBox(height: 8),
            _Note(text: l10n.oreUnavailableInVersion(hiddenOres)),
          ],
          // Nether gold is a sub-option of Gold, so it only shows when Gold is
          // selected and exists in this version.
          if (selectedOres.contains(OreType.gold)) ...[
            const SizedBox(height: 4),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.includeNetherGold),
              subtitle: Text(l10n.searchForNetherGold),
              value: d.includeNether,
              onChanged: (v) => state.setIncludeNether(v ?? false),
            ),
          ],
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _structuresOpen = !_structuresOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(l10n.groupStructures, style: labelStyle),
                  if (selectedStructures.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${selectedStructures.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _structuresOpen ? Icons.expand_less : Icons.expand_more,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _structuresOpen
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                state.setSelectedStructures(
                                  structureInfo
                                      .map((s) => s['type'] as StructureType)
                                      .toSet(),
                                );
                                state.setIncludeStructures(true);
                              },
                              child: Text(l10n.selectAll),
                            ),
                            TextButton(
                              onPressed: selectedStructures.isEmpty
                                  ? null
                                  : () {
                                      state.setSelectedStructures({});
                                      state.setIncludeStructures(false);
                                    },
                              child: Text(l10n.clearAll),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in structureInfo)
                              Builder(
                                builder: (context) {
                                  final type = s['type'] as StructureType;
                                  final rarity = s['rarity'] as String;
                                  return Tooltip(
                                    message: rarity,
                                    child: FilterChip(
                                      avatar: _Dot(
                                        color: StructureUtils.getRarityColor(
                                          rarity,
                                          isDark: _isDark,
                                        ),
                                      ),
                                      label: Text(s['name'] as String),
                                      selected: selectedStructures.contains(
                                        type,
                                      ),
                                      onSelected: (v) => _toggleStructure(
                                        state,
                                        type,
                                        v,
                                        selectedStructures,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        if (hiddenStructures > 0) ...[
                          const SizedBox(height: 8),
                          _Note(
                            text: l10n.structureUnavailableInVersion(
                              hiddenStructures,
                            ),
                          ),
                        ],
                        if (selectedStructures.length > 1 &&
                            context.watch<MonetizationConfig>().isEnabled &&
                            !context.watch<ProStatusProvider>().isPro) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Free tier searches 1 structure at a time. Upgrade to Pro for all at once.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: GamerColors.purpleText(_isDark),
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// The slice of [SearchState] this card displays. Dart records compare their
/// fields with `==`, so `context.select` only rebuilds the card when one of
/// these values is replaced.
typedef _Slice = ({
  Set<OreType> ores,
  bool includeOres,
  bool includeNether,
  Set<StructureType> structures,
  bool includeStructures,
  MinecraftEdition edition,
  VersionEra era,
});

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  const _Note({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
