import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../theme/gamer_theme.dart';

class SearchCenterCard extends StatelessWidget {
  final TextEditingController xController;
  final TextEditingController yController;
  final TextEditingController zController;
  final TextEditingController radiusController;
  final bool isDarkMode;

  const SearchCenterCard({
    super.key,
    required this.xController,
    required this.yController,
    required this.zController,
    required this.radiusController,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GamerCard(
      isDarkMode: isDarkMode,
      accentColor: GamerColors.neonCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GamerSectionHeader(
            emoji: '📍',
            title: l10n.searchCenterTitle,
            isDarkMode: isDarkMode,
            accentColor: GamerColors.neonCyan,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildCoordField(context, xController, l10n.coordinateX, l10n)),
              const SizedBox(width: 8),
              Expanded(child: _buildCoordField(context, yController, l10n.coordinateY, l10n, hint: '-59')),
              const SizedBox(width: 8),
              Expanded(child: _buildCoordField(context, zController, l10n.coordinateZ, l10n)),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: radiusController,
            decoration: InputDecoration(
              labelText: l10n.searchRadiusLabel,
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('🔍', style: TextStyle(fontSize: 16)),
              ),
              filled: true,
              fillColor: isDarkMode ? GamerColors.darkSurface : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.white12 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: GamerColors.neonCyan, width: 2),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) return l10n.errorEmptyRadius;
              final radius = int.tryParse(value);
              if (radius == null || radius <= 0) return l10n.errorRadiusPositive;
              if (radius > 2000) return l10n.errorRadiusMax;
              return null;
            },
          ),
        ],
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
        filled: true,
        fillColor: isDarkMode ? GamerColors.darkSurface : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDarkMode ? Colors.white12 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GamerColors.neonCyan, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(Icons.swap_horiz, size: 16,
            color: isDarkMode ? GamerColors.neonCyan : Colors.grey[600]),
          onPressed: () {
            final t = controller.text;
            if (t.isEmpty) return;
            controller.text = t.startsWith('-') ? t.substring(1) : '-$t';
          },
          tooltip: l10n.togglePlusMinus,
        ),
      ),
      keyboardType: TextInputType.numberWithOptions(signed: true, decimal: false),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))],
      validator: (value) {
        if (value == null || value.isEmpty) return l10n.errorFieldRequired;
        final v = int.tryParse(value);
        if (v == null) return l10n.errorFieldInvalid;
        if (label == l10n.coordinateY && (v < -64 || v > 320)) return l10n.errorYRange;
        return null;
      },
    );
  }
}
