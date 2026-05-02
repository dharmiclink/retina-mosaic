import 'dart:ui';

import 'package:nexthria_domain/nexthria_domain.dart';

import 'live_frame_sampler.dart';

class RetainedGoldFrame {
  const RetainedGoldFrame({
    required this.goldFrame,
    required this.frameEnvelope,
    required this.sample,
    required this.canvasTransform,
    required this.canvasOffset,
    required this.alignmentConfidence,
    required this.retainedFramePath,
  });

  final GoldFrame goldFrame;
  final FrameEnvelope frameEnvelope;
  final FrameSample sample;
  final List<double> canvasTransform;
  final Offset canvasOffset;
  final double alignmentConfidence;
  final String retainedFramePath;
}

class GoldFrameBucket {
  GoldFrameBucket({this.capacity = 48});

  final int capacity;
  final List<RetainedGoldFrame> _frames = <RetainedGoldFrame>[];

  void reset() => _frames.clear();

  int get size => _frames.length;

  RetainedGoldFrame? get latestAccepted =>
      _frames.isEmpty ? null : _frames.first;

  List<RetainedGoldFrame> get frames =>
      List<RetainedGoldFrame>.unmodifiable(_frames);

  void add(RetainedGoldFrame frame) {
    _frames.insert(0, frame);
    _frames.sort((RetainedGoldFrame a, RetainedGoldFrame b) {
      final int diagnosticOrder = b.goldFrame.utilityScore.diagnosticQuality
          .compareTo(a.goldFrame.utilityScore.diagnosticQuality);
      if (diagnosticOrder != 0) {
        return diagnosticOrder;
      }
      return b.goldFrame.utilityScore.mosaicUtility.compareTo(
        a.goldFrame.utilityScore.mosaicUtility,
      );
    });

    if (_frames.length > capacity) {
      _frames.removeRange(capacity, _frames.length);
    }
  }
}
