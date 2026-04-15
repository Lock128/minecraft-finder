import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/gamer_theme.dart';

class ReleaseNotesTab extends StatelessWidget {
  final bool isDarkMode;

  const ReleaseNotesTab({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: isDarkMode ? GamerColors.darkBg : GamerColors.lightBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [GamerColors.neonGreen.withValues(alpha: 0.2), GamerColors.neonCyan.withValues(alpha: 0.1)]
                      : [GamerColors.lightGreen.withValues(alpha: 0.1), GamerColors.neonCyan.withValues(alpha: 0.05)],
                ),
                border: Border.all(
                  color: GamerColors.neonGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.update_outlined,
                    color: GamerColors.greenText(isDarkMode), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.releaseNotesHeader,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _sectionHeader(l10n.releaseNotesEditionSection),
            const SizedBox(height: 12),
            _featureItem(l10n.releaseNotesEditionSelectorTitle,
              l10n.releaseNotesEditionSelectorBody),
            const SizedBox(height: 8),
            _featureItem(l10n.releaseNotesVersionEraTitle,
              l10n.releaseNotesVersionEraBody),
            const SizedBox(height: 8),
            _featureItem(l10n.releaseNotesBedrockRngTitle,
              l10n.releaseNotesBedrockRngBody),
            const SizedBox(height: 20),

            _sectionHeader(l10n.releaseNotesBedwarsSection),
            const SizedBox(height: 12),
            _featureItem(l10n.releaseNotesBedwarsGuideTitle,
              l10n.releaseNotesBedwarsGuideBody),
            const SizedBox(height: 8),
            _featureItem(l10n.releaseNotesResourceStrategiesTitle,
              l10n.releaseNotesResourceStrategiesBody),
            const SizedBox(height: 8),
            _featureItem(l10n.releaseNotesDefenseAttackTitle,
              l10n.releaseNotesDefenseAttackBody),
            const SizedBox(height: 20),

            _sectionHeader(l10n.releaseNotesUiSection),
            const SizedBox(height: 12),
            _featureItem(l10n.releaseNotesNeonTitle,
              l10n.releaseNotesNeonBody),
            const SizedBox(height: 8),
            _featureItem(l10n.releaseNotesLightModeTitle,
              l10n.releaseNotesLightModeBody),
            const SizedBox(height: 8),
            _featureItem(l10n.releaseNotesCardsTitle,
              l10n.releaseNotesCardsBody),
            const SizedBox(height: 20),

            _sectionHeader(l10n.releaseNotesAlgorithmSection),
            const SizedBox(height: 12),
            _featureItem(l10n.releaseNotesNoiseTitle,
              l10n.releaseNotesNoiseBody),
            const SizedBox(height: 8),
            _featureItem(l10n.releaseNotesBiomeTitle,
              l10n.releaseNotesBiomeBody),
            const SizedBox(height: 8),
            _featureItem(l10n.releaseNotesPerformanceTitle,
              l10n.releaseNotesPerformanceBody),
            const SizedBox(height: 20),

            _sectionHeader(l10n.releaseNotesHighlightsSection),
            const SizedBox(height: 12),
            _bulletList([
              l10n.releaseNotesHighlight1,
              l10n.releaseNotesHighlight2,
              l10n.releaseNotesHighlight3,
              l10n.releaseNotesHighlight4,
              l10n.releaseNotesHighlight5,
              l10n.releaseNotesHighlight6,
              l10n.releaseNotesHighlight7,
            ]),
            const SizedBox(height: 20),

            _sectionHeader(l10n.releaseNotesTechnicalSection),
            const SizedBox(height: 12),
            _bulletList([
              l10n.releaseNotesTechnical1,
              l10n.releaseNotesTechnical2,
              l10n.releaseNotesTechnical3,
              l10n.releaseNotesTechnical4,
              l10n.releaseNotesTechnical5,
              l10n.releaseNotesTechnical6,
            ]),
            const SizedBox(height: 20),

            _sectionHeader(l10n.releaseNotesPreviousSection),
            const SizedBox(height: 12),
            _featureItem(l10n.releaseNotesV1050Title,
              l10n.releaseNotesV1050Body),
            const SizedBox(height: 8),
            _featureItem(l10n.releaseNotesV1042Title,
              l10n.releaseNotesV1042Body),
            const SizedBox(height: 8),
            _featureItem(l10n.releaseNotesV1041Title,
              l10n.releaseNotesV1041Body),
            const SizedBox(height: 8),
            _featureItem(l10n.releaseNotesV1036Title,
              l10n.releaseNotesV1036Body),
            const SizedBox(height: 8),
            _featureItem(l10n.releaseNotesV1027Title,
              l10n.releaseNotesV1027Body),
            const SizedBox(height: 8),
            _featureItem(l10n.releaseNotesV1022Title,
              l10n.releaseNotesV1022Body),
            const SizedBox(height: 8),
            _featureItem(l10n.releaseNotesV1015Title,
              l10n.releaseNotesV1015Body),
            const SizedBox(height: 8),
            _featureItem(l10n.releaseNotesV1010Title,
              l10n.releaseNotesV1010Body),
            const SizedBox(height: 20),

            _sectionHeader(l10n.releaseNotesTimelineSection),
            const SizedBox(height: 12),
            _buildTimeline(l10n),
            const SizedBox(height: 20),

            // Footer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDarkMode ? GamerColors.darkCard : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GamerColors.neonCyan.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: GamerColors.cyanText(isDarkMode), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.releaseNotesFooter,
                      style: TextStyle(
                        color: GamerColors.cyanText(isDarkMode),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: GamerColors.greenText(isDarkMode),
        letterSpacing: 0.3,
      ));
  }

