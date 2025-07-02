import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchCenterCard extends StatelessWidget {
  final TextEditingController xController;
  final TextEditingController yController;
  final TextEditingController zController;
  final TextEditingController radiusController;

  const SearchCenterCard({
    super.key,
    required this.xController,
    required this.yController,
    required this.zController,
    required this.radiusController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFF4CAF50), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              const Color(0xFFF1F8E9),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF795548),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Center(
                    child: Text('📍', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Search Center',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: xController,
                    decoration: InputDecoration(
                      labelText: 'X',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        onPressed: () {
                          final currentText = xController.text;
                          if (currentText.isEmpty) return;
                          if (currentText.startsWith('-')) {
                            xController.text = currentText.substring(1);
                          } else {
                            xController.text = '-$currentText';
                          }
                        },
                        tooltip: 'Toggle +/-',
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                        signed: true, decimal: false),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: yController,
                    decoration: InputDecoration(
                      labelText: 'Y (Height)',
                      hintText: 'e.g. -59 for diamonds',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        onPressed: () {
                          final currentText = yController.text;
                          if (currentText.isEmpty) return;
                          if (currentText.startsWith('-')) {
                            yController.text = currentText.substring(1);
                          } else {
                            yController.text = '-$currentText';
                          }
                        },
                        tooltip: 'Toggle +/-',
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                        signed: true, decimal: false),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final y = int.tryParse(value);
                      if (y == null) {
                        return 'Invalid';
                      }
                      if (y < -64 || y > 320) {
                        return 'Y: -64 to 320';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: zController,
                    decoration: InputDecoration(
                      labelText: 'Z',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        onPressed: () {
                          final currentText = zController.text;
                          if (currentText.isEmpty) return;
                          if (currentText.startsWith('-')) {
                            zController.text = currentText.substring(1);
                          } else {
                            zController.text = '-$currentText';
                          }
                        },
                        tooltip: 'Toggle +/-',
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                        signed: true, decimal: false),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: radiusController,
              decoration: InputDecoration(
                labelText: 'Search Radius (blocks)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF607D8B),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Center(
                    child: Text('🔍', style: TextStyle(fontSize: 12)),
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter search radius';
                }
                final radius = int.tryParse(value);
                if (radius == null || radius <= 0) {
                  return 'Radius must be a positive number';
                }
                if (radius > 2000) {
                  return 'Radius too large (max 2000)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
