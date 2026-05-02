import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GuidanceBanner extends StatelessWidget {
  const GuidanceBanner({
    super.key,
    required this.instruction,
    required this.confidence,
  });

  final String instruction;
  final double confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: NexthriaTheme.card.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: NexthriaTheme.cyan.withValues(alpha: 0.42)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: NexthriaTheme.cyan.withValues(alpha: 0.16),
            blurRadius: 22,
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.assistant_navigation, color: NexthriaTheme.cyan),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(
                color: NexthriaTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(confidence * 100).round()}%',
            style: const TextStyle(
              color: NexthriaTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
