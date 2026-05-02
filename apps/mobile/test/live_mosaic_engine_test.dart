import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/capture/live_frame_sampler.dart';
import 'package:mobile/features/capture/live_mosaic_engine.dart';
import 'package:nexthria_domain/nexthria_domain.dart';

void main() {
  test('live mosaic engine paints coverage and mosaic intensity', () {
    final LiveMosaicEngine engine = LiveMosaicEngine();
    final FrameSample sample = FrameSample(
      width: 8,
      height: 8,
      values: List<double>.generate(
        64,
        (int index) => (index.isEven ? 220 : 40).toDouble(),
      ),
    );

    final LiveMosaicSolution solution = engine.ingest(
      sample: sample,
      utilityScore: const UtilityScore(
        sharpness: 0.82,
        glareRatio: 0.06,
        vascularContrast: 0.74,
        illumination: 0.79,
        posteriorPoleFraming: 0.76,
        stableFocus: 0.81,
        diagnosticQuality: 0.8,
        mosaicUtility: 0.78,
        diagnosticPass: true,
        retainForMosaic: true,
        weightedTotal: 0.8,
      ),
      anchor: null,
    );

    expect(solution.coveragePercent, greaterThan(0));
    expect(solution.coverageGrid.any((double value) => value > 0), isTrue);
    expect(
      solution.mosaicIntensityGrid.any((double value) => value > 0),
      isTrue,
    );
    expect(solution.transform.length, 9);
  });
}
