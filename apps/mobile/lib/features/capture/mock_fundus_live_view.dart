import 'package:flutter/material.dart';

class MockFundusLiveView extends StatelessWidget {
  const MockFundusLiveView({
    super.key,
    required this.assetPath,
    required this.alignment,
    required this.zoom,
    required this.mirrorHorizontally,
    required this.processingActive,
  });

  final String assetPath;
  final Alignment alignment;
  final double zoom;
  final bool mirrorHorizontally;
  final bool processingActive;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ColoredBox(color: Color(0xFF04070B)),
          Positioned.fill(
            child: Transform.scale(
              scaleX: mirrorHorizontally ? -zoom : zoom,
              scaleY: zoom,
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                alignment: alignment,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: <Color>[
                    Colors.transparent,
                    const Color(0xFF04070B).withValues(alpha: 0.28),
                    const Color(0xFF04070B).withValues(alpha: 0.88),
                  ],
                  stops: const <double>[0.45, 0.78, 1.0],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 224,
              height: 224,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: processingActive
                      ? const Color(0xFF17B7E5)
                      : Colors.white24,
                  width: 3,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF17B7E5).withValues(alpha: 0.22),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF07101A).withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Text(
                  processingActive
                      ? 'Mock scan is painting over a CC0 fundus photograph'
                      : 'Loaded with a real fundus photo for offline demo capture',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
