import 'dart:math' as math;

import 'package:nexthria_cv/nexthria_cv.dart';

import 'live_frame_sampler.dart';

class FeaturePoint {
  const FeaturePoint({
    required this.x,
    required this.y,
    required this.score,
    required this.descriptor,
  });

  final int x;
  final int y;
  final double score;
  final List<double> descriptor;
}

class FeatureMatch {
  const FeatureMatch({
    required this.anchor,
    required this.current,
    required this.distance,
  });

  final FeaturePoint anchor;
  final FeaturePoint current;
  final double distance;
}

class FeatureAlignment {
  const FeatureAlignment({
    required this.dx,
    required this.dy,
    required this.scale,
    required this.rotationRadians,
    required this.confidence,
    required this.matches,
    required this.anchorKeypoints,
    required this.currentKeypoints,
    required this.transform,
    required this.inlierCount,
    required this.meanReprojectionError,
  });

  final double dx;
  final double dy;
  final double scale;
  final double rotationRadians;
  final double confidence;
  final List<FeatureMatch> matches;
  final int anchorKeypoints;
  final int currentKeypoints;
  final List<double> transform;
  final int inlierCount;
  final double meanReprojectionError;
}

class FeatureMatcher {
  const FeatureMatcher();

  List<FeaturePoint> detect(FrameSample sample, {int maxPoints = 48}) {
    if (sample.isEmpty || sample.width < 7 || sample.height < 7) {
      return const <FeaturePoint>[];
    }

    final List<FeaturePoint> candidates = <FeaturePoint>[];
    for (int y = 3; y < sample.height - 3; y += 1) {
      for (int x = 3; x < sample.width - 3; x += 1) {
        final double gx = (sample.at(x + 1, y) - sample.at(x - 1, y)).abs();
        final double gy = (sample.at(x, y + 1) - sample.at(x, y - 1)).abs();
        final double g1 = (sample.at(x + 1, y + 1) - sample.at(x - 1, y - 1))
            .abs();
        final double g2 = (sample.at(x + 1, y - 1) - sample.at(x - 1, y + 1))
            .abs();
        final double cornerScore = (gx * gy) + (g1 * g2 * 0.5);
        if (cornerScore < 400) {
          continue;
        }

        candidates.add(
          FeaturePoint(
            x: x,
            y: y,
            score: cornerScore,
            descriptor: _descriptor(sample, x, y),
          ),
        );
      }
    }

    candidates.sort(
      (FeaturePoint a, FeaturePoint b) => b.score.compareTo(a.score),
    );
    final List<FeaturePoint> selected = <FeaturePoint>[];
    for (final FeaturePoint point in candidates) {
      final bool tooClose = selected.any(
        (FeaturePoint existing) =>
            (existing.x - point.x).abs() <= 3 &&
            (existing.y - point.y).abs() <= 3,
      );
      if (tooClose) {
        continue;
      }
      selected.add(point);
      if (selected.length >= maxPoints) {
        break;
      }
    }
    return selected;
  }

