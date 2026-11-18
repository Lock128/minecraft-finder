import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/search_state.dart';
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
  bool _expanded = false;
  ValueNotifier<int>? _refreshNotifier;

  @override
  void initState() {
    super.initState();
    _loadRecentSeeds();
    PreferencesService.getRecentSeedsExpanded().then((v) {
      if (mounted && v != _expanded) setState(() => _expanded = v);
    });
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    PreferencesService.setRecentSeedsExpanded(_expanded);
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
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        // One compact, tappable row. The seeds only take space when expanded.
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.history, size: 16, color: muted),
                const SizedBox(width: 6),
                Text(
                  '${l10n.recentSeeds} (${_recentSeeds.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more, size: 18, color: muted),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
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
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onPressed: () => _selectSeed(seed),
                        ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
