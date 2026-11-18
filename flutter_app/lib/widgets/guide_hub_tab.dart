import 'package:material_ui/material_ui.dart';
import '../l10n/app_localizations.dart';
import 'bedwars_guide_tab.dart';
import 'guide_tab.dart';

/// Single "Guide" destination that switches between the Minecraft user guide
/// and the Bedwars guide, so the bottom navigation stays at four items.
class GuideHubTab extends StatefulWidget {
  final bool isDarkMode;

  const GuideHubTab({super.key, required this.isDarkMode});

  @override
  State<GuideHubTab> createState() => _GuideHubTabState();
}

enum _GuideKind { minecraft, bedwars }

class _GuideHubTabState extends State<GuideHubTab> {
  _GuideKind _kind = _GuideKind.minecraft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<_GuideKind>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: _GuideKind.minecraft,
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text(l10n.guideTab),
                ),
                ButtonSegment(
                  value: _GuideKind.bedwars,
                  icon: const Icon(Icons.sports_esports),
                  label: Text(l10n.bedwarsTab),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _kind == _GuideKind.minecraft
                ? GuideTab(
                    key: const ValueKey('guide'),
                    isDarkMode: widget.isDarkMode,
                  )
                : BedwarsGuideTab(
                    key: const ValueKey('bedwars'),
                    isDarkMode: widget.isDarkMode,
                  ),
          ),
        ),
      ],
    );
  }
}
