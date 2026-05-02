import 'dart:math' as math;
import 'dart:ui';

import 'package:nexthria_cv/nexthria_cv.dart';
import 'package:nexthria_domain/nexthria_domain.dart';

import 'feature_matcher.dart';
import 'gold_frame_bucket.dart';
import 'live_frame_sampler.dart';

class LiveMosaicSolution {
  const LiveMosaicSolution({
    required this.transform,
    required this.coveragePercent,
    required this.confidenceSummary,
    required this.coverageGrid,
    required this.mosaicIntensityGrid,
    required this.mosaicResolution,
    required this.canvasOffset,
    required this.alignmentConfidence,
    required this.matchCount,
    required this.anchorKeypoints,
    required this.currentKeypoints,
    required this.suggestedSweepDirection,
  });

  final List<double> transform;
  final double coveragePercent;
  final ConfidenceSummary confidenceSummary;
  final List<double> coverageGrid;
  final List<double> mosaicIntensityGrid;
  final int mosaicResolution;
  final Offset canvasOffset;
  final double alignmentConfidence;
  final int matchCount;
  final int anchorKeypoints;
  final int currentKeypoints;
  final GuidanceDirection suggestedSweepDirection;
}

class LiveMosaicEngine {
  LiveMosaicEngine({this.gridSize = 28, this.mosaicResolution = 112})
    : _coverageGrid = List<double>.filled(gridSize * gridSize, 0),
      _mosaicIntensityGrid = List<double>.filled(
        mosaicResolution * mosaicResolution,
        0,
      ),
      _mosaicWeightGrid = List<double>.filled(
        mosaicResolution * mosaicResolution,
        0,
      ),
      _matcher = const FeatureMatcher();

  final int gridSize;
  final int mosaicResolution;
  final FeatureMatcher _matcher;
  final List<double> _coverageGrid;
  final List<double> _mosaicIntensityGrid;
  final List<double> _mosaicWeightGrid;
  List<double> _currentTransform = <double>[1, 0, 56, 0, 1, 56, 0, 0, 1];
  Offset _currentOffset = const Offset(14, 14);

  void reset() {
    for (int index = 0; index < _coverageGrid.length; index += 1) {
      _coverageGrid[index] = 0;
    }
    for (int index = 0; index < _mosaicIntensityGrid.length; index += 1) {
      _mosaicIntensityGrid[index] = 0;
      _mosaicWeightGrid[index] = 0;
    }
    _currentOffset = Offset(gridSize / 2, gridSize / 2);
    final double center = mosaicResolution / 2;
    _currentTransform = <double>[1, 0, center, 0, 1, center, 0, 0, 1];
  }

  LiveMosaicSolution snapshot() {
    final double mean =
        _coverageGrid.reduce((double a, double b) => a + b) /
        _coverageGrid.length;
    final double min = _coverageGrid.reduce(math.min);
    final double max = _coverageGrid.reduce(math.max);
    return LiveMosaicSolution(
      transform: List<double>.from(_currentTransform),
      coveragePercent: _coveragePercent(),
      confidenceSummary: ConfidenceSummary(
        meanConfidence: mean,
        minConfidence: min,
        maxConfidence: max,
      ),
      coverageGrid: List<double>.from(_coverageGrid),
      mosaicIntensityGrid: List<double>.from(_mosaicIntensityGrid),
      mosaicResolution: mosaicResolution,
      canvasOffset: _currentOffset,
      alignmentConfidence: max,
      matchCount: 0,
      anchorKeypoints: 0,
      currentKeypoints: 0,
      suggestedSweepDirection: _suggestedSweepDirection(),
    );
  }

