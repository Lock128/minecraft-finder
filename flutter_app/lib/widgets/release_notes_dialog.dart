import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class ReleaseNotesDialog extends StatelessWidget {
  final bool isDarkMode;

  const ReleaseNotesDialog({super.key, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF4CAF50),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.new_releases, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.dialogReleaseNotesHeader,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: Container(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(l10n.dialogRecentSeedsSection),
                      const SizedBox(height: 12),
                      _buildFeatureItem(l10n.dialogQuickSeedAccessTitle, l10n.dialogQuickSeedAccessBody),
                      const SizedBox(height: 12),
                      _buildFeatureItem(l10n.dialogSmartSeedTitle, l10n.dialogSmartSeedBody),
                      const SizedBox(height: 12),
                      _buildFeatureItem(l10n.dialogEnhancedUxTitle, l10n.dialogEnhancedUxBody),
                      const SizedBox(height: 20),
                      _buildSectionHeader(l10n.dialogSearchMemorySection),
                      const SizedBox(height: 12),
                      _buildFeatureItem(l10n.dialogAutoSaveTitle, l10n.dialogAutoSaveBody),
                      const SizedBox(height: 12),
                      _buildFeatureItem(l10n.dialogSeamlessTitle, l10n.dialogSeamlessBody),
                      const SizedBox(height: 20),
                      _buildSectionHeader(l10n.dialogEnhancedUxSection),
                      const SizedBox(height: 12),
                      _buildFeatureList([
                        l10n.dialogUxBullet1,
                        l10n.dialogUxBullet2,
                        l10n.dialogUxBullet3,
                        l10n.dialogUxBullet4,
                        l10n.dialogUxBullet5,
                        l10n.dialogUxBullet6,
                      ]),
                      const SizedBox(height: 20),
                      _buildSectionHeader(l10n.dialogTechSection),
                      const SizedBox(height: 12),
                      _buildFeatureList([
                        l10n.dialogTechBullet1,
                        l10n.dialogTechBullet2,
                        l10n.dialogTechBullet3,
                        l10n.dialogTechBullet4,
                        l10n.dialogTechBullet5,
                        l10n.dialogTechBullet6,
                      ]),
                      const SizedBox(height: 20),
                      _buildSectionHeader(l10n.dialogPreviousSection),
                      const SizedBox(height: 12),
                      _buildFeatureItem(l10n.dialogV1036Title, l10n.dialogV1036Body),
                      const SizedBox(height: 12),
                      _buildFeatureItem(l10n.dialogV1027Title, l10n.dialogV1027Body),
                      const SizedBox(height: 12),
                      _buildFeatureItem(l10n.dialogV1022Title, l10n.dialogV1022Body),
                      const SizedBox(height: 20),
                      _buildSectionHeader(l10n.dialogPlayersSection),
                      const SizedBox(height: 12),
                      _buildFeatureList([
                        l10n.dialogPlayerBullet1,
                        l10n.dialogPlayerBullet2,
                        l10n.dialogPlayerBullet3,
                        l10n.dialogPlayerBullet4,
                        l10n.dialogPlayerBullet5,
                        l10n.dialogPlayerBullet6,
                      ]),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2E2E2E) : Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.dialogFooter,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.dialogGotIt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E3A1E) : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDarkMode ? const Color(0xFF4CAF50) : Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(List<String> features) {
    return Column(
      children: features
          .map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: TextStyle(
                            color: isDarkMode
                                ? const Color(0xFF66BB6A)
                                : const Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  static void show(BuildContext context, {bool isDarkMode = false}) {
    showDialog(
      context: context,
      builder: (context) => ReleaseNotesDialog(isDarkMode: isDarkMode),
    );
  }
}
