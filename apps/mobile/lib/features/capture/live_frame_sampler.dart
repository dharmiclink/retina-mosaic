import 'dart:math' as math;

import 'package:camera/camera.dart';

class FrameSample {
  FrameSample({
    required this.width,
    required this.height,
    required this.values,
  });

  factory FrameSample.fromCameraImage(CameraImage image) {
    final Plane plane = image.planes.first;
    final int stepX = math.max(1, image.width ~/ 72);
    final int stepY = math.max(1, image.height ~/ 72);
    final int bytesPerPixel = plane.bytesPerPixel ?? 1;
    final bool isPackedBgra = image.planes.length == 1 && bytesPerPixel >= 4;

    final List<double> values = <double>[];
    int width = 0;
    int height = 0;

    for (int y = 1; y < image.height - 1; y += stepY) {
      int rowCount = 0;
      for (int x = 1; x < image.width - 1; x += stepX) {
        final int baseIndex = (y * plane.bytesPerRow) + (x * bytesPerPixel);
        if (baseIndex >= plane.bytes.length) {
          continue;
        }

        final double luma;
        if (isPackedBgra && baseIndex + 2 < plane.bytes.length) {
          luma = plane.bytes[baseIndex + 1].toDouble();
        } else {
          luma = plane.bytes[baseIndex].toDouble();
        }

        values.add(luma);
        rowCount += 1;
      }

      if (rowCount > 0) {
        width = rowCount;
        height += 1;
      }
    }

    return FrameSample(width: width, height: height, values: values);
  }

  final int width;
  final int height;
  final List<double> values;

  bool get isEmpty => width == 0 || height == 0 || values.isEmpty;

  double at(int x, int y) => values[(y * width) + x];

  int estimateKeypointCount() {
    if (isEmpty) {
      return 0;
    }

    int keypoints = 0;
    for (int y = 1; y < height - 1; y += 1) {
      for (int x = 1; x < width - 1; x += 1) {
        final double dx = (at(x + 1, y) - at(x - 1, y)).abs();
        final double dy = (at(x, y + 1) - at(x, y - 1)).abs();
        final double gradient = dx + dy;
        if (gradient > 36) {
          keypoints += 1;
        }
      }
    }
    return keypoints;
  }
}
