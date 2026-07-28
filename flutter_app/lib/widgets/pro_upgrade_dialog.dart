import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pro_status_provider.dart';
import '../theme/gamer_theme.dart';

/// A dialog that shows Pro tier benefits and allows the user to purchase
/// via App Store / Play Store IAP, or restore a previous purchase.
class ProUpgradeDialog extends StatelessWidget {
  final bool isDarkMode;

  const ProUpgradeDialog({super.key, required this.isDarkMode});

  static void show(BuildContext context, {required bool isDarkMode}) {
    showDialog(
      context: context,
      builder: (_) => ProUpgradeDialog(isDarkMode: isDarkMode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProStatusProvider>(
      builder: (context, pro, _) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDarkMode ? GamerColors.darkCard : Colors.white,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                if (pro.isPro) _buildAlreadyPro(context) else _buildBody(context, pro),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [
                  GamerColors.neonPurple.withValues(alpha: 0.25),
                  GamerColors.neonCyan.withValues(alpha: 0.15),
                ]
              : [
                  GamerColors.lightPurple.withValues(alpha: 0.08),
                  GamerColors.lightCyan.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [GamerColors.neonPurple, GamerColors.neonCyan],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isDarkMode
                      ? GamerColors.subtleGlow(GamerColors.neonPurple)
                      : null,
                ),
                child: const Center(
                  child: Icon(Icons.diamond, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Upgrade to Pro',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close,
                    color: isDarkMode ? Colors.white54 : Colors.grey[500]),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock the full power of the finder',
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.white60 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadyPro(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: GamerColors.neonGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle,
                color: GamerColors.greenText(isDarkMode), size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'You are a Pro user!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: GamerColors.greenText(isDarkMode),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All Pro features are unlocked. Thank you for your support!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.white60 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close',
                style: TextStyle(
                  color: GamerColors.greenText(isDarkMode),
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProStatusProvider pro) {
    // Get price from loaded products, or show fallback
    String priceText = '\$4.99';
    if (pro.products.isNotEmpty) {
      priceText = pro.products.first.price;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Feature list
          _featureRow(Icons.search, 'Netherite comprehensive search',
              'Scan entire chunks for ancient debris'),
          _featureRow(Icons.zoom_out_map, 'Unlimited search radius',
              'Search beyond the 50-block free limit'),
          _featureRow(Icons.category, 'All structure types at once',
              'Search all 16 structures simultaneously'),
          _featureRow(Icons.format_list_numbered, 'Unlimited results',
              'Get up to 500 results (vs 50 free)'),
          _featureRow(Icons.auto_awesome, 'Future Pro features',
              'Access all upcoming premium features'),
          const SizedBox(height: 20),

          // Error message
          if (pro.error != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(pro.error!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Buy button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: pro.purchasePending ? null : () => pro.buyPro(),
              style: ElevatedButton.styleFrom(
                backgroundColor: GamerColors.neonPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    GamerColors.neonPurple.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: isDarkMode ? 4 : 2,
              ),
              child: pro.purchasePending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      'Unlock Pro — $priceText',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
            ),
          ),
          const SizedBox(height: 10),

          // Restore purchases
          TextButton(
            onPressed:
                pro.purchasePending ? null : () => pro.restorePurchases(),
            child: Text(
              'Restore Purchase',
              style: TextStyle(
                color: isDarkMode ? Colors.white54 : Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),

          // One-time purchase note
          Text(
            'One-time purchase. No subscription.',
            style: TextStyle(
              fontSize: 11,
              color: isDarkMode ? Colors.white38 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? GamerColors.neonPurple.withValues(alpha: 0.15)
                  : GamerColors.lightPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                size: 16,
                color: isDarkMode
                    ? GamerColors.neonPurple
                    : GamerColors.lightPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDarkMode
                          ? Colors.white
                          : const Color(0xFF1A1A2E),
                    )),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? Colors.white38 : Colors.grey[500],
                    )),
              ],
            ),
          ),
          Icon(Icons.check_circle,
              size: 16,
              color: GamerColors.greenText(isDarkMode)),
        ],
      ),
    );
  }
}
