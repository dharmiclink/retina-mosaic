import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nexthria_bench/nexthria_bench.dart';
import 'package:nexthria_domain/nexthria_domain.dart';

void main() {
  test('benchmark report serializes nested snapshot', () {
    const BenchmarkReport report = BenchmarkReport(
      frameScoringLatencyMs: 5,
      previewUpdateLatencyMs: 40,
      memoryFootprintMb: 150,
      snapshot: CapturePreviewState(
        sessionId: 'bench',
        eyeLaterality: EyeLaterality.left,
        utilityScore: UtilityScore(
          sharpness: 1,
          glareRatio: 0.1,
          vascularContrast: 0.8,
          illumination: 0.7,
          weightedTotal: 0.8,
          keepFrame: true,
        ),
        guidanceVector: GuidanceVector(
          direction: GuidanceDirection.center,
          magnitude: 0,
          instruction: 'Centered',
          confidence: 1,
        ),
        mosaicUpdate: MosaicUpdate(
          transform: <double>[1, 0, 0, 0, 1, 0, 0, 0, 1],
          coveragePercent: 10,
          unresolvedHolesMask: 'mask://test',
          confidenceSummary: ConfidenceSummary(
            meanConfidence: 0.8,
            minConfidence: 0.5,
            maxConfidence: 0.9,
          ),
        ),
        bucketSize: 2,
        qualityLabel: 'Good',
        processingActive: true,
      ),
    );

    expect(report.toJson()['snapshot'], isA<Map<String, dynamic>>());
  });

  test('capture gate benchmark counts confusion correctly', () {
    const CaptureGateBenchmarkRunner runner = CaptureGateBenchmarkRunner();
    final List<CaptureGateRecord> records = <CaptureGateRecord>[
      CaptureGateRecord(
        id: 'ok',
        label: CaptureLabel.accept,
        score: const UtilityScore(
          sharpness: 0.8,
          glareRatio: 0.08,
          vascularContrast: 0.7,
          illumination: 0.76,
          posteriorPoleFraming: 0.72,
          stableFocus: 0.7,
          diagnosticQuality: 0.79,
          mosaicUtility: 0.73,
          diagnosticPass: true,
          retainForMosaic: true,
        ),
      ),
      CaptureGateRecord(
        id: 'bad',
        label: CaptureLabel.reject,
        score: const UtilityScore(
          sharpness: 0.3,
          glareRatio: 0.24,
          vascularContrast: 0.25,
          illumination: 0.4,
          posteriorPoleFraming: 0.3,
          stableFocus: 0.3,
          diagnosticQuality: 0.28,
          mosaicUtility: 0.32,
          diagnosticPass: false,
          retainForMosaic: false,
        ),
      ),
      CaptureGateRecord(
        id: 'review',
        label: CaptureLabel.pendingReview,
        score: const UtilityScore(
          sharpness: 0.5,
          glareRatio: 0.12,
          vascularContrast: 0.42,
          illumination: 0.57,
          posteriorPoleFraming: 0.49,
          stableFocus: 0.45,
          diagnosticQuality: 0.57,
          mosaicUtility: 0.56,
          diagnosticPass: false,
          retainForMosaic: true,
        ),
      ),
    ];

    final CaptureGateBenchmarkReport report = runner.run(records);

    expect(report.recordCount, 3);
    expect(report.evaluatedRecordCount, 2);
    expect(report.confusion.truePositive, 1);
    expect(report.confusion.trueNegative, 1);
    expect(report.pendingReviewCount, 1);
    expect(report.borderlineCount, 0);
    expect(report.mismatches, isEmpty);
  });

  test('reference quality scorer returns bounded scores for image input', () {
    final img.Image image = img.Image(width: 64, height: 64);
    for (int y = 0; y < image.height; y += 1) {
      for (int x = 0; x < image.width; x += 1) {
        final int green = ((80 + (x * 2) - y).clamp(0, 255)).round();
        image.setPixelRgb(x, y, 40, green, 20);
      }
    }

    final ReferenceQualityScorer scorer = const ReferenceQualityScorer();
    final UtilityScore score = scorer.scoreImage(image);

    expect(score.sharpness, inInclusiveRange(0, 1));
    expect(score.illumination, inInclusiveRange(0, 1));
    expect(score.vascularContrast, inInclusiveRange(0, 1));
    expect(score.posteriorPoleFraming, inInclusiveRange(0, 1));
    expect(score.stableFocus, inInclusiveRange(0, 1));
  });
}
