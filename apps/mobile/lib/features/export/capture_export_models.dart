import 'package:nexthria_domain/nexthria_domain.dart';

import '../capture/gold_frame_bucket.dart';

class CaptureExportRequest {
  const CaptureExportRequest({
    required this.sessionId,
    required this.eyeLaterality,
    required this.retainedFrames,
    required this.bestDiagnosticFrame,
    required this.autoSuggestedFrame,
    required this.bestDiagnosticScore,
    required this.diagnosticCapturePassed,
    required this.selectionMode,
    required this.selectionReason,
    required this.captureProfileVersion,
    required this.mosaicIntensityGrid,
    required this.mosaicResolution,
    required this.coveragePercent,
  });

  final String sessionId;
  final EyeLaterality eyeLaterality;
  final List<RetainedGoldFrame> retainedFrames;
  final RetainedGoldFrame bestDiagnosticFrame;
  final RetainedGoldFrame? autoSuggestedFrame;
  final double bestDiagnosticScore;
  final bool diagnosticCapturePassed;
  final SelectionMode selectionMode;
  final String selectionReason;
  final String captureProfileVersion;
  final List<double> mosaicIntensityGrid;
  final int mosaicResolution;
  final double coveragePercent;
}