  FeatureAlignment align(FrameSample anchor, FrameSample current) {
    final NativeTransformEstimate? nativeEstimate = NexthriaCvPlugin.instance
        .estimateTransform(
          anchorValues: anchor.values,
          anchorWidth: anchor.width,
          anchorHeight: anchor.height,
          currentValues: current.values,
          currentWidth: current.width,
          currentHeight: current.height,
        );
    if (nativeEstimate != null &&
        nativeEstimate.transform.length == 9 &&
        nativeEstimate.inlierCount >= 4) {
      return FeatureAlignment(
        dx: nativeEstimate.dx,
        dy: nativeEstimate.dy,
        scale: nativeEstimate.scale,
        rotationRadians: nativeEstimate.rotationRadians,
        confidence: nativeEstimate.confidence,
        matches: const <FeatureMatch>[],
        anchorKeypoints: nativeEstimate.anchorKeypoints,
        currentKeypoints: nativeEstimate.currentKeypoints,
        transform: nativeEstimate.transform,
        inlierCount: nativeEstimate.inlierCount,
        meanReprojectionError: nativeEstimate.meanReprojectionError,
      );
    }

    final List<FeaturePoint> anchorPoints = detect(anchor);
    final List<FeaturePoint> currentPoints = detect(current);
    final List<FeatureMatch> matches = _match(anchorPoints, currentPoints);

    if (matches.length < 2) {
      return _fallbackAlignment(
        matches: matches,
        anchorKeypoints: anchorPoints.length,
        currentKeypoints: currentPoints.length,
      );
    }

    final _SimilarityEstimate? estimate = _estimateSimilarityRansac(matches);
    if (estimate == null) {
      return _fallbackAlignment(
        matches: matches,
        anchorKeypoints: anchorPoints.length,
        currentKeypoints: currentPoints.length,
      );
    }

    final double confidence =
        (((estimate.inliers.length / math.max(matches.length, 4)) * 0.55) +
                ((1 - (estimate.meanError / 6.5)).clamp(0.0, 1.0) * 0.35) +
                ((math.min(anchorPoints.length, currentPoints.length) / 32)
                        .clamp(0.0, 1.0) *
                    0.1))
            .clamp(0.24, 0.99);

    return FeatureAlignment(
      dx: estimate.transform[2],
      dy: estimate.transform[5],
      scale: estimate.scale,
      rotationRadians: estimate.rotationRadians,
      confidence: confidence,
      matches: matches,
      anchorKeypoints: anchorPoints.length,
      currentKeypoints: currentPoints.length,
      transform: estimate.transform,
      inlierCount: estimate.inliers.length,
      meanReprojectionError: estimate.meanError,
    );
  }

  FeatureAlignment _fallbackAlignment({
    required List<FeatureMatch> matches,
    required int anchorKeypoints,
    required int currentKeypoints,
  }) {
    double dx = 0;
    double dy = 0;
    if (matches.isNotEmpty) {
      final double anchorCx =
          matches
              .map((FeatureMatch match) => match.anchor.x.toDouble())
              .reduce((double a, double b) => a + b) /
          matches.length;
      final double anchorCy =
          matches
              .map((FeatureMatch match) => match.anchor.y.toDouble())
              .reduce((double a, double b) => a + b) /
          matches.length;
      final double currentCx =
          matches
              .map((FeatureMatch match) => match.current.x.toDouble())
              .reduce((double a, double b) => a + b) /
          matches.length;
      final double currentCy =
          matches
              .map((FeatureMatch match) => match.current.y.toDouble())
              .reduce((double a, double b) => a + b) /
          matches.length;
      dx = anchorCx - currentCx;
      dy = anchorCy - currentCy;
    }

    return FeatureAlignment(
      dx: dx,
      dy: dy,
      scale: 1,
      rotationRadians: 0,
      confidence: matches.isEmpty ? 0.2 : 0.28,
      matches: matches,
      anchorKeypoints: anchorKeypoints,
      currentKeypoints: currentKeypoints,
      transform: <double>[1, 0, dx, 0, 1, dy, 0, 0, 1],
      inlierCount: matches.isEmpty ? 0 : 1,
      meanReprojectionError: matches.isEmpty ? double.infinity : 8,
    );
  }

  _SimilarityEstimate? _estimateSimilarityRansac(List<FeatureMatch> matches) {
    final int candidateCount = math.min(matches.length, 8);
    _SimilarityEstimate? best;

    for (int i = 0; i < candidateCount; i += 1) {
      for (int j = i + 1; j < candidateCount; j += 1) {
        final _SimilarityEstimate? candidate = _estimateFromPair(
          matches[i],
          matches[j],
          matches,
        );
        if (candidate == null) {
          continue;
        }
        if (_isBetter(candidate, best)) {
          best = candidate;
        }
      }
    }

    if (best == null) {
      return null;
    }

    final _SimilarityEstimate? refined = _refineSimilarity(
      best.inliers,
      matches,
    );
    if (refined != null && _isBetter(refined, best)) {
      best = refined;
    }

    return best;
  }

