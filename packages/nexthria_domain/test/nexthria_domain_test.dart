import 'package:flutter_test/flutter_test.dart';
import 'package:nexthria_domain/nexthria_domain.dart';

void main() {
  test('capture preview state round-trips to JSON', () {
    final CapturePreviewState state = CapturePreviewState(
      sessionId: 'session-01',
      eyeLaterality: EyeLaterality.right,
      utilityScore: const UtilityScore(
        sharpness: 0.91,
        glareRatio: 0.08,
        vascularContrast: 0.74,
        illumination: 0.81,
        posteriorPoleFraming: 0.79,
        stableFocus: 0.83,
        diagnosticQuality: 0.87,
        mosaicUtility: 0.84,
        diagnosticPass: true,
        retainForMosaic: true,
        rejectionReasons: <String>[],
        weightedTotal: 0.84,
        keepFrame: true,
      ),
      guidanceVector: const GuidanceVector(
        direction: GuidanceDirection.left,
        magnitude: 5,
        instruction: 'Tilt device 5° left',
        confidence: 0.88,
      ),
      mosaicUpdate: const MosaicUpdate(
        transform: <double>[1, 0, 0, 0, 1, 0, 0, 0, 1],
        coveragePercent: 62.5,
        unresolvedHolesMask: 'mask://phase0',
        confidenceSummary: ConfidenceSummary(
          meanConfidence: 0.82,
          minConfidence: 0.55,
          maxConfidence: 0.97,
        ),
      ),
      bucketSize: 14,
      qualityLabel: 'Diagnostic frame locked',
      processingActive: true,
      bestDiagnosticFrameId: 'frame-17',
      bestDiagnosticScore: 0.87,
      diagnosticCapturePassed: true,
      captureLocked: true,
      guidanceStage: GuidanceStage.exportReady,
      selectionMode: SelectionMode.manual,
      autoSuggestedFrameId: 'frame-11',
    );

    final CapturePreviewState decoded = CapturePreviewState.fromJson(
      state.toJson(),
    );

    expect(decoded.sessionId, 'session-01');
    expect(decoded.eyeLaterality, EyeLaterality.right);
    expect(decoded.utilityScore.diagnosticPass, isTrue);
    expect(decoded.guidanceVector.direction, GuidanceDirection.left);
    expect(decoded.mosaicUpdate.coveragePercent, 62.5);
    expect(decoded.bestDiagnosticFrameId, 'frame-17');
    expect(decoded.guidanceStage, GuidanceStage.exportReady);
    expect(decoded.selectionMode, SelectionMode.manual);
    expect(decoded.autoSuggestedFrameId, 'frame-11');
  });
}
