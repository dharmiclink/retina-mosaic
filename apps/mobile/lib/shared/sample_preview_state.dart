import 'package:nexthria_domain/nexthria_domain.dart';

const CapturePreviewState idlePreviewState = CapturePreviewState(
  sessionId: 'phase0-idle',
  eyeLaterality: EyeLaterality.right,
  utilityScore: UtilityScore(
    sharpness: 0.42,
    glareRatio: 0.18,
    vascularContrast: 0.35,
    illumination: 0.51,
    posteriorPoleFraming: 0.34,
    stableFocus: 0.39,
    diagnosticQuality: 0.41,
    mosaicUtility: 0.44,
    rejectionReasons: <String>['Find pupil reflex and center posterior pole'],
    weightedTotal: 0.44,
    keepFrame: false,
  ),
  guidanceVector: GuidanceVector(
    direction: GuidanceDirection.center,
    magnitude: 0,
    instruction: 'Center retina in view to begin',
    confidence: 0.72,
  ),
  mosaicUpdate: MosaicUpdate(
    transform: <double>[1, 0, 0, 0, 1, 0, 0, 0, 1],
    coveragePercent: 12,
    unresolvedHolesMask: 'mask://idle',
    confidenceSummary: ConfidenceSummary(
      meanConfidence: 0.45,
      minConfidence: 0.22,
      maxConfidence: 0.61,
    ),
  ),
  bucketSize: 0,
  qualityLabel: 'Awaiting NexEye capture alignment',
  processingActive: false,
  bestDiagnosticScore: 0,
  diagnosticCapturePassed: false,
  captureLocked: false,
  rejectionReasons: <String>['Find pupil reflex and center posterior pole'],
  guidanceStage: GuidanceStage.findReflex,
  selectionMode: SelectionMode.auto,
);
