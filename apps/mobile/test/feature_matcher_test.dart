import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/capture/feature_matcher.dart';
import 'package:mobile/features/capture/live_frame_sampler.dart';

void main() {
  test(
    'feature matcher recovers similarity transform from textured sample',
    () {
      final FrameSample anchor = _buildSyntheticFundusSample(52, 52);
      final List<double> expectedTransform = _similarityTransform(
        scale: 1.06,
        rotationRadians: 0.08,
        tx: 3.2,
        ty: -2.4,
      );
      final FrameSample current = _warpSample(
        source: anchor,
        currentToSourceTransform: expectedTransform,
        width: 52,
        height: 52,
      );

      final FeatureAlignment alignment = const FeatureMatcher().align(
        anchor,
        current,
      );

      expect(alignment.inlierCount, greaterThanOrEqualTo(4));
      expect(alignment.confidence, greaterThan(0.45));
      expect(alignment.meanReprojectionError, lessThan(3.8));

      final List<({double x, double y})> probePoints = <({double x, double y})>[
        (x: 12, y: 14),
        (x: 26, y: 19),
        (x: 34, y: 32),
      ];

      for (final ({double x, double y}) probe in probePoints) {
        final ({double x, double y}) expected = _applyTransform(
          expectedTransform,
          probe.x,
          probe.y,
        );
        final ({double x, double y}) actual = _applyTransform(
          alignment.transform,
          probe.x,
          probe.y,
        );
        final double error = math.sqrt(
          math.pow(actual.x - expected.x, 2).toDouble() +
              math.pow(actual.y - expected.y, 2).toDouble(),
        );
        expect(error, lessThan(2.6));
      }
    },
  );

  test(
    'feature matcher recovers projective transform from textured sample',
    () {
      final FrameSample anchor = _buildSyntheticFundusSample(56, 56);
      final List<double> expectedTransform = <double>[
        1.03,
        -0.05,
        3.4,
        0.07,
        1.01,
        -2.8,
        0.0011,
        -0.0008,
        1,
      ];
      final FrameSample current = _warpSample(
        source: anchor,
        currentToSourceTransform: expectedTransform,
        width: 56,
        height: 56,
      );

      final FeatureAlignment alignment = const FeatureMatcher().align(
        anchor,
        current,
      );

      expect(alignment.inlierCount, greaterThanOrEqualTo(4));
      expect(alignment.confidence, greaterThan(0.4));
      expect(alignment.meanReprojectionError, lessThan(4.1));

      final List<({double x, double y})> probePoints = <({double x, double y})>[
        (x: 14, y: 12),
        (x: 28, y: 24),
        (x: 39, y: 34),
      ];

      for (final ({double x, double y}) probe in probePoints) {
        final ({double x, double y}) expected = _applyTransform(
          expectedTransform,
          probe.x,
          probe.y,
        );
        final ({double x, double y}) actual = _applyTransform(
          alignment.transform,
          probe.x,
          probe.y,
        );
        final double error = math.sqrt(
          math.pow(actual.x - expected.x, 2).toDouble() +
              math.pow(actual.y - expected.y, 2).toDouble(),
        );
        expect(error, lessThan(3.3));
      }
    },
  );
}

FrameSample _buildSyntheticFundusSample(int width, int height) {
  final List<double> values = <double>[];
  const List<({double x, double y, double amplitude, double spread})> blobs =
      <({double x, double y, double amplitude, double spread})>[
        (x: 13, y: 14, amplitude: 82, spread: 22),
        (x: 37, y: 16, amplitude: 68, spread: 18),
        (x: 28, y: 30, amplitude: 74, spread: 20),
        (x: 17, y: 38, amplitude: 56, spread: 16),
      ];

  for (int y = 0; y < height; y += 1) {
    for (int x = 0; x < width; x += 1) {
      double value =
          72 +
          (18 * math.sin(x / 5.2)) +
          (16 * math.cos(y / 6.1)) +
          (10 * math.sin((x + y) / 4.4)) +
          (0.9 * x) -
          (0.35 * y);

      for (final ({double x, double y, double amplitude, double spread}) blob
          in blobs) {
        final double dx = x - blob.x;
        final double dy = y - blob.y;
        value +=
            blob.amplitude * math.exp(-((dx * dx) + (dy * dy)) / blob.spread);
      }

      value -=
          28 *
          math.exp(
            -_distanceToLine(x.toDouble(), y.toDouble(), 6, 12, 44, 34) / 4.2,
          );
      value -=
          24 *
          math.exp(
            -_distanceToLine(x.toDouble(), y.toDouble(), 12, 42, 42, 10) / 5.0,
          );
      value -=
          18 *
          math.exp(
            -_distanceToLine(x.toDouble(), y.toDouble(), 8, 26, 36, 28) / 3.4,
          );

      values.add(value.clamp(0, 255).toDouble());
    }
  }

  return FrameSample(width: width, height: height, values: values);
}

FrameSample _warpSample({
  required FrameSample source,
  required List<double> currentToSourceTransform,
  required int width,
  required int height,
}) {
  final List<double> values = List<double>.filled(width * height, 0);
  for (int y = 0; y < height; y += 1) {
    for (int x = 0; x < width; x += 1) {
      final ({double x, double y}) sourcePoint = _applyTransform(
        currentToSourceTransform,
        x.toDouble(),
        y.toDouble(),
      );
      values[(y * width) + x] = _sampleBilinear(
        source,
        sourcePoint.x,
        sourcePoint.y,
      );
    }
  }
  return FrameSample(width: width, height: height, values: values);
}

List<double> _similarityTransform({
  required double scale,
  required double rotationRadians,
  required double tx,
  required double ty,
}) {
  final double c = math.cos(rotationRadians);
  final double s = math.sin(rotationRadians);
  return <double>[scale * c, -scale * s, tx, scale * s, scale * c, ty, 0, 0, 1];
}

({double x, double y}) _applyTransform(
  List<double> transform,
  double x,
  double y,
) {
  final double w = (transform[6] * x) + (transform[7] * y) + transform[8];
  if (w.abs() < 1e-6) {
    return (x: transform[2], y: transform[5]);
  }
  return (
    x: ((transform[0] * x) + (transform[1] * y) + transform[2]) / w,
    y: ((transform[3] * x) + (transform[4] * y) + transform[5]) / w,
  );
}

double _sampleBilinear(FrameSample sample, double x, double y) {
  if (x < 0 || y < 0 || x >= sample.width - 1 || y >= sample.height - 1) {
    return 0;
  }

  final int x0 = x.floor();
  final int y0 = y.floor();
  final int x1 = x0 + 1;
  final int y1 = y0 + 1;
  final double fx = x - x0;
  final double fy = y - y0;

  final double top = (sample.at(x0, y0) * (1 - fx)) + (sample.at(x1, y0) * fx);
  final double bottom =
      (sample.at(x0, y1) * (1 - fx)) + (sample.at(x1, y1) * fx);
  return (top * (1 - fy)) + (bottom * fy);
}

double _distanceToLine(
  double x,
  double y,
  double x1,
  double y1,
  double x2,
  double y2,
) {
  final double dx = x2 - x1;
  final double dy = y2 - y1;
  final double numerator = ((dy * x) - (dx * y) + (x2 * y1) - (y2 * x1)).abs();
  final double denominator = math.sqrt((dx * dx) + (dy * dy));
  if (denominator == 0) {
    return 0;
  }
  return numerator / denominator;
}