  _SimilarityEstimate? _estimateFromPair(
    FeatureMatch first,
    FeatureMatch second,
    List<FeatureMatch> allMatches,
  ) {
    final double currentDx = (second.current.x - first.current.x).toDouble();
    final double currentDy = (second.current.y - first.current.y).toDouble();
    final double anchorDx = (second.anchor.x - first.anchor.x).toDouble();
    final double anchorDy = (second.anchor.y - first.anchor.y).toDouble();

    final double currentNorm = math.sqrt(
      (currentDx * currentDx) + (currentDy * currentDy),
    );
    final double anchorNorm = math.sqrt(
      (anchorDx * anchorDx) + (anchorDy * anchorDy),
    );
    if (currentNorm < 2 || anchorNorm < 2) {
      return null;
    }

    final double scale = (anchorNorm / currentNorm).clamp(0.8, 1.25);
    final double rotationRadians =
        (math.atan2(anchorDy, anchorDx) - math.atan2(currentDy, currentDx))
            .clamp(-0.45, 0.45);
    final double cosTheta = math.cos(rotationRadians);
    final double sinTheta = math.sin(rotationRadians);

    final double tx =
        first.anchor.x -
        (scale * ((cosTheta * first.current.x) - (sinTheta * first.current.y)));
    final double ty =
        first.anchor.y -
        (scale * ((sinTheta * first.current.x) + (cosTheta * first.current.y)));

    final List<double> transform = <double>[
      scale * cosTheta,
      -scale * sinTheta,
      tx,
      scale * sinTheta,
      scale * cosTheta,
      ty,
      0,
      0,
      1,
    ];

    return _evaluateTransform(transform, scale, rotationRadians, allMatches);
  }

  _SimilarityEstimate? _refineSimilarity(
    List<FeatureMatch> inliers,
    List<FeatureMatch> allMatches,
  ) {
    if (inliers.length < 2) {
      return null;
    }

    double currentCx = 0;
    double currentCy = 0;
    double anchorCx = 0;
    double anchorCy = 0;
    for (final FeatureMatch match in inliers) {
      currentCx += match.current.x;
      currentCy += match.current.y;
      anchorCx += match.anchor.x;
      anchorCy += match.anchor.y;
    }
    currentCx /= inliers.length;
    currentCy /= inliers.length;
    anchorCx /= inliers.length;
    anchorCy /= inliers.length;

    double cross = 0;
    double dot = 0;
    for (final FeatureMatch match in inliers) {
      final double px = match.current.x - currentCx;
      final double py = match.current.y - currentCy;
      final double qx = match.anchor.x - anchorCx;
      final double qy = match.anchor.y - anchorCy;
      dot += (px * qx) + (py * qy);
      cross += (px * qy) - (py * qx);
    }

    final double rotationRadians = math.atan2(cross, dot).clamp(-0.45, 0.45);
    final double cosTheta = math.cos(rotationRadians);
    final double sinTheta = math.sin(rotationRadians);

    double numerator = 0;
    double denominator = 0;
    for (final FeatureMatch match in inliers) {
      final double px = match.current.x - currentCx;
      final double py = match.current.y - currentCy;
      final double rx = (cosTheta * px) - (sinTheta * py);
      final double ry = (sinTheta * px) + (cosTheta * py);
      final double qx = match.anchor.x - anchorCx;
      final double qy = match.anchor.y - anchorCy;
      numerator += (qx * rx) + (qy * ry);
      denominator += (px * px) + (py * py);
    }

    if (denominator <= 0) {
      return null;
    }

    final double scale = (numerator / denominator).clamp(0.8, 1.25);
    final double tx =
        anchorCx - (scale * ((cosTheta * currentCx) - (sinTheta * currentCy)));
    final double ty =
        anchorCy - (scale * ((sinTheta * currentCx) + (cosTheta * currentCy)));

    final List<double> transform = <double>[
      scale * cosTheta,
      -scale * sinTheta,
      tx,
      scale * sinTheta,
      scale * cosTheta,
      ty,
      0,
      0,
      1,
    ];

    return _evaluateTransform(transform, scale, rotationRadians, allMatches);
  }

