import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/ore_location.dart';
import '../models/structure_location.dart';
import '../theme/gamer_theme.dart';
import '../utils/ore_utils.dart';
import '../utils/structure_utils.dart';

/// A 2D top-down mini-map widget showing found ore/structure locations as
/// colored dots on a coordinate grid. X-axis is X coordinate, Y-axis is Z.
/// Supports zoom and pan via InteractiveViewer.
class ResultsMapView extends StatefulWidget {
  final List<OreLocation> results;
  final List<StructureLocation> structureResults;
  final bool isDarkMode;

  const ResultsMapView({
    super.key,
    required this.results,
    required this.structureResults,
    required this.isDarkMode,
  });

  @override
  State<ResultsMapView> createState() => _ResultsMapViewState();
}

class _ResultsMapViewState extends State<ResultsMapView> {
  String? _tooltipText;
  Offset? _tooltipPosition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = widget.isDarkMode;

    if (widget.results.isEmpty && widget.structureResults.isEmpty) {
      return Center(
        child: Text(l10n.noResultsYet,
            style: Theme.of(context).textTheme.headlineSmall),
      );
    }

    return Column(
      children: [
        _buildLegend(context, isDark, l10n),
        Expanded(
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                boundaryMargin: const EdgeInsets.all(100),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _MapPainter(
                        results: widget.results,
                        structureResults: widget.structureResults,
                        isDarkMode: isDark,
                      ),
                      child: GestureDetector(
                        onTapDown: (details) =>
                            _handleTap(details, constraints),
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_tooltipText != null && _tooltipPosition != null)
                Positioned(
                  left: _tooltipPosition!.dx.clamp(0, 200),
                  top: _tooltipPosition!.dy.clamp(0, 200),
                  child: _buildTooltip(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context, bool isDark, AppLocalizations l10n) {
    final oreTypes = widget.results.map((r) => r.oreType).toSet();
    final hasStructures = widget.structureResults.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? GamerColors.darkSurface.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: GamerColors.neonGreen.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          ...oreTypes.map((ore) => _legendItem(
                _getOreColor(ore, isDark),
                OreUtils.getOreEmoji(ore),
                ore.name,
              )),
          if (hasStructures)
            _legendItem(
              isDark ? GamerColors.neonOrange : GamerColors.lightOrange,
              '🏰',
              l10n.mapLegendStructures,
            ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String emoji, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text('$emoji $label', style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildTooltip() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(maxWidth: 180),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? GamerColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: GamerColors.neonGreen.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          _tooltipText!,
          style: TextStyle(
            fontSize: 10,
            color: widget.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  void _handleTap(TapDownDetails details, BoxConstraints constraints) {
    final tapPos = details.localPosition;
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    // Calculate bounds
    final allX = [
      ...widget.results.map((r) => r.x),
      ...widget.structureResults.map((r) => r.x),
    ];
    final allZ = [
      ...widget.results.map((r) => r.z),
      ...widget.structureResults.map((r) => r.z),
    ];

    if (allX.isEmpty) return;

    final minX = allX.reduce((a, b) => a < b ? a : b).toDouble();
    final maxX = allX.reduce((a, b) => a > b ? a : b).toDouble();
    final minZ = allZ.reduce((a, b) => a < b ? a : b).toDouble();
    final maxZ = allZ.reduce((a, b) => a > b ? a : b).toDouble();

    final rangeX = (maxX - minX).clamp(1, double.infinity);
    final rangeZ = (maxZ - minZ).clamp(1, double.infinity);
    final padding = 40.0;
    final drawW = width - padding * 2;
    final drawH = height - padding * 2;

    // Check ore hits
    for (final ore in widget.results) {
      final px = padding + ((ore.x - minX) / rangeX) * drawW;
      final py = padding + ((ore.z - minZ) / rangeZ) * drawH;
      if ((tapPos - Offset(px, py)).distance < 12) {
        setState(() {
          _tooltipText =
              '${OreUtils.getOreEmoji(ore.oreType)} ${ore.oreType.name}\n'
              '(${ore.x}, ${ore.y}, ${ore.z})\n'
              '${(ore.probability * 100).toStringAsFixed(1)}%';
          _tooltipPosition = tapPos;
        });
        return;
      }
    }

    // Check structure hits
    for (final s in widget.structureResults) {
      final px = padding + ((s.x - minX) / rangeX) * drawW;
      final py = padding + ((s.z - minZ) / rangeZ) * drawH;
      if ((tapPos - Offset(px, py)).distance < 12) {
        setState(() {
          _tooltipText =
              '${StructureUtils.getStructureEmoji(s.structureType)} ${s.structureType.name}\n'
              '(${s.x}, ${s.y}, ${s.z})\n'
              '${(s.probability * 100).toStringAsFixed(1)}%';
          _tooltipPosition = tapPos;
        });
        return;
      }
    }

    // Tap on empty space clears tooltip
    setState(() {
      _tooltipText = null;
      _tooltipPosition = null;
    });
  }

  Color _getOreColor(OreType oreType, bool isDark) {
    switch (oreType) {
      case OreType.diamond:
        return isDark ? GamerColors.diamondNeon : GamerColors.lightDiamond;
      case OreType.gold:
        return isDark ? GamerColors.goldNeon : GamerColors.lightGold;
      case OreType.netherite:
        return isDark ? GamerColors.netheriteNeon : GamerColors.lightNetherite;
      case OreType.redstone:
        return isDark ? GamerColors.redstoneNeon : GamerColors.lightRedstone;
      case OreType.iron:
        return isDark ? GamerColors.ironNeon : GamerColors.lightIron;
      case OreType.coal:
        return isDark ? GamerColors.coalNeon : GamerColors.lightCoal;
      case OreType.lapis:
        return isDark ? GamerColors.lapisNeon : GamerColors.lightLapis;
    }
  }
}

class _MapPainter extends CustomPainter {
  final List<OreLocation> results;
  final List<StructureLocation> structureResults;
  final bool isDarkMode;

  _MapPainter({
    required this.results,
    required this.structureResults,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final allX = [
      ...results.map((r) => r.x),
      ...structureResults.map((r) => r.x),
    ];
    final allZ = [
      ...results.map((r) => r.z),
      ...structureResults.map((r) => r.z),
    ];

    if (allX.isEmpty) return;

    final minX = allX.reduce((a, b) => a < b ? a : b).toDouble();
    final maxX = allX.reduce((a, b) => a > b ? a : b).toDouble();
    final minZ = allZ.reduce((a, b) => a < b ? a : b).toDouble();
    final maxZ = allZ.reduce((a, b) => a > b ? a : b).toDouble();

    final rangeX = (maxX - minX).clamp(1, double.infinity);
    final rangeZ = (maxZ - minZ).clamp(1, double.infinity);

    const padding = 40.0;
    final drawW = size.width - padding * 2;
    final drawH = size.height - padding * 2;

    // Draw grid
    _drawGrid(canvas, size, padding, minX, maxX, minZ, maxZ);

    // Draw ore dots
    for (final ore in results) {
      final px = padding + ((ore.x - minX) / rangeX) * drawW;
      final py = padding + ((ore.z - minZ) / rangeZ) * drawH;
      final color = _oreColor(ore.oreType);
      final radius = 4.0 + (ore.probability * 4);

      canvas.drawCircle(
        Offset(px, py),
        radius,
        Paint()
          ..color = color.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(px, py),
        radius,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Draw structure dots (square markers)
    for (final s in structureResults) {
      final px = padding + ((s.x - minX) / rangeX) * drawW;
      final py = padding + ((s.z - minZ) / rangeZ) * drawH;
      final color =
          isDarkMode ? GamerColors.neonOrange : GamerColors.lightOrange;
      const half = 5.0;

      canvas.drawRect(
        Rect.fromCenter(center: Offset(px, py), width: half * 2, height: half * 2),
        Paint()
          ..color = color.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(px, py), width: half * 2, height: half * 2),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Draw axis labels
    _drawAxisLabels(canvas, size, padding, minX, maxX, minZ, maxZ);
  }

  void _drawGrid(Canvas canvas, Size size, double padding, double minX,
      double maxX, double minZ, double maxZ) {
    final gridPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final drawW = size.width - padding * 2;
    final drawH = size.height - padding * 2;

    // Draw 5 vertical and horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final x = padding + (i / 4) * drawW;
      final y = padding + (i / 4) * drawH;
      canvas.drawLine(Offset(x, padding), Offset(x, padding + drawH), gridPaint);
      canvas.drawLine(Offset(padding, y), Offset(padding + drawW, y), gridPaint);
    }
  }

  void _drawAxisLabels(Canvas canvas, Size size, double padding, double minX,
      double maxX, double minZ, double maxZ) {
    final textStyle = TextStyle(
      fontSize: 9,
      color: isDarkMode ? Colors.white38 : Colors.grey[400],
    );

    final drawW = size.width - padding * 2;
    final drawH = size.height - padding * 2;

    // X axis labels (bottom)
    for (int i = 0; i <= 4; i++) {
      final value = minX + (i / 4) * (maxX - minX);
      final tp = TextPainter(
        text: TextSpan(text: value.toInt().toString(), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(padding + (i / 4) * drawW - tp.width / 2, size.height - padding + 4),
      );
    }

    // Z axis labels (left)
    for (int i = 0; i <= 4; i++) {
      final value = minZ + (i / 4) * (maxZ - minZ);
      final tp = TextPainter(
        text: TextSpan(text: value.toInt().toString(), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(padding - tp.width - 4, padding + (i / 4) * drawH - tp.height / 2),
      );
    }

    // Axis titles
    final xTitle = TextPainter(
      text: TextSpan(text: 'X', style: textStyle.copyWith(fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    xTitle.paint(canvas, Offset(size.width / 2 - xTitle.width / 2, size.height - 14));

    final zTitle = TextPainter(
      text: TextSpan(text: 'Z', style: textStyle.copyWith(fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    zTitle.paint(canvas, Offset(4, size.height / 2 - zTitle.height / 2));
  }

  Color _oreColor(OreType oreType) {
    switch (oreType) {
      case OreType.diamond:
        return GamerColors.diamondNeon;
      case OreType.gold:
        return GamerColors.goldNeon;
      case OreType.netherite:
        return GamerColors.netheriteNeon;
      case OreType.redstone:
        return GamerColors.redstoneNeon;
      case OreType.iron:
        return GamerColors.ironNeon;
      case OreType.coal:
        return GamerColors.coalNeon;
      case OreType.lapis:
        return GamerColors.lapisNeon;
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) {
    return results != oldDelegate.results ||
        structureResults != oldDelegate.structureResults ||
        isDarkMode != oldDelegate.isDarkMode;
  }
}
