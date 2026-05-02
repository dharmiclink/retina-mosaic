import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StatusMeter extends StatelessWidget {
  const StatusMeter({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double clamped = value.clamp(0, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: NexthriaTheme.textPrimary,
              ),
            ),
            Text(
              '${(clamped * 100).round()}%',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: NexthriaTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
