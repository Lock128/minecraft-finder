import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../theme/gamer_theme.dart';

class AppInfoDialog extends StatelessWidget {
  final bool isDarkMode;

  const AppInfoDialog({super.key, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDarkMode ? GamerColors.darkCard : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [GamerColors.neonGreen.withValues(alpha: 0.2), GamerColors.neonCyan.withValues(alpha: 0.1)]
                      : [GamerColors.lightGreen.withValues(alpha: 0.1), GamerColors.neonCyan.withValues(alpha: 0.05)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: GamerColors.neonGreen.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [GamerColors.neonGreen, GamerColors.neonCyan],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('⛏️', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.aboutTitle,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close,
                      color: isDarkMode ? Colors.white54 : Colors.grey[500]),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(l10n.aboutWhatTitle),
                    const SizedBox(height: 12),
                    _descCard(
                      l10n.aboutDescTitle,
                      l10n.aboutDescBody,
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle(l10n.aboutResourcesTitle),
                    const SizedBox(height: 12),
                    _buildResourceGrid(l10n),
                    const SizedBox(height: 20),
                    _sectionTitle(l10n.aboutStructuresTitle),
                    const SizedBox(height: 12),
                    _buildStructureChips(l10n),
                    const SizedBox(height: 20),
                    _sectionTitle(l10n.aboutHowItWorksTitle),
                    const SizedBox(height: 12),
                    _buildSteps(l10n),
                    const SizedBox(height: 20),
                    _sectionTitle(l10n.aboutFeaturesTitle),
                    const SizedBox(height: 12),
                    _buildFeatures(l10n),
                    if (kIsWeb) ...[
                      const SizedBox(height: 20),
                      _sectionTitle(l10n.aboutSupportTitle),
                      const SizedBox(height: 12),
                      _buildSupportSection(l10n),
                    ],
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDarkMode ? GamerColors.darkSurface : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: isDarkMode ? GamerColors.neonYellow : GamerColors.lightYellow, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.aboutFooterTip,
                      style: TextStyle(
                        color: isDarkMode ? GamerColors.neonYellow : GamerColors.lightYellow,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.aboutGotIt,
                      style: TextStyle(
                        color: GamerColors.greenText(isDarkMode),
                        fontWeight: FontWeight.w700,
                      )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
      style: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w800,
        color: GamerColors.greenText(isDarkMode),
      ));
  }

  Widget _descCard(String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? GamerColors.darkSurface : GamerColors.neonGreen.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GamerColors.neonGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 15,
            color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
          )),
          const SizedBox(height: 8),
          Text(desc, style: TextStyle(
            fontSize: 13, height: 1.5,
            color: isDarkMode ? Colors.white60 : Colors.grey[600],
          )),
        ],
      ),
    );
  }

  Widget _buildResourceGrid(AppLocalizations l10n) {
    final resources = [
      (l10n.aboutResourceDiamond, '💎', 'Y -64 to 16', GamerColors.diamondNeon),
      (l10n.aboutResourceGold, '🏅', 'Y -64 to 32', GamerColors.goldNeon),
      (l10n.aboutResourceNetherite, '🔥', 'Y 8 to 22', GamerColors.netheriteNeon),
      (l10n.aboutResourceIron, '⚪', 'Y -64 to 256', GamerColors.ironNeon),
      (l10n.aboutResourceRedstone, '🔴', 'Y -64 to 15', GamerColors.redstoneNeon),
      (l10n.aboutResourceCoal, '⚫', 'Y 0 to 256', GamerColors.coalNeon),
      (l10n.aboutResourceLapis, '🔵', 'Y -64 to 64', GamerColors.lapisNeon),
    ];

    return Wrap(
      spacing: 8, runSpacing: 8,
      children: resources.map((r) {
        final (name, emoji, levels, color) = r;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? GamerColors.darkSurface : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(name, style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12,
                color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
              )),
              Text(levels, style: TextStyle(
                fontSize: 10, color: isDarkMode ? Colors.white38 : Colors.grey[500],
              )),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStructureChips(AppLocalizations l10n) {
    final structures = [
      l10n.aboutStructureVillages,
      l10n.aboutStructureStrongholds,
      l10n.aboutStructureDungeons,
      l10n.aboutStructureMineshafts,
      l10n.aboutStructureDesertTemples,
      l10n.aboutStructureJungleTemples,
      l10n.aboutStructureOceanMonuments,
      l10n.aboutStructureWoodlandMansions,
      l10n.aboutStructurePillagerOutposts,
      l10n.aboutStructureRuinedPortals,
    ];

    return Wrap(
      spacing: 6, runSpacing: 4,
      children: structures.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? GamerColors.darkSurface : GamerColors.neonCyan.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GamerColors.neonCyan.withValues(alpha: 0.2)),
        ),
        child: Text(s, style: TextStyle(
          fontSize: 11,
          color: isDarkMode ? GamerColors.neonCyan : Colors.blueGrey[700],
        )),
      )).toList(),
    );
  }

  Widget _buildSteps(AppLocalizations l10n) {
    final steps = [
      l10n.aboutStep1,
      l10n.aboutStep2,
      l10n.aboutStep3,
      l10n.aboutStep4,
      l10n.aboutStep5,
      l10n.aboutStep6,
    ];

    return Column(
      children: steps.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: isDarkMode ? GamerColors.neonGreen.withValues(alpha: 0.2) : GamerColors.lightGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: (isDarkMode ? GamerColors.neonGreen : GamerColors.lightGreen).withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text('${e.key + 1}', style: TextStyle(
                  color: GamerColors.greenText(isDarkMode),
                  fontWeight: FontWeight.w800, fontSize: 11,
                )),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(e.value, style: TextStyle(
              fontSize: 13, height: 1.4,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ))),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildFeatures(AppLocalizations l10n) {
    final features = [
      l10n.aboutFeature1,
      l10n.aboutFeature2,
      l10n.aboutFeature3,
      l10n.aboutFeature4,
      l10n.aboutFeature5,
    ];

    return Column(
      children: features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ ', style: TextStyle(
              color: GamerColors.greenText(isDarkMode),
            )),
            Expanded(child: Text(f, style: TextStyle(
              fontSize: 13, height: 1.4,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ))),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSupportSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? GamerColors.darkSurface : GamerColors.neonYellow.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GamerColors.neonYellow.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.local_cafe, color: Color(0xFFFF6F00), size: 22),
              const SizedBox(width: 8),
              Text(l10n.aboutBuyMeCoffee, style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800,
                color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
              )),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.aboutSupportBody,
            style: TextStyle(
              fontSize: 13, height: 1.4,
              color: isDarkMode ? Colors.white60 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openBuyMeCoffee,
              icon: const Icon(Icons.local_cafe, size: 16),
              label: Text(l10n.aboutSupportButton,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFDD44),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBuyMeCoffee() async {
    if (kIsWeb) {
      try {
        final Uri uri = Uri.parse('https://buymeacoffee.com/lockhead');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }
  }

  static void show(BuildContext context, {bool isDarkMode = false}) {
    showDialog(
      context: context,
      builder: (context) => AppInfoDialog(isDarkMode: isDarkMode),
    );
  }
}