  LiveMosaicSolution ingest({
    required FrameSample sample,
    required UtilityScore utilityScore,
    required RetainedGoldFrame? anchor,
  }) {
    double alignmentConfidence = 0.64;
    int matchCount = 0;
    int anchorKeypoints = 0;
    int currentKeypoints = 0;
    List<double> currentTransform;

    if (anchor == null) {
      currentTransform = _centeredCanvasTransform(sample);
      alignmentConfidence = 0.72;
      currentKeypoints = sample.estimateKeypointCount();
    } else {
      final FeatureAlignment estimate = _matcher.align(anchor.sample, sample);
      alignmentConfidence = estimate.confidence;
      matchCount = estimate.inlierCount;
      anchorKeypoints = estimate.anchorKeypoints;
      currentKeypoints = estimate.currentKeypoints;
      currentTransform = _multiply(anchor.canvasTransform, estimate.transform);
      currentTransform = _clampTransformToCanvas(currentTransform, sample);
    }

    _currentTransform = currentTransform;
    _currentOffset = _transformCenterToGridOffset(currentTransform, sample);
    final NativeMosaicAccumulateResult? nativeResult = NexthriaCvPlugin.instance
        .accumulateMosaic(
          sampleValues: sample.values,
          sampleWidth: sample.width,
          sampleHeight: sample.height,
          transformValues: currentTransform,
          coverageValues: _coverageGrid,
          intensityValues: _mosaicIntensityGrid,
          weightValues: _mosaicWeightGrid,
          utilityWeight: utilityScore.weightedTotal,
          gridSize: gridSize,
          mosaicResolution: mosaicResolution,
        );
    late final double mean;
    late final double min;
    late final double max;
    GuidanceDirection suggestedSweepDirection;

    if (_applyNativeCanvasResult(nativeResult)) {
      mean = nativeResult!.meanConfidence;
      min = nativeResult.minConfidence;
      max = nativeResult.maxConfidence;
      suggestedSweepDirection = nativeResult.suggestedSweepDirection;
      if (nativeResult.transform.length == 9) {
        _currentTransform = nativeResult.transform;
      }
      _currentOffset = Offset(
        nativeResult.canvasOffsetX,
        nativeResult.canvasOffsetY,
      );
    } else {
      _paintFootprint(
        transform: currentTransform,
        sample: sample,
        utilityWeight: utilityScore.weightedTotal,
      );
      _blendSampleOntoCanvas(
        sample: sample,
        transform: currentTransform,
        utilityWeight: utilityScore.weightedTotal,
      );
      mean =
          _coverageGrid.reduce((double a, double b) => a + b) /
          _coverageGrid.length;
      min = _coverageGrid.reduce(math.min);
      max = _coverageGrid.reduce(math.max);
      suggestedSweepDirection = _suggestedSweepDirection();
    }

    return LiveMosaicSolution(
      transform: List<double>.from(_currentTransform),
      coveragePercent: _coveragePercent(),
      confidenceSummary: ConfidenceSummary(
        meanConfidence: mean,
        minConfidence: min,
        maxConfidence: max,
      ),
      coverageGrid: List<double>.from(_coverageGrid),
      mosaicIntensityGrid: List<double>.from(_mosaicIntensityGrid),
      mosaicResolution: mosaicResolution,
      canvasOffset: _currentOffset,
      alignmentConfidence: alignmentConfidence,
      matchCount: matchCount,
      anchorKeypoints: anchorKeypoints,
      currentKeypoints: currentKeypoints,
      suggestedSweepDirection: suggestedSweepDirection,
    );
  }

  bool _applyNativeCanvasResult(NativeMosaicAccumulateResult? result) {
    if (result == null ||
        result.coverageGrid.length != _coverageGrid.length ||
        result.mosaicIntensityGrid.length != _mosaicIntensityGrid.length ||
        result.mosaicWeightGrid.length != _mosaicWeightGrid.length) {
      return false;
    }

    for (int index = 0; index < _coverageGrid.length; index += 1) {
      _coverageGrid[index] = result.coverageGrid[index];
    }
    for (int index = 0; index < _mosaicIntensityGrid.length; index += 1) {
      _mosaicIntensityGrid[index] = result.mosaicIntensityGrid[index];
      _mosaicWeightGrid[index] = result.mosaicWeightGrid[index];
    }
    return true;
  }

  List<double> _centeredCanvasTransform(FrameSample sample) {
    return <double>[
      1,
      0,
      (mosaicResolution / 2) - (sample.width / 2),
      0,
      1,
      (mosaicResolution / 2) - (sample.height / 2),
      0,
      0,
      1,
    ];
  }

