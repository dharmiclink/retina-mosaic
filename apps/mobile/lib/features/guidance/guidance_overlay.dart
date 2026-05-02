import 'package:flutter/material.dart';
import 'package:nexthria_domain/nexthria_domain.dart';
import 'package:nexthria_ui/nexthria_ui.dart';

class GuidanceOverlay extends StatelessWidget {
  const GuidanceOverlay({
    super.key,
    required this.guidanceVector,
    required this.processingActive,
  });

  final GuidanceVector guidanceVector;
  final bool processingActive;

  IconData get _icon {
    switch (guidanceVector.direction) {
      case GuidanceDirection.left:
        return Icons.keyboard_double_arrow_left_rounded;
      case GuidanceDirection.right:
        return Icons.keyboard_double_arrow_right_rounded;
      case GuidanceDirection.up:
        return Icons.keyboard_double_arrow_up_rounded;
      case GuidanceDirection.down:
        return Icons.keyboard_double_arrow_down_rounded;
      case GuidanceDirection.center:
      case GuidanceDirection.hold:
        return Icons.control_camera_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Center(
          child: Icon(
            _icon,
            size: 132,
            color: processingActive
                ? const Color(0xCC17B7E5)
                : const Color(0x5517B7E5),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: GuidanceBanner(
              instruction: guidanceVector.instruction,
              confidence: guidanceVector.confidence,
            ),
          ),
        ),
      ],
    );
  }
}
