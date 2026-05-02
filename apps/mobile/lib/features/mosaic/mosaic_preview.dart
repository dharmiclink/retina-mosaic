import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nexthria_domain/nexthria_domain.dart';

class MosaicPreview extends StatelessWidget {
  const MosaicPreview({
    super.key,
    required this.mosaicUpdate,
    this.coverageGrid,
    this.mosaicIntensityGrid,
    this.mosaicResolution,
    this.imageAssetPath,
    this.mirrorHorizontally = false,
  });

  final MosaicUpdate mosaicUpdate;
  final List<double>? coverageGrid;
  final List<double>? mosaicIntensityGrid;
  final int? mosaicResolution;
  final String? imageAssetPath;
  final bool mirrorHorizontally;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const ColoredBox(color: Color(0xFF162A3F)),
            if (imageAssetPath != null)
              Transform.flip(
                flipX: mirrorHorizontally,
                child: Image.asset(imageAssetPath!, fit: BoxFit.cover),
              ),
            CustomPaint(
              painter: _MosaicPainter(
                mosaicUpdate,
                coverageGrid: coverageGrid,
                mosaicIntensityGrid: mosaicIntensityGrid,
                mosaicResolution: mosaicResolution,
                hasBackgroundImage: imageAssetPath != null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MosaicPainter extends CustomPainter {
  _MosaicPainter(
    this.update, {
    required this.hasBackgroundImage,
    required this.coverageGrid,
    required this.mosaicIntensityGrid,
    required this.mosaicResolution,
  });

  final MosaicUpdate update;
  final bool hasBackgroundImage;
  final List<double>? coverageGrid;
  final List<double>? mosaicIntensityGrid;
  final int? mosaicResolution;

  @override
  void paint(Canvas canvas, Size size) {
    if (!hasBackgroundImage) {
      final Paint retinaPaint = Paint()
        ..shader = const RadialGradient(
          colors: <Color>[
            Color(0xFFF5B165),
            Color(0xFFCC633A),
            Color(0xFF5E2A22),
          ],
        ).createShader(Offset.zero & size);
      canvas.drawOval(
        Rect.fromLTWH(
          size.width * 0.08,
          size.height * 0.08,
          size.width * 0.84,
          size.height * 0.84,
        ),
        retinaPaint,
      );
    }

    final Paint vignette = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.transparent,
          const Color(0xFF0C1117).withValues(alpha: 0.16),
          const Color(0xFF06090E).withValues(alpha: 0.72),
        ],
        stops: const <double>[0.5, 0.78, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);

    if (mosaicIntensityGrid != null &&
        mosaicIntensityGrid!.isNotEmpty &&
        mosaicResolution != null) {
      final double cellWidth = size.width / mosaicResolution!;
      final double cellHeight = size.height / mosaicResolution!;

      for (int y = 0; y < mosaicResolution!; y += 1) {
        for (int x = 0; x < mosaicResolution!; x += 1) {
          final double intensity =
              mosaicIntensityGrid![(y * mosaicResolution!) + x];
          if (intensity <= 0) {
            continue;
          }

          final Rect cellRect = Rect.fromLTWH(
            x * cellWidth,
            y * cellHeight,
            cellWidth + 0.2,
            cellHeight + 0.2,
          );
          final Paint pixelPaint = Paint()
            ..color = Color.lerp(
              const Color(0xFF170A08),
              const Color(0xFFFFC78A),
              intensity.clamp(0.0, 1.0),
            )!;
          canvas.drawRect(cellRect, pixelPaint);
        }
      }
    }

    if (coverageGrid == null || coverageGrid!.isEmpty) {
      final Paint scrapePaint = Paint()
        ..color = const Color(0xFFF7F2E7).withValues(alpha: 0.82)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 30;

      final List<Offset> strokes = <Offset>[
        Offset(size.width * 0.23, size.height * 0.22),
        Offset(size.width * 0.72, size.height * 0.28),
        Offset(size.width * 0.65, size.height * 0.72),
        Offset(size.width * 0.32, size.height * 0.74),
      ];

      for (int index = 0; index < strokes.length; index += 1) {
        final Offset start = strokes[index];
        final Offset end = Offset(
          start.dx + 42 * math.cos(index * 1.2),
          start.dy + 36 * math.sin(index * 1.2),
        );
        canvas.drawLine(start, end, scrapePaint);
      }
    } else {
      final int gridSize = math.sqrt(coverageGrid!.length).round();
      final double cellWidth = size.width / gridSize;
      final double cellHeight = size.height / gridSize;

      for (int y = 0; y < gridSize; y += 1) {
        for (int x = 0; x < gridSize; x += 1) {
          final double coverage = coverageGrid![(y * gridSize) + x];
          final Rect cellRect = Rect.fromLTWH(
            x * cellWidth,
            y * cellHeight,
            cellWidth,
            cellHeight,
          );
          final bool unresolved = coverage < 0.16;
          final Paint cellPaint = Paint()
            ..color = unresolved
                ? const Color(0xC4090C11)
                : Color.lerp(
                    const Color(0x1800E1FF),
                    const Color(0x66FFF1D0),
                    coverage.clamp(0.0, 1.0),
                  )!;
          canvas.drawRect(
            unresolved ? cellRect : cellRect.deflate(0.8),
            cellPaint,
          );
        }
      }
    }

    final Offset holeCenter = Offset(size.width * 0.55, size.height * 0.52);
    final double holeRadius =
        34 + (1 - update.confidenceSummary.meanConfidence) * 18;
    final Paint holePaint = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[Color(0xFF2A313A), Color(0xFF090C11)],
      ).createShader(Rect.fromCircle(center: holeCenter, radius: holeRadius));
    canvas.drawCircle(holeCenter, holeRadius, holePaint);

    final Paint framePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
        const Radius.circular(22),
      ),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MosaicPainter oldDelegate) {
    return oldDelegate.update.coveragePercent != update.coveragePercent ||
        oldDelegate.coverageGrid != coverageGrid ||
        oldDelegate.mosaicIntensityGrid != mosaicIntensityGrid;
  }
}
