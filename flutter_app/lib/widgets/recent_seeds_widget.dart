import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/search_state.dart';
import '../theme/gamer_theme.dart';
import '../utils/preferences_service.dart';

class RecentSeedsWidget extends StatefulWidget {
  final TextEditingController seedController;
  final bool isDarkMode;

  const RecentSeedsWidget({
    super.key,
    required this.seedController,
    required this.isDarkMode,
  });

  @override
  State<RecentSeedsWidget> createState() => _RecentSeedsWidgetState();
}

class _RecentSeedsWidgetState extends State<RecentSeedsWidget> {
  List<String> _recentSeeds = [];
  ValueNotifier<int>? _refreshNotifier;

  @override
  void initState() {
    super.initState();
    _loadRecentSeeds();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to the SearchState's refresh notifier if available
    SearchState? searchState;
    try {
      searchState = Provider.of<SearchState>(context, listen: false);
    } catch (_) {
      // Provider not available in tree (e.g., standalone usage)
    }
    if (searchState != null &&
        _refreshNotifier != searchState.recentSeedsRefreshNotifier) {
      _refreshNotifier?.removeListener(_loadRecentSeeds);
      _refreshNotifier = searchState.recentSeedsRefreshNotifier;
      _refreshNotifier!.addListener(_loadRecentSeeds);
    }
  }

  @override
  void dispose() {
    _refreshNotifier?.removeListener(_loadRecentSeeds);
    super.dispose();
  }

  Future<void> _loadRecentSeeds() async {
    final seeds = await PreferencesService.getRecentSeeds();
    if (mounted) {
      setState(() => _recentSeeds = seeds);
    }
  }

  void _selectSeed(String seed) {
    widget.seedController.text = seed;
    PreferencesService.saveLastSeed(seed);
  }

  @override
  Widget build(BuildContext context) {
    if (_recentSeeds.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final isDark = widget.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.history,
                size: 14,
                color: isDark ? Colors.white54 : GamerColors.mutedIcon(context)),
            const SizedBox(width: 4),
            Text(l10n.recentSeeds,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white54
                      : GamerColors.mutedText(context),
                )),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final seed in _recentSeeds)
              ActionChip(
                label: Text(
                  seed,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                visualDensity: VisualDensity.compact,
                onPressed: () => _selectSeed(seed),
              ),
          ],
        ),
      ],
    );
  }
}
