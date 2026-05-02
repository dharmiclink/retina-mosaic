import 'dart:convert';

import 'package:nexthria_domain/nexthria_domain.dart';

import 'src/native_api.dart';

class NativeTransformEstimate {
  const NativeTransformEstimate({
    required this.transform,
    required this.dx,
    required this.dy,
    required this.scale,
    required this.rotationRadians,
    required this.confidence,
    required this.anchorKeypoints,
    required this.currentKeypoints,
    required this.inlierCount,
    required this.meanReprojectionError,
  });

  final List<double> transform;
  final double dx;
  final double dy;
  final double scale;
  final double rotationRadians;
  final double confidence;
  final int anchorKeypoints;
  final int currentKeypoints;
  final int inlierCount;
  final double meanReprojectionError;

  factory NativeTransformEstimate.fromJson(Map<String, dynamic> json) {
    return NativeTransformEstimate(
      transform: (json['transform'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic value) => (value as num).toDouble())
          .toList(growable: false),
      dx: (json['dx'] as num?)?.toDouble() ?? 0,
      dy: (json['dy'] as num?)?.toDouble() ?? 0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1,
      rotationRadians: (json['rotationRadians'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      anchorKeypoints: json['anchorKeypoints'] as int? ?? 0,
      currentKeypoints: json['currentKeypoints'] as int? ?? 0,
      inlierCount: json['inlierCount'] as int? ?? 0,
      meanReprojectionError:
          (json['meanReprojectionError'] as num?)?.toDouble() ?? 999,
    );
  }
}

class NativeMosaicAccumulateResult {
  const NativeMosaicAccumulateResult({
    required this.transform,
    required this.coveragePercent,
    required this.coverageGrid,
    required this.mosaicIntensityGrid,
    required this.mosaicWeightGrid,
    required this.meanConfidence,
    required this.minConfidence,
    required this.maxConfidence,
    required this.canvasOffsetX,
    required this.canvasOffsetY,
    required this.suggestedSweepDirection,
  });

  final List<double> transform;
  final double coveragePercent;
  final List<double> coverageGrid;
  final List<double> mosaicIntensityGrid;
  final List<double> mosaicWeightGrid;
  final double meanConfidence;
  final double minConfidence;
  final double maxConfidence;
  final double canvasOffsetX;
  final double canvasOffsetY;
  final GuidanceDirection suggestedSweepDirection;

  factory NativeMosaicAccumulateResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> confidence =
        json['confidenceSummary'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final Map<String, dynamic> offset =
        json['canvasOffset'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final String rawDirection =
        json['suggestedSweepDirection'] as String? ??
        GuidanceDirection.hold.name;
    return NativeMosaicAccumulateResult(
      transform: (json['transform'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic value) => (value as num).toDouble())
          .toList(growable: false),
      coveragePercent: (json['coveragePercent'] as num?)?.toDouble() ?? 0,
      coverageGrid:
          (json['coverageGrid'] as List<dynamic>? ?? const <dynamic>[])
              .map((dynamic value) => (value as num).toDouble())
              .toList(growable: false),
      mosaicIntensityGrid:
          (json['mosaicIntensityGrid'] as List<dynamic>? ?? const <dynamic>[])
              .map((dynamic value) => (value as num).toDouble())
              .toList(growable: false),
      mosaicWeightGrid:
          (json['mosaicWeightGrid'] as List<dynamic>? ?? const <dynamic>[])
              .map((dynamic value) => (value as num).toDouble())
              .toList(growable: false),
      meanConfidence: (confidence['meanConfidence'] as num?)?.toDouble() ?? 0,
      minConfidence: (confidence['minConfidence'] as num?)?.toDouble() ?? 0,
      maxConfidence: (confidence['maxConfidence'] as num?)?.toDouble() ?? 0,
      canvasOffsetX: (offset['x'] as num?)?.toDouble() ?? 0,
      canvasOffsetY: (offset['y'] as num?)?.toDouble() ?? 0,
      suggestedSweepDirection: GuidanceDirection.values.firstWhere(
        (GuidanceDirection value) => value.name == rawDirection,
        orElse: () => GuidanceDirection.hold,
      ),
    );
  }
}

class NexthriaCvPlugin {
  NexthriaCvPlugin._();

  static final NexthriaCvPlugin instance = NexthriaCvPlugin._();

  final NativeApi _nativeApi = NativeApi();

  String _sessionId = 'phase0-session';
  bool _processingActive = false;

  Future<String> initializeSession({String patientId = 'demo-patient'}) async {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    _sessionId = '$patientId-$timestamp';
    _processingActive = false;
    return _sessionId;
  }

  Future<void> startStreamProcessing() async {
    _processingActive = true;
  }

  Future<void> stopStreamProcessing() async {
    _processingActive = false;
  }

  Future<CapturePreviewState> getLatestPreviewState() async {
    final Map<String, dynamic> json =
        jsonDecode(_nativeApi.previewStateJson()) as Map<String, dynamic>;
    final Map<String, dynamic> merged = <String, dynamic>{
      ...json,
      'sessionId': _sessionId,
      'processingActive': _processingActive,
    };

    return CapturePreviewState.fromJson(merged);
  }

  Future<CaptureSessionExport> exportSession() async {
    final Map<String, dynamic> json =
        jsonDecode(_nativeApi.exportJson()) as Map<String, dynamic>;
    return CaptureSessionExport.fromJson(json);
  }

  NativeTransformEstimate? estimateTransform({
    required List<double> anchorValues,
    required int anchorWidth,
    required int anchorHeight,
    required List<double> currentValues,
    required int currentWidth,
    required int currentHeight,
  }) {
    final String payload = _nativeApi.estimateTransformJson(
      anchorValues: anchorValues,
      anchorWidth: anchorWidth,
      anchorHeight: anchorHeight,
      currentValues: currentValues,
      currentWidth: currentWidth,
      currentHeight: currentHeight,
    );
    if (payload.isEmpty || payload == '{}') {
      return null;
    }
    return NativeTransformEstimate.fromJson(
      jsonDecode(payload) as Map<String, dynamic>,
    );
  }

  NativeMosaicAccumulateResult? accumulateMosaic({
    required List<double> sampleValues,
    required int sampleWidth,
    required int sampleHeight,
    required List<double> transformValues,
    required List<double> coverageValues,
    required List<double> intensityValues,
    required List<double> weightValues,
    required double utilityWeight,
    required int gridSize,
    required int mosaicResolution,
  }) {
    final String payload = _nativeApi.accumulateMosaicJson(
      sampleValues: sampleValues,
      sampleWidth: sampleWidth,
      sampleHeight: sampleHeight,
      transformValues: transformValues,
      coverageValues: coverageValues,
      intensityValues: intensityValues,
      weightValues: weightValues,
      utilityWeight: utilityWeight,
      gridSize: gridSize,
      mosaicResolution: mosaicResolution,
    );
    if (payload.isEmpty || payload == '{}') {
      return null;
    }
    return NativeMosaicAccumulateResult.fromJson(
      jsonDecode(payload) as Map<String, dynamic>,
    );
  }

  int ping() => _nativeApi.ping();
}
