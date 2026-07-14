import 'package:flutter/material.dart';
import '../config/app_constants.dart';

/// A small, consistent "not medical advice" disclaimer shown wherever a
/// genetic-compatibility result appears. Keeps Helix framed as genetic
/// *education*, not a diagnosis (see backend COMPLIANCE.md §8 / R8).
class GeneticDisclaimer extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const GeneticDisclaimer({super.key, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 13, color: AppConstants.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              AppConstants.geneticDisclaimer,
              style: const TextStyle(
                color: AppConstants.textMuted,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
