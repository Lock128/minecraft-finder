import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/search_history_entry.dart';
import '../providers/search_history_provider.dart';
import '../providers/search_state.dart';
import '../theme/gamer_theme.dart';

/// A collapsible section showing recent searches with replay capability.
/// Designed to be placed in the SearchTab below the recent seeds.
class SearchHistoryWidget extends StatefulWidget {
  final bool isDarkMode;

  const SearchHistoryWidget({super.key, required this.isDarkMode});

  @override
  State<SearchHistoryWidget> createState() => _SearchHistoryWidgetState();
}

class _SearchHistoryWidgetState extends State<SearchHistoryWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    SearchHistoryProvider? historyProvider;
    try {
      historyProvider = context.watch<SearchHistoryProvider>();
    } catch (_) {
      // Provider not available in tree (e.g., standalone usage in tests)
      return const SizedBox.shrink();
    }
    final entries = historyProvider.entries;

    if (entries.isEmpty) return const SizedBox.shrink();

    final displayEntries = entries.take(5).toList();
    final isDark = widget.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(Icons.history,
                  size: 14, color: isDark ? Colors.white54 : Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                l10n.searchHistoryTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.grey[500],
                ),
              ),
              const Spacer(),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: isDark ? Colors.white54 : Colors.grey[500],
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          ...displayEntries
              .map((entry) => _buildHistoryItem(context, entry, l10n, isDark)),
        ],
      ],
    );
  }

  Widget _buildHistoryItem(BuildContext context, SearchHistoryEntry entry,
      AppLocalizations l10n, bool isDark) {
    final oreNames =
        entry.oreTypes.map((o) => o.name).take(3).join(', ');
    final structNames =
        entry.structures.map((s) => s.name).take(2).join(', ');

    String subtitle = '';
    if (entry.includeOres && oreNames.isNotEmpty) {
      subtitle += oreNames;
    }
    if (entry.includeStructures && structNames.isNotEmpty) {
      if (subtitle.isNotEmpty) subtitle += ' + ';
      subtitle += structNames;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isDark
            ? GamerColors.neonCyan.withValues(alpha: 0.08)
            : GamerColors.neonCyan.withValues(alpha: 0.04),
        border: Border.all(
          color: GamerColors.neonCyan.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.favoritesSeedLabel} ${entry.seed}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: isDark ? GamerColors.neonCyan : GamerColors.lightCyan,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  '${entry.resultCount} ${l10n.searchHistoryResults} - r${entry.radius}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 28,
            child: TextButton(
              onPressed: () => _replaySearch(context, entry),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.searchHistoryReplay,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? GamerColors.neonGreen : GamerColors.lightGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _replaySearch(BuildContext context, SearchHistoryEntry entry) {
    final searchState = context.read<SearchState>();
    searchState.seedController.text = entry.seed;
    searchState.xController.text = entry.centerX.toString();
    searchState.yController.text = entry.centerY.toString();
    searchState.zController.text = entry.centerZ.toString();
    searchState.radiusController.text = entry.radius.toString();
    searchState.setOreTypes(entry.oreTypes);
    searchState.setSelectedStructures(entry.structures);
    searchState.setEdition(entry.edition);
    searchState.setVersionEra(entry.versionEra);
    searchState.setIncludeOres(entry.includeOres);
    searchState.setIncludeStructures(entry.includeStructures);
  }
}