  Widget _featureItem(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? GamerColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? GamerColors.neonGreen.withValues(alpha: 0.15)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            )),
          const SizedBox(height: 4),
          Text(description,
            style: TextStyle(
              fontSize: 12, height: 1.4,
              color: isDarkMode ? Colors.white60 : Colors.grey[600],
            )),
        ],
      ),
    );
  }

  Widget _bulletList(List<String> items) {
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 5, height: 5,
              decoration: BoxDecoration(
                color: GamerColors.greenText(isDarkMode),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(item,
                style: TextStyle(
                  fontSize: 13, height: 1.4,
                  color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                )),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTimeline(AppLocalizations l10n) {
    final versions = [
      ('1.0.51', l10n.releaseNotesTimelineCurrent, l10n.releaseNotesTimelineEditionVersion, GamerColors.neonOrange),
      ('1.0.50', l10n.releaseNotesTimelinePrevious, l10n.releaseNotesTimelineBedwarsUi, GamerColors.neonGreen),
      ('1.0.42', l10n.releaseNotesTimelineEarlier, l10n.releaseNotesTimelineLapisUi, GamerColors.neonCyan),
      ('1.0.41', l10n.releaseNotesTimelineEarlier, l10n.releaseNotesTimelineRecentSeeds, GamerColors.lapisNeon),
      ('1.0.36', l10n.releaseNotesTimelineEarlier, l10n.releaseNotesTimelineSearchMemory, GamerColors.neonOrange),
      ('1.0.27', l10n.releaseNotesTimelineEarlier, l10n.releaseNotesTimelineVisualUpdates, GamerColors.neonPurple),
      ('1.0.22', l10n.releaseNotesTimelineEarlier, l10n.releaseNotesTimelineExtendedOres, GamerColors.diamondNeon),
      ('1.0.15', l10n.releaseNotesTimelineEarlier, l10n.releaseNotesTimelineStructures, GamerColors.redstoneNeon),
      ('1.0.10', l10n.releaseNotesTimelineEarlier, l10n.releaseNotesTimelineCoreFeatures, GamerColors.coalNeon),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? GamerColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: versions.asMap().entries.map((entry) {
          final i = entry.key;
          final (version, date, highlight, color) = entry.value;
          final isLast = i == versions.length - 1;

          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: isDarkMode ? GamerColors.subtleGlow(color) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('v$version',
                    style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13,
                      color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                    )),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(date,
                      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  Text(highlight,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white38 : Colors.grey[500],
                    )),
                ],
              ),
              if (!isLast) ...[
                const SizedBox(height: 6),
                Container(
                  margin: const EdgeInsets.only(left: 4.5),
                  width: 1, height: 16,
                  color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
                ),
                const SizedBox(height: 6),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }
}
