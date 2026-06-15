import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/favorite_location.dart';
import '../models/ore_location.dart';
import '../providers/favorites_provider.dart';
import '../theme/gamer_theme.dart';
import '../utils/ore_utils.dart';
import '../utils/structure_utils.dart';

class FavoritesTab extends StatelessWidget {
  final bool isDarkMode;

  const FavoritesTab({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    FavoritesProvider? favoritesProvider;
    try {
      favoritesProvider = context.watch<FavoritesProvider>();
    } catch (_) {
      return _buildEmptyState(context, l10n);
    }
    final grouped = favoritesProvider.groupedBySeed;

    if (favoritesProvider.favorites.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return Container(
      color: isDarkMode ? GamerColors.darkBg : GamerColors.lightBg,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: grouped.keys.length,
        itemBuilder: (context, index) {
          final seed = grouped.keys.elementAt(index);
          final items = grouped[seed]!;
          return _buildSeedGroup(context, seed, items, l10n);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(l10n.favoritesEmpty,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(l10n.favoritesEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildSeedGroup(BuildContext context, String seed,
      List<FavoriteLocation> items, AppLocalizations l10n) {
    return GamerCard(
      isDarkMode: isDarkMode,
      accentColor: GamerColors.neonPurple,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.landscape,
                  size: 16,
                  color: isDarkMode
                      ? GamerColors.neonPurple
                      : GamerColors.lightPurple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l10n.favoritesSeedLabel} $seed',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: isDarkMode
                        ? GamerColors.neonPurple
                        : GamerColors.lightPurple,
                  ),
                ),
              ),
              Text(
                '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((fav) => _buildFavoriteItem(context, fav, l10n)),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(
      BuildContext context, FavoriteLocation fav, AppLocalizations l10n) {
    final color = fav.type == FavoriteType.ore
        ? _getOreColor(fav.oreLocation!.oreType)
        : (isDarkMode ? GamerColors.neonOrange : GamerColors.lightOrange);

    return Dismissible(
      key: Key(fav.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.withValues(alpha: 0.2),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) {
        context.read<FavoritesProvider>().removeFavorite(fav.id);
      },
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(
              fav.type == FavoriteType.ore
                  ? OreUtils.getOreEmoji(fav.oreLocation!.oreType)
                  : StructureUtils.getStructureEmoji(
                      fav.structureLocation!.structureType),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fav.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    '(${fav.x}, ${fav.y}, ${fav.z})',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  if (fav.label.isNotEmpty)
                    Text(
                      fav.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.copy, size: 16, color: Colors.grey[400]),
              onPressed: () => _copyCoordinates(context, fav, l10n),
              tooltip: l10n.copyCoordinates,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Color _getOreColor(OreType oreType) {
    switch (oreType) {
      case OreType.diamond:
        return isDarkMode ? GamerColors.diamondNeon : GamerColors.lightDiamond;
      case OreType.gold:
        return isDarkMode ? GamerColors.goldNeon : GamerColors.lightGold;
      case OreType.netherite:
        return isDarkMode
            ? GamerColors.netheriteNeon
            : GamerColors.lightNetherite;
      case OreType.redstone:
        return isDarkMode
            ? GamerColors.redstoneNeon
            : GamerColors.lightRedstone;
      case OreType.iron:
        return isDarkMode ? GamerColors.ironNeon : GamerColors.lightIron;
      case OreType.coal:
        return isDarkMode ? GamerColors.coalNeon : GamerColors.lightCoal;
      case OreType.lapis:
        return isDarkMode ? GamerColors.lapisNeon : GamerColors.lightLapis;
    }
  }

  void _copyCoordinates(
      BuildContext context, FavoriteLocation fav, AppLocalizations l10n) {
    final coords = '${fav.x} ${fav.y} ${fav.z}';
    Clipboard.setData(ClipboardData(text: coords));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.copiedCoordinates(coords)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
