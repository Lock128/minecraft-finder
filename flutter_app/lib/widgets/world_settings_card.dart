import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../theme/gamer_theme.dart';
import 'recent_seeds_widget.dart';

/// Seed input plus the user's recent seeds. This is the one field every search
/// needs, so it sits at the top of the Search tab without a section title.
class WorldSettingsCard extends StatelessWidget {
  final TextEditingController seedController;
  final bool isDarkMode;
  final VoidCallback? onSeedSearched;

  const WorldSettingsCard({
    super.key,
    required this.seedController,
    required this.isDarkMode,
    this.onSeedSearched,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GamerCard(
      isDarkMode: isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: seedController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.worldSeedLabel,
              hintText: l10n.worldSeedHint,
              prefixIcon: const Icon(Icons.grass_outlined),
              suffixIcon: _SeedSuffix(controller: seedController),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.errorEmptySeed;
              }
              return null;
            },
          ),
          RecentSeedsWidget(
            seedController: seedController,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }
}

/// Paste button while the field is empty, clear button once it has text.
/// Tooltips come from Material's own localizations.
class _SeedSuffix extends StatelessWidget {
  final TextEditingController controller;
  const _SeedSuffix({required this.controller});

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) controller.text = text;
  }

  @override
  Widget build(BuildContext context) {
    final m = MaterialLocalizations.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => value.text.isEmpty
          ? IconButton(
              icon: const Icon(Icons.content_paste),
              tooltip: m.pasteButtonLabel,
              onPressed: _paste,
            )
          : IconButton(
              icon: const Icon(Icons.close),
              tooltip: m.deleteButtonTooltip,
              onPressed: controller.clear,
            ),
    );
  }
}
