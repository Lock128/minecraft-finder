import 'package:flutter/material.dart';

class SearchButtons extends StatelessWidget {
  final bool isLoading;
  final bool findAllNetherite;
  final Function(bool) onFindOres;

  const SearchButtons({
    super.key,
    required this.isLoading,
    required this.findAllNetherite,
    required this.onFindOres,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : () => onFindOres(false),
                  icon: isLoading && !findAllNetherite
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B4513),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Center(
                            child: Text('⛏️', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                  label: Text(
                    isLoading && !findAllNetherite ? 'Searching...' : 'Find',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purple[800]!],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : () => onFindOres(true),
                  icon: isLoading && findAllNetherite
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C1810),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Center(
                            child: Text('🔥', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                  label: Text(
                    isLoading && findAllNetherite
                        ? 'Searching All Netherite...'
                        : 'Find ALL Netherite',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoContainer(),
      ],
    );
  }

  Widget _buildInfoContainer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.deepPurple, size: 16),
              SizedBox(width: 8),
              Text(
                'Comprehensive Netherite Search',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '• Searches entire world (4000x4000 blocks)\n• May take 30-60 seconds\n• Shows up to 200 netherite locations\n• Ignores other ore selections',
            style: TextStyle(
              color: Colors.deepPurple.withOpacity(0.8),
              height: 1.3,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
