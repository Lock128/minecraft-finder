import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/gamer_theme.dart';

class GuideTab extends StatelessWidget {
  final bool isDarkMode;

  const GuideTab({super.key, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      color: isDarkMode ? GamerColors.darkBg : GamerColors.lightBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGuideCard(
              title: l10n.guideDiamondTitle,
              emoji: '💎',
              accentColor: GamerColors.diamondNeon,
              content: [
                l10n.guideDiamondIntro,
                '',
                l10n.guideDiamondOptimal,
                l10n.guideDiamondLevel1,
                l10n.guideDiamondLevel2,
                l10n.guideDiamondLevel3,
                l10n.guideDiamondLevel4,
              ],
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              title: l10n.guideGoldTitle,
              emoji: '🏅',
              accentColor: GamerColors.goldNeon,
              content: [
                l10n.guideGoldIntro,
                '',
                l10n.guideGoldOverworld,
                l10n.guideGoldLevel1,
                l10n.guideGoldLevel2,
                l10n.guideGoldLevel3,
                '',
                l10n.guideGoldBadlands,
                l10n.guideGoldBadlandsLevel,
                l10n.guideGoldBadlandsBonus,
              ],
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              title: l10n.guideNetheriteTitle,
              emoji: '🔥',
              accentColor: GamerColors.netheriteNeon,
              content: [
                l10n.guideNetheriteIntro,
                '',
                l10n.guideNetheriteOptimal,
                l10n.guideNetheriteLevel1,
                l10n.guideNetheriteLevel2,
                l10n.guideNetheriteLevel3,
                '',
                l10n.guideNetheriteSearch,
                l10n.guideNetheriteRegular,
                l10n.guideNetheriteComprehensive,
              ],
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              title: l10n.guideIronTitle,
              emoji: '⚪',
              accentColor: GamerColors.ironNeon,
              content: [
                l10n.guideIronIntro,
                '',
                l10n.guideIronOptimal,
                l10n.guideIronLevel1,
                l10n.guideIronLevel2,
                l10n.guideIronLevel3,
              ],
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              title: l10n.guideRedstoneTitle,
              emoji: '🔴',
              accentColor: GamerColors.redstoneNeon,
              content: [
                l10n.guideRedstoneIntro,
                '',
                l10n.guideRedstoneOptimal,
                l10n.guideRedstoneLevel1,
                l10n.guideRedstoneLevel2,
                l10n.guideRedstoneLevel3,
                l10n.guideRedstoneLevel4,
              ],
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              title: l10n.guideCoalTitle,
              emoji: '⚫',
              accentColor: GamerColors.coalNeon,
              content: [
                l10n.guideCoalIntro,
                '',
                l10n.guideCoalOptimal,
                l10n.guideCoalLevel1,
                l10n.guideCoalLevel2,
              ],
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              title: l10n.guideLapisTitle,
              emoji: '🔵',
              accentColor: GamerColors.lapisNeon,
              content: [
                l10n.guideLapisIntro,
                '',
                l10n.guideLapisOptimal,
                l10n.guideLapisLevel1,
                l10n.guideLapisLevel2,
                l10n.guideLapisLevel3,
              ],
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              title: l10n.guideStructureTitle,
              emoji: '🏰',
              accentColor: GamerColors.neonOrange,
              content: [
                l10n.guideStructureIntro,
                '',
                l10n.guideStructureCommon,
                l10n.guideStructureVillages,
                l10n.guideStructureOutposts,
                l10n.guideStructurePortals,
                '',
                l10n.guideStructureRare,
                l10n.guideStructureStrongholds,
                l10n.guideStructureEndCities,
                l10n.guideStructureMonuments,
                l10n.guideStructureAncientCities,
              ],
            ),
            const SizedBox(height: 24),
            _buildProTip(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required String title,
    required String emoji,
    required Color accentColor,
    required List<String> content,
  }) {
    // Use darker variant for text in light mode
    final textColor = isDarkMode ? accentColor : _lightVariant(accentColor);

    return GamerCard(
      isDarkMode: isDarkMode,
      accentColor: accentColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GamerSectionHeader(
            emoji: emoji,
            title: title,
            isDarkMode: isDarkMode,
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          ...content.map((line) {
            if (line.isEmpty) return const SizedBox(height: 8);
            if (line.startsWith('🎯') || line.startsWith('🌍') ||
                line.startsWith('🏜️') || line.startsWith('🔍') ||
                line.startsWith('🏘️') || line.startsWith('🏛️')) {
              return Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Text(line,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textColor,
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
                  color: isDarkMode ? Colors.white70 : Colors.grey[700],
                )),
            );
          }),
        ],
      ),
    );
  }

  Color _lightVariant(Color neonColor) {
    if (neonColor == GamerColors.diamondNeon) return GamerColors.lightDiamond;
    if (neonColor == GamerColors.goldNeon) return GamerColors.lightGold;
    if (neonColor == GamerColors.netheriteNeon) return GamerColors.lightNetherite;
    if (neonColor == GamerColors.ironNeon) return GamerColors.lightIron;
    if (neonColor == GamerColors.redstoneNeon) return GamerColors.lightRedstone;
    if (neonColor == GamerColors.coalNeon) return GamerColors.lightCoal;
    if (neonColor == GamerColors.lapisNeon) return GamerColors.lightLapis;
    if (neonColor == GamerColors.neonOrange) return GamerColors.lightOrange;
    if (neonColor == GamerColors.neonGreen) return GamerColors.lightGreen;
    if (neonColor == GamerColors.neonCyan) return GamerColors.lightCyan;
    if (neonColor == GamerColors.neonPurple) return GamerColors.lightPurple;
    return neonColor;
  }

  Widget _buildProTip(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: isDarkMode
              ? [GamerColors.neonCyan.withValues(alpha: 0.1), GamerColors.neonGreen.withValues(alpha: 0.05)]
              : [GamerColors.neonCyan.withValues(alpha: 0.06), GamerColors.neonGreen.withValues(alpha: 0.03)],
        ),
        border: Border.all(color: GamerColors.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.lightbulb, color: GamerColors.cyanText(isDarkMode), size: 28),
          const SizedBox(height: 8),
          Text(l10n.proTipTitle,
            style: TextStyle(
              color: GamerColors.cyanText(isDarkMode),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            )),
          const SizedBox(height: 8),
          Text(
            l10n.proTipBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
