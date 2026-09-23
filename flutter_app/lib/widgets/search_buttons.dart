import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/gamer_theme.dart';

class SearchButtons extends StatefulWidget {
  final bool isLoading;
  final bool findAllNetherite;
  final Function(bool) onFindOres;
  final bool isDarkMode;

  /// Whether the whole-world Netherite scope is active. When true, the single
  /// primary action performs the deep scan instead of a radius-bounded search.
  final bool wholeWorldActive;

  const SearchButtons({
    super.key,
    required this.isLoading,
    required this.findAllNetherite,
    required this.onFindOres,
    this.isDarkMode = false,
    this.wholeWorldActive = false,
  });

  @override
  State<SearchButtons> createState() => _SearchButtonsState();
}

class _SearchButtonsState extends State<SearchButtons> {
  // Info boxes are collapsed by default to keep the important action button
  // and results in view without extra scrolling.
  bool _showInfo = false;

  bool get isLoading => widget.isLoading;
  bool get findAllNetherite => widget.findAllNetherite;
  Function(bool) get onFindOres => widget.onFindOres;
  bool get isDarkMode => widget.isDarkMode;
  bool get wholeWorldActive => widget.wholeWorldActive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        // A single primary action. Scope (radius vs. whole world) is chosen in
        // the search inputs above, so there is no second competing button.
        _GamerButton(
          onPressed: isLoading ? null : () => onFindOres(wholeWorldActive),
          isLoading: isLoading,
          label: isLoading ? l10n.searchingButton : l10n.findButton,
          emoji: wholeWorldActive ? '🔥' : '⛏️',
          gradient: wholeWorldActive
              ? const [GamerColors.neonPurple, GamerColors.neonPink]
              : const [GamerColors.neonGreen, Color(0xFF00C853)],
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 10),
        // Collapsible help section: keeps the buttons prominent and the
        // screen short, while info is a tap away.
        Align(
          alignment: Alignment.center,
          child: TextButton.icon(
            onPressed: () => setState(() => _showInfo = !_showInfo),
            icon: Icon(
              _showInfo ? Icons.expand_less : Icons.help_outline,
              size: 16,
            ),
            label: Text(
              _showInfo ? l10n.hideSearchInfo : l10n.showSearchInfo,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor:
                  isDarkMode ? GamerColors.neonGreen : GamerColors.lightGreen,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        if (_showInfo) ...[
          const SizedBox(height: 6),
          _buildInfoBox(
            icon: Icons.info_outline,
            color: GamerColors.neonGreen,
            title: null,
            body: l10n.regularSearchInfo,
          ),
          // Explain the whole-world deep scan only when it's the active scope.
          if (wholeWorldActive) ...[
            const SizedBox(height: 8),
            _buildInfoBox(
              icon: Icons.info_outline,
              color: GamerColors.neonPurple,
              title: l10n.comprehensiveNetheriteSearch,
              body: l10n.comprehensiveNetheriteBody,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required Color color,
    String? title,
    required String body,
  }) {
    final textColor = isDarkMode ? color : _lightVariant(color);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDarkMode ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(icon, color: textColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title == null) ...[
                Icon(icon, color: textColor, size: 14),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(body,
                    style: TextStyle(
                      color: isDarkMode
                          ? color.withValues(alpha: 0.8)
                          : textColor.withValues(alpha: 0.8),
                      height: 1.4,
                      fontSize: 11,
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _lightVariant(Color c) {
    if (c == GamerColors.neonPurple) return GamerColors.lightPurple;
    if (c == GamerColors.neonGreen) return GamerColors.lightGreen;
    if (c == GamerColors.neonCyan) return GamerColors.lightCyan;
    if (c == GamerColors.neonOrange) return GamerColors.lightOrange;
    return c;
  }
}

class _GamerButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final String emoji;
  final List<Color> gradient;
  final bool isDarkMode;

  const _GamerButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
    required this.emoji,
    required this.gradient,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: gradient),
        boxShadow: isDarkMode
            ? GamerColors.subtleGlow(gradient.first)
            : [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                else
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
