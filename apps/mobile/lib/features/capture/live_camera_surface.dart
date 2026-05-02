import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class LiveCameraSurface extends StatelessWidget {
  const LiveCameraSurface({
    super.key,
    required this.controller,
    required this.processingActive,
  });

  final CameraController controller;
  final bool processingActive;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ColoredBox(
            color: const Color(0xFF04070B),
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize?.height ?? 1,
                height: controller.value.previewSize?.width ?? 1,
                child: CameraPreview(controller),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: <Color>[
                    Colors.transparent,
                    const Color(0xFF04070B).withValues(alpha: 0.22),
                    const Color(0xFF04070B).withValues(alpha: 0.86),
                  ],
                  stops: const <double>[0.44, 0.76, 1.0],
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
                    color: const Color(0xFF17B7E5).withValues(alpha: 0.18),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 18,
            left: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF07101A).withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'Live retinal stream',
                  style: TextStyle(
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
