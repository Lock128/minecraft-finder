import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Primary search action, pinned below the scrolling form so it is always
/// reachable. Shows an indeterminate progress bar while a search runs.
class SearchActionBar extends StatelessWidget {
  final bool isLoading;

  /// Whether the whole-world Netherite scope is active. When true, the single
  /// action performs the deep scan instead of a radius-bounded search.
  final bool wholeWorldActive;
  final ValueChanged<bool> onFindOres;

  const SearchActionBar({
    super.key,
    required this.isLoading,
    required this.wholeWorldActive,
    required this.onFindOres,
  });

  void _showInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.showSearchInfo,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(l10n.regularSearchInfo),
              if (wholeWorldActive) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.comprehensiveNetheriteSearch,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(l10n.comprehensiveNetheriteBody),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 3,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLoading
                    ? const LinearProgressIndicator(
                        key: ValueKey('search-progress'),
                      )
                    : const SizedBox.shrink(key: ValueKey('search-idle')),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => onFindOres(wholeWorldActive),
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              wholeWorldActive
                                  ? Icons.local_fire_department_outlined
                                  : Icons.search,
                            ),
                      label: Text(
                        isLoading ? l10n.searchingButton : l10n.findButton,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showInfo(context),
                    icon: const Icon(Icons.help_outline),
                    tooltip: l10n.showSearchInfo,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
