import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../theme/gamer_theme.dart';

/// Coordinates and radius of the search area, plus the whole-world Netherite
/// scope.
class SearchCenterCard extends StatelessWidget {
  final TextEditingController xController;
  final TextEditingController yController;
  final TextEditingController zController;
  final TextEditingController radiusController;
  final bool isDarkMode;

  /// Whether Netherite is currently selected. The whole-world scope option is
  /// Netherite-specific, so it only appears when this is true.
  final bool netheriteSelected;

  /// Whether the whole-world Netherite scope is currently active.
  final bool wholeWorldNetherite;

  /// Toggles the whole-world scope. The parent applies Pro gating.
  final ValueChanged<bool>? onWholeWorldChanged;

  const SearchCenterCard({
    super.key,
    required this.xController,
    required this.yController,
    required this.zController,
    required this.radiusController,
    this.isDarkMode = false,
    this.netheriteSelected = false,
    this.wholeWorldNetherite = false,
    this.onWholeWorldChanged,
  });

  bool get wholeWorld => netheriteSelected && wholeWorldNetherite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GamerSectionHeader(
          icon: Icons.my_location_outlined,
          title: l10n.searchCenterTitle,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCoordField(
                context,
                xController,
                l10n.coordinateX,
                l10n,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCoordField(
                context,
                yController,
                l10n.coordinateY,
                l10n,
                hint: '-59',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCoordField(
                context,
                zController,
                l10n.coordinateZ,
                l10n,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: radiusController,
          enabled: !wholeWorld,
          decoration: InputDecoration(
            labelText: l10n.searchRadiusLabel,
            hintText: wholeWorld ? l10n.wholeWorldActiveHint : null,
            prefixIcon: const Icon(Icons.radar),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            // Radius is ignored when scanning the whole world.
            if (wholeWorld) return null;
            if (value == null || value.isEmpty) return l10n.errorEmptyRadius;
            final radius = int.tryParse(value);
            if (radius == null || radius <= 0) {
              return l10n.errorRadiusPositive;
            }
            if (radius > 2000) return l10n.errorRadiusMax;
            return null;
          },
        ),
        // Whole-world scope is Netherite-specific, so it only appears when
        // Netherite is selected.
        if (netheriteSelected) ...[
          const SizedBox(height: 12),
          _buildWholeWorldToggle(context, l10n),
        ],
      ],
    );
    return GamerCard(isDarkMode: isDarkMode, child: content);
  }

  Widget _buildWholeWorldToggle(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final accent = GamerColors.purpleText(isDarkMode);
    return Material(
      color: wholeWorldNetherite
          ? accent.withValues(alpha: 0.10)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: wholeWorldNetherite
              ? accent.withValues(alpha: 0.6)
              : scheme.outlineVariant,
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        value: wholeWorldNetherite,
        onChanged: (v) => onWholeWorldChanged?.call(v),
        title: Row(
          children: [
            Flexible(child: Text(l10n.wholeWorldNetheriteTitle)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PRO',
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(l10n.wholeWorldNetheriteSubtitle),
      ),
    );
  }

  Widget _buildCoordField(
    BuildContext context,
    TextEditingController controller,
    String label,
    AppLocalizations l10n, {
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: IconButton(
          icon: const Icon(Icons.swap_horiz, size: 18),
          onPressed: () {
            final t = controller.text;
            if (t.isEmpty) return;
            controller.text = t.startsWith('-') ? t.substring(1) : '-$t';
          },
          tooltip: l10n.togglePlusMinus,
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: false,
      ),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))],
      validator: (value) {
        if (value == null || value.isEmpty) return l10n.errorFieldRequired;
        final v = int.tryParse(value);
        if (v == null) return l10n.errorFieldInvalid;
        if (label == l10n.coordinateY && (v < -64 || v > 320)) {
          return l10n.errorYRange;
        }
        return null;
      },
    );
  }
}