  List<double> _clampTransformToCanvas(
    List<double> transform,
    FrameSample sample,
  ) {
    final Offset center = _applyTransform(
      transform,
      sample.width / 2,
      sample.height / 2,
    );
    final double margin = 10;
    double dx = 0;
    double dy = 0;

    if (center.dx < margin) {
      dx = margin - center.dx;
    } else if (center.dx > mosaicResolution - margin) {
      dx = (mosaicResolution - margin) - center.dx;
    }

    if (center.dy < margin) {
      dy = margin - center.dy;
    } else if (center.dy > mosaicResolution - margin) {
      dy = (mosaicResolution - margin) - center.dy;
    }

    if (dx == 0 && dy == 0) {
      return transform;
    }

    return <double>[
      transform[0],
      transform[1],
      transform[2] + dx,
      transform[3],
      transform[4],
      transform[5] + dy,
      transform[6],
      transform[7],
      transform[8],
    ];
  }

  Offset _transformCenterToGridOffset(
    List<double> transform,
    FrameSample sample,
  ) {
    final Offset center = _applyTransform(
      transform,
      sample.width / 2,
      sample.height / 2,
    );
    final double pixelsPerGridUnit = mosaicResolution / gridSize;
    return Offset(
      (center.dx / pixelsPerGridUnit).clamp(0.0, gridSize.toDouble() - 1),
      (center.dy / pixelsPerGridUnit).clamp(0.0, gridSize.toDouble() - 1),
    );
  }

  void _paintFootprint({
    required List<double> transform,
    required FrameSample sample,
    required double utilityWeight,
  }) {
    final List<Offset> corners = <Offset>[
      _applyTransform(transform, 0, 0),
      _applyTransform(transform, sample.width.toDouble(), 0),
      _applyTransform(
        transform,
        sample.width.toDouble(),
        sample.height.toDouble(),
      ),
      _applyTransform(transform, 0, sample.height.toDouble()),
    ];

    double minX = corners.first.dx;
    double maxX = corners.first.dx;
    double minY = corners.first.dy;
    double maxY = corners.first.dy;
    for (final Offset corner in corners.skip(1)) {
      minX = math.min(minX, corner.dx);
      maxX = math.max(maxX, corner.dx);
      minY = math.min(minY, corner.dy);
      maxY = math.max(maxY, corner.dy);
    }

    final double pixelsPerGridUnit = mosaicResolution / gridSize;
    final Offset gridCenter = _transformCenterToGridOffset(transform, sample);
    final double radiusX = math.max(
      2.2,
      ((maxX - minX) / pixelsPerGridUnit) / 2,
    );
    final double radiusY = math.max(
      2.2,
      ((maxY - minY) / pixelsPerGridUnit) / 2,
    );

    for (int y = 0; y < gridSize; y += 1) {
      for (int x = 0; x < gridSize; x += 1) {
        final double dx = (x - gridCenter.dx) / radiusX;
        final double dy = (y - gridCenter.dy) / radiusY;
        final double distance = (dx * dx) + (dy * dy);
        if (distance > 1) {
          continue;
        }

        final double gain = (1 - distance) * utilityWeight;
        final int index = (y * gridSize) + x;
        _coverageGrid[index] = (_coverageGrid[index] + gain).clamp(0.0, 1.0);
      }
    }
  }

  void _blendSampleOntoCanvas({
    required FrameSample sample,
    required List<double> transform,
    required double utilityWeight,
  }) {
    if (sample.isEmpty) {
      return;
    }

    final double sampleCenterX = sample.width / 2;
    final double sampleCenterY = sample.height / 2;
    final double maxDistance = math.sqrt(
      (sampleCenterX * sampleCenterX) + (sampleCenterY * sampleCenterY),
    );

    for (int sy = 0; sy < sample.height; sy += 1) {
      for (int sx = 0; sx < sample.width; sx += 1) {
        final double dx = sx - sampleCenterX;
        final double dy = sy - sampleCenterY;
        final double radialWeight =
            1 - (math.sqrt((dx * dx) + (dy * dy)) / maxDistance);
        final double weight = (radialWeight.clamp(0.0, 1.0) * utilityWeight)
            .clamp(0.0, 1.0);
        if (weight <= 0.02) {
          continue;
        }

        final Offset canvasPoint = _applyTransform(
          transform,
          sx.toDouble(),
          sy.toDouble(),
        );
        _splatOntoCanvas(
          x: canvasPoint.dx,
          y: canvasPoint.dy,
          intensity: sample.at(sx, sy) / 255.0,
          weight: weight,
        );
      }
    }
  }

