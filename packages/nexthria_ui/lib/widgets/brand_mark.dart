import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 52, this.showGlow = true});

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final Widget core = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: NexthriaTheme.accentGradient,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: showGlow
            ? <BoxShadow>[
                BoxShadow(
                  color: NexthriaTheme.cyan.withValues(alpha: 0.28),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Container(
          width: size * 0.48,
          height: size * 0.48,
          decoration: BoxDecoration(
            color: const Color(0xCCFFFFFF),
            borderRadius: BorderRadius.circular(size * 0.16),
          ),
          child: Icon(
            Icons.remove_red_eye_outlined,
            color: NexthriaTheme.bg,
            size: size * 0.24,
          ),
        ),
      ),
    );

    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Center(child: core),
    );
  }
}
