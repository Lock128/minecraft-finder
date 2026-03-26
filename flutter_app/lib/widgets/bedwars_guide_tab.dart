import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/bedwars_guide_data.dart';
import '../theme/gamer_theme.dart';

/// A row of selectable chips for switching between Bedwars skill tiers.
class TierSelector extends StatelessWidget {
  final SkillTier selectedTier;
  final ValueChanged<SkillTier> onTierChanged;
  final bool isDarkMode;

  const TierSelector({
    super.key,
    required this.selectedTier,
    required this.onTierChanged,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: SkillTier.values.map((tier) {
        final isSelected = tier == selectedTier;
        final accentColor = tier.accentColor;
        final label = _tierLabel(l10n, tier);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: tier == SkillTier.starters ? 0 : 4,
              right: tier == SkillTier.experts ? 0 : 4,
            ),
            child: GestureDetector(
              onTap: () => onTierChanged(tier),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? accentColor.withValues(alpha: isDarkMode ? 0.2 : 0.15)
                      : isDarkMode
                          ? GamerColors.darkCard
                          : GamerColors.lightCard,
                  border: Border.all(
                    color: isSelected
                        ? accentColor
                        : (isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.3)),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected && isDarkMode
                      ? GamerColors.subtleGlow(accentColor)
                      : null,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? accentColor
                        : (isDarkMode ? Colors.white70 : Colors.grey[700]),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _tierLabel(AppLocalizations l10n, SkillTier tier) {
    switch (tier) {
      case SkillTier.starters:
        return l10n.bedwarsTierStarters;
      case SkillTier.practitioners:
        return l10n.bedwarsTierPractitioners;
      case SkillTier.experts:
        return l10n.bedwarsTierExperts;
    }
  }
}


/// A single localized guide section with a title, emoji, accent color, and content lines.
class _LocalizedGuideSection {
  final String title;
  final String emoji;
  final Color accentColor;
  final List<String> content;

  const _LocalizedGuideSection({
    required this.title,
    required this.emoji,
    required this.accentColor,
    required this.content,
  });
}

/// The root widget for the Bedwars guide tab.
/// Displays a tier selector pinned at the top and scrollable guide content below.
class BedwarsGuideTab extends StatefulWidget {
  final bool isDarkMode;

  const BedwarsGuideTab({super.key, required this.isDarkMode});

  @override
  State<BedwarsGuideTab> createState() => _BedwarsGuideTabState();
}

class _BedwarsGuideTabState extends State<BedwarsGuideTab> {
  SkillTier _selectedTier = SkillTier.starters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isDarkMode
              ? [GamerColors.darkBg, GamerColors.darkSurface]
              : [GamerColors.lightBg, GamerColors.lightCard],
        ),
      ),
      child: Column(
        children: [
          // Pinned TierSelector at top
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TierSelector(
              selectedTier: _selectedTier,
              onTierChanged: (tier) {
                setState(() {
                  _selectedTier = tier;
                });
              },
              isDarkMode: widget.isDarkMode,
            ),
          ),
          // Scrollable guide content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildSectionCards(l10n),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_LocalizedGuideSection> _sectionsForTier(AppLocalizations l10n) {
    switch (_selectedTier) {
      case SkillTier.starters:
        return [
          _LocalizedGuideSection(
            title: l10n.bedwarsGameObjectiveTitle,
            emoji: '🎯',
            accentColor: GamerColors.neonGreen,
            content: [
              l10n.bedwarsGameObjective1,
              l10n.bedwarsGameObjective2,
              l10n.bedwarsGameObjective3,
              l10n.bedwarsGameObjective4,
            ],
          ),
          _LocalizedGuideSection(
            title: l10n.bedwarsResourceGatheringTitle,
            emoji: '⛏️',
            accentColor: GamerColors.neonGreen,
            content: [
              l10n.bedwarsResourceGathering1,
              l10n.bedwarsResourceGathering2,
              l10n.bedwarsResourceGathering3,
              l10n.bedwarsResourceGathering4,
            ],
          ),
          _LocalizedGuideSection(
            title: l10n.bedwarsPurchasingTitle,
            emoji: '🛒',
            accentColor: GamerColors.neonGreen,
            content: [
              l10n.bedwarsPurchasing1,
              l10n.bedwarsPurchasing2,
              l10n.bedwarsPurchasing3,
              l10n.bedwarsPurchasing4,
            ],
          ),
          _LocalizedGuideSection(
            title: l10n.bedwarsBedDefenseTitle,
            emoji: '🛡️',
            accentColor: GamerColors.neonGreen,
            content: [
              l10n.bedwarsBedDefense1,
              l10n.bedwarsBedDefense2,
              l10n.bedwarsBedDefense3,
              l10n.bedwarsBedDefense4,
            ],
          ),
          _LocalizedGuideSection(
            title: l10n.bedwarsCombatTipsTitle,
            emoji: '⚔️',
            accentColor: GamerColors.neonGreen,
            content: [
              l10n.bedwarsCombatTips1,
              l10n.bedwarsCombatTips2,
              l10n.bedwarsCombatTips3,
              l10n.bedwarsCombatTips4,
            ],
          ),
        ];
      case SkillTier.practitioners:
        return [
          _LocalizedGuideSection(
            title: l10n.bedwarsResourceManagementTitle,
            emoji: '💎',
            accentColor: GamerColors.neonCyan,
            content: [
              l10n.bedwarsResourceManagement1,
              l10n.bedwarsResourceManagement2,
              l10n.bedwarsResourceManagement3,
              l10n.bedwarsResourceManagement4,
            ],
          ),
          _LocalizedGuideSection(
            title: l10n.bedwarsIntermediateDefenseTitle,
            emoji: '🏰',
            accentColor: GamerColors.neonCyan,
            content: [
              l10n.bedwarsIntermediateDefense1,
              l10n.bedwarsIntermediateDefense2,
              l10n.bedwarsIntermediateDefense3,
              l10n.bedwarsIntermediateDefense4,
            ],
          ),
          _LocalizedGuideSection(
            title: l10n.bedwarsTeamCoordinationTitle,
            emoji: '🤝',
            accentColor: GamerColors.neonCyan,
            content: [
              l10n.bedwarsTeamCoordination1,
              l10n.bedwarsTeamCoordination2,
              l10n.bedwarsTeamCoordination3,
              l10n.bedwarsTeamCoordination4,
            ],
          ),
          _LocalizedGuideSection(
            title: l10n.bedwarsBridgeBuildingTitle,
            emoji: '🌉',
            accentColor: GamerColors.neonCyan,
            content: [
              l10n.bedwarsBridgeBuilding1,
              l10n.bedwarsBridgeBuilding2,
              l10n.bedwarsBridgeBuilding3,
              l10n.bedwarsBridgeBuilding4,
            ],
          ),
          _LocalizedGuideSection(
            title: l10n.bedwarsMidGameCombatTitle,
            emoji: '🗡️',
            accentColor: GamerColors.neonCyan,
            content: [
              l10n.bedwarsMidGameCombat1,
              l10n.bedwarsMidGameCombat2,
              l10n.bedwarsMidGameCombat3,
              l10n.bedwarsMidGameCombat4,
            ],
          ),
        ];
      case SkillTier.experts:
        return [
          _LocalizedGuideSection(
            title: l10n.bedwarsAdvancedPvpTitle,
            emoji: '🔥',
            accentColor: GamerColors.neonPink,
            content: [
              l10n.bedwarsAdvancedPvp1,
              l10n.bedwarsAdvancedPvp2,
              l10n.bedwarsAdvancedPvp3,
              l10n.bedwarsAdvancedPvp4,
            ],
          ),
          _LocalizedGuideSection(
            title: l10n.bedwarsSpeedBridgingTitle,
            emoji: '🏃',
            accentColor: GamerColors.neonPink,
            content: [
              l10n.bedwarsSpeedBridging1,
              l10n.bedwarsSpeedBridging2,
              l10n.bedwarsSpeedBridging3,
              l10n.bedwarsSpeedBridging4,
            ],
          ),
          _LocalizedGuideSection(
            title: l10n.bedwarsRushStrategiesTitle,
            emoji: '⚡',
            accentColor: GamerColors.neonPink,
            content: [
              l10n.bedwarsRushStrategies1,
              l10n.bedwarsRushStrategies2,
              l10n.bedwarsRushStrategies3,
              l10n.bedwarsRushStrategies4,
            ],
          ),
          _LocalizedGuideSection(
            title: l10n.bedwarsEndgameTitle,
            emoji: '👑',
            accentColor: GamerColors.neonPink,
            content: [
              l10n.bedwarsEndgame1,
              l10n.bedwarsEndgame2,
              l10n.bedwarsEndgame3,
              l10n.bedwarsEndgame4,
            ],
          ),
          _LocalizedGuideSection(
            title: l10n.bedwarsCounterStrategiesTitle,
            emoji: '🧠',
            accentColor: GamerColors.neonPink,
            content: [
              l10n.bedwarsCounterStrategies1,
              l10n.bedwarsCounterStrategies2,
              l10n.bedwarsCounterStrategies3,
              l10n.bedwarsCounterStrategies4,
            ],
          ),
        ];
    }
  }

  List<Widget> _buildSectionCards(AppLocalizations l10n) {
    final sections = _sectionsForTier(l10n);
    final widgets = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      if (i > 0) {
        widgets.add(const SizedBox(height: 12));
      }
      widgets.add(_buildGuideCard(sections[i]));
    }
    return widgets;
  }

  Widget _buildGuideCard(_LocalizedGuideSection section) {
    return GamerCard(
      isDarkMode: widget.isDarkMode,
      accentColor: section.accentColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GamerSectionHeader(
            emoji: section.emoji,
            title: section.title,
            isDarkMode: widget.isDarkMode,
            accentColor: section.accentColor,
          ),
          const SizedBox(height: 16),
          ...section.content.map((line) {
            if (line.isEmpty) return const SizedBox(height: 8);
            if (line.startsWith('🎯') || line.startsWith('🌍') ||
                line.startsWith('🏜️') || line.startsWith('🔍') ||
                line.startsWith('🏘️') || line.startsWith('🏛️')) {
              return Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Text(line,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: section.accentColor,
                    fontSize: 14,
                  )),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(line,
                style: TextStyle(
                  height: 1.5,
                  fontSize: 13,
                  color: widget.isDarkMode ? Colors.white70 : Colors.grey[700],
                )),
            );
          }),
        ],
      ),
    );
  }
}