  void _splatOntoCanvas({
    required double x,
    required double y,
    required double intensity,
    required double weight,
  }) {
    final int x0 = x.floor();
    final int y0 = y.floor();
    final double fx = x - x0;
    final double fy = y - y0;

    _accumulatePixel(x0, y0, intensity, weight * (1 - fx) * (1 - fy));
    _accumulatePixel(x0 + 1, y0, intensity, weight * fx * (1 - fy));
    _accumulatePixel(x0, y0 + 1, intensity, weight * (1 - fx) * fy);
    _accumulatePixel(x0 + 1, y0 + 1, intensity, weight * fx * fy);
  }

  void _accumulatePixel(int x, int y, double intensity, double weight) {
    if (weight <= 0 ||
        x < 0 ||
        y < 0 ||
        x >= mosaicResolution ||
        y >= mosaicResolution) {
      return;
    }

    final int index = (y * mosaicResolution) + x;
    final double existingWeight = _mosaicWeightGrid[index];
    final double totalWeight = existingWeight + weight;
    _mosaicIntensityGrid[index] =
        ((_mosaicIntensityGrid[index] * existingWeight) +
            (intensity * weight)) /
        totalWeight;
    _mosaicWeightGrid[index] = totalWeight.clamp(0.0, 4.0);
  }

  double _coveragePercent() {
    final int painted = _coverageGrid
        .where((double value) => value >= 0.16)
        .length;
    return ((painted / _coverageGrid.length) * 100).clamp(0.0, 95.0);
  }

  GuidanceDirection _suggestedSweepDirection() {
    double leftSum = 0;
    double rightSum = 0;
    double topSum = 0;
    double bottomSum = 0;

    for (int y = 0; y < gridSize; y += 1) {
      for (int x = 0; x < gridSize; x += 1) {
        final double gap = 1 - _coverageGrid[(y * gridSize) + x];
        if (x < gridSize / 2) {
          leftSum += gap;
        } else {
          rightSum += gap;
        }
        if (y < gridSize / 2) {
          topSum += gap;
        } else {
          bottomSum += gap;
        }
      }
    }

    final Map<GuidanceDirection, double> totals = <GuidanceDirection, double>{
      GuidanceDirection.left: leftSum,
      GuidanceDirection.right: rightSum,
      GuidanceDirection.up: topSum,
      GuidanceDirection.down: bottomSum,
    };

    return totals.entries.reduce((
      MapEntry<GuidanceDirection, double> a,
      MapEntry<GuidanceDirection, double> b,
    ) {
      return a.value >= b.value ? a : b;
    }).key;
  }

  List<double> _multiply(List<double> a, List<double> b) {
    return <double>[
      (a[0] * b[0]) + (a[1] * b[3]) + (a[2] * b[6]),
      (a[0] * b[1]) + (a[1] * b[4]) + (a[2] * b[7]),
      (a[0] * b[2]) + (a[1] * b[5]) + (a[2] * b[8]),
      (a[3] * b[0]) + (a[4] * b[3]) + (a[5] * b[6]),
      (a[3] * b[1]) + (a[4] * b[4]) + (a[5] * b[7]),
      (a[3] * b[2]) + (a[4] * b[5]) + (a[5] * b[8]),
      (a[6] * b[0]) + (a[7] * b[3]) + (a[8] * b[6]),
      (a[6] * b[1]) + (a[7] * b[4]) + (a[8] * b[7]),
      (a[6] * b[2]) + (a[7] * b[5]) + (a[8] * b[8]),
    ];
  }

  Offset _applyTransform(List<double> transform, double x, double y) {
    final double w = (transform[6] * x) + (transform[7] * y) + transform[8];
    if (w.abs() < 1e-6) {
      return Offset(transform[2], transform[5]);
    }
    return Offset(
      ((transform[0] * x) + (transform[1] * y) + transform[2]) / w,
      ((transform[3] * x) + (transform[4] * y) + transform[5]) / w,
    );
  }
}