  _SimilarityEstimate _evaluateTransform(
    List<double> transform,
    double scale,
    double rotationRadians,
    List<FeatureMatch> matches,
  ) {
    final List<FeatureMatch> inliers = <FeatureMatch>[];
    double inlierErrorSum = 0;

    for (final FeatureMatch match in matches) {
      final _Point projection = _applyTransform(
        transform,
        match.current.x.toDouble(),
        match.current.y.toDouble(),
      );
      final double error = math.sqrt(
        math.pow(projection.x - match.anchor.x, 2).toDouble() +
            math.pow(projection.y - match.anchor.y, 2).toDouble(),
      );
      if (error <= 4.5) {
        inliers.add(match);
        inlierErrorSum += error;
      }
    }

    final double meanError = inliers.isEmpty
        ? double.infinity
        : inlierErrorSum / inliers.length;

    return _SimilarityEstimate(
      transform: transform,
      scale: scale,
      rotationRadians: rotationRadians,
      inliers: inliers,
      meanError: meanError,
    );
  }

  bool _isBetter(_SimilarityEstimate candidate, _SimilarityEstimate? best) {
    if (best == null) {
      return candidate.inliers.length >= 2;
    }
    if (candidate.inliers.length != best.inliers.length) {
      return candidate.inliers.length > best.inliers.length;
    }
    return candidate.meanError < best.meanError;
  }

  List<FeatureMatch> _match(
    List<FeaturePoint> anchor,
    List<FeaturePoint> current,
  ) {
    final List<FeatureMatch> candidates = <FeatureMatch>[];
    for (final FeaturePoint currentPoint in current) {
      FeaturePoint? best;
      FeaturePoint? secondBest;
      double bestDistance = double.infinity;
      double secondDistance = double.infinity;

      for (final FeaturePoint anchorPoint in anchor) {
        final double distance = _descriptorDistance(
          anchorPoint.descriptor,
          currentPoint.descriptor,
        );
        if (distance < bestDistance) {
          secondDistance = bestDistance;
          secondBest = best;
          bestDistance = distance;
          best = anchorPoint;
        } else if (distance < secondDistance) {
          secondDistance = distance;
          secondBest = anchorPoint;
        }
      }

      if (best == null) {
        continue;
      }
      if (secondBest != null && bestDistance / secondDistance > 0.82) {
        continue;
      }
      candidates.add(
        FeatureMatch(
          anchor: best,
          current: currentPoint,
          distance: bestDistance,
        ),
      );
    }

    candidates.sort(
      (FeatureMatch a, FeatureMatch b) => a.distance.compareTo(b.distance),
    );

    final Set<String> usedAnchors = <String>{};
    final List<FeatureMatch> selected = <FeatureMatch>[];
    for (final FeatureMatch match in candidates) {
      final String anchorKey = '${match.anchor.x}:${match.anchor.y}';
      if (usedAnchors.contains(anchorKey)) {
        continue;
      }
      usedAnchors.add(anchorKey);
      selected.add(match);
      if (selected.length >= 16) {
        break;
      }
    }

    return selected;
  }

  List<double> _descriptor(FrameSample sample, int x, int y) {
    final List<double> descriptor = <double>[];
    for (int dy = -2; dy <= 2; dy += 2) {
      for (int dx = -2; dx <= 2; dx += 2) {
        descriptor.add(sample.at(x + dx, y + dy) / 255.0);
      }
    }
    descriptor.add((sample.at(x + 1, y) - sample.at(x - 1, y)) / 255.0);
    descriptor.add((sample.at(x, y + 1) - sample.at(x, y - 1)) / 255.0);
    return descriptor;
  }

  double _descriptorDistance(List<double> a, List<double> b) {
    double sum = 0;
    for (int index = 0; index < a.length; index += 1) {
      final double delta = a[index] - b[index];
      sum += delta * delta;
    }
    return math.sqrt(sum);
  }

  _Point _applyTransform(List<double> transform, double x, double y) {
    return _Point(
      x: (transform[0] * x) + (transform[1] * y) + transform[2],
      y: (transform[3] * x) + (transform[4] * y) + transform[5],
    );
  }
}

class _SimilarityEstimate {
  const _SimilarityEstimate({
    required this.transform,
    required this.scale,
    required this.rotationRadians,
    required this.inliers,
    required this.meanError,
  });

  final List<double> transform;
  final double scale;
  final double rotationRadians;
  final List<FeatureMatch> inliers;
  final double meanError;
}

class _Point {
  const _Point({required this.x, required this.y});

  final double x;
  final double y;
}
