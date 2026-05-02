import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:nexthria_domain/nexthria_domain.dart';

import 'live_frame_sampler.dart';

class LiveUtilityScorer {
  const LiveUtilityScorer();

  UtilityScore score(CameraImage image) =>
      scoreSample(FrameSample.fromCameraImage(image));

  UtilityScore scoreSample(FrameSample sample) {
    final int sampleCount = sample.values.length;
    if (sampleCount == 0) {
      return const UtilityScore(
        sharpness: 0,
        glareRatio: 1,
        vascularContrast: 0,
        illumination: 0,
        posteriorPoleFraming: 0,
        stableFocus: 0,
        diagnosticQuality: 0,
        mosaicUtility: 0,
        diagnosticPass: false,
        retainForMosaic: false,
        rejectionReasons: <String>['No retinal signal detected'],
      );
    }

    double sum = 0;
    int glareHits = 0;
    for (final double value in sample.values) {
      sum += value;
      if (value >= 245) {
        glareHits += 1;
      }
    }

    final double mean = sum / sampleCount;
    double varianceSum = 0;
    for (final double value in sample.values) {
      final double delta = value - mean;
      varianceSum += delta * delta;
    }

    final double variance = varianceSum / sampleCount;
    final double contrast = (math.sqrt(variance) / 72).clamp(0.0, 1.0);
    final double glareRatio = glareHits / sampleCount;

    double gradientSum = 0;
    int gradientCount = 0;
    double laplacianEnergy = 0;
    int laplacianCount = 0;

    for (int y = 1; y < sample.height - 1; y += 1) {
      for (int x = 1; x < sample.width - 1; x += 1) {
        final double center = sample.at(x, y);
        final double left = sample.at(x - 1, y);
        final double right = sample.at(x + 1, y);
        final double up = sample.at(x, y - 1);
        final double down = sample.at(x, y + 1);

        gradientSum += (right - left).abs() + (down - up).abs();
        gradientCount += 1;

        final double laplacian = (4 * center) - left - right - up - down;
        laplacianEnergy += laplacian.abs();
        laplacianCount += 1;
      }
    }

    final double vascularContrast = gradientCount == 0
        ? 0
        : (gradientSum / gradientCount / 92).clamp(0.0, 1.0);
    final double sharpness = laplacianCount == 0
        ? 0
        : (laplacianEnergy / laplacianCount / 48).clamp(0.0, 1.0);
    final double illumination =
        (((1 - ((mean - 132).abs() / 132)) * 0.7) + (contrast * 0.3)).clamp(
          0.0,
          1.0,
        );
    final double posteriorPoleFraming = _posteriorPoleFraming(sample);
    final double stableFocus = _stableFocus(sample);

    final double mosaicUtility =
        ((sharpness * 0.34) +
                ((1 - glareRatio) * 0.24) +
                (vascularContrast * 0.24) +
                (illumination * 0.18))
            .clamp(0.0, 1.0);
    final double diagnosticQuality =
        ((sharpness * 0.28) +
                ((1 - glareRatio) * 0.22) +
                (vascularContrast * 0.18) +
                (illumination * 0.14) +
                (posteriorPoleFraming * 0.12) +
                (stableFocus * 0.06))
            .clamp(0.0, 1.0);

    final List<String> rejectionReasons = <String>[];
    if (glareRatio > 0.18) {
      rejectionReasons.add('Reduce corneal glare');
    }
    if (sharpness < 0.42) {
      rejectionReasons.add('Hold steady for sharper vessel detail');
    }
    if (illumination < 0.48) {
      rejectionReasons.add('Re-center illumination through the pupil');
    }
    if (vascularContrast < 0.34) {
      rejectionReasons.add('Increase vessel contrast before capture');
    }
    if (posteriorPoleFraming < 0.48) {
      rejectionReasons.add('Center the posterior pole');
    }
    if (stableFocus < 0.44) {
      rejectionReasons.add('Maintain stable focus through the lens');
    }

    final bool diagnosticPass =
        diagnosticQuality >= 0.68 &&
        glareRatio <= 0.18 &&
        sharpness >= 0.42 &&
        vascularContrast >= 0.34 &&
        illumination >= 0.48 &&
        posteriorPoleFraming >= 0.48 &&
        stableFocus >= 0.44;
    final bool retainForMosaic =
        diagnosticPass ||
        (mosaicUtility >= 0.56 &&
            glareRatio <= 0.24 &&
            sharpness >= 0.32 &&
            vascularContrast >= 0.24);

    return UtilityScore(
      sharpness: sharpness,
      glareRatio: glareRatio,
      vascularContrast: vascularContrast,
      illumination: illumination,
      posteriorPoleFraming: posteriorPoleFraming,
      stableFocus: stableFocus,
      diagnosticQuality: diagnosticQuality,
      mosaicUtility: mosaicUtility,
      diagnosticPass: diagnosticPass,
      retainForMosaic: retainForMosaic,
      rejectionReasons: rejectionReasons,
      weightedTotal: mosaicUtility,
      keepFrame: retainForMosaic,
    );
  }

  double _posteriorPoleFraming(FrameSample sample) {
    final double centerX = sample.width / 2;
    final double centerY = sample.height / 2;
    final double maxDistance = math.sqrt(
      (centerX * centerX) + (centerY * centerY),
    );
    double centerWeightedSignal = 0;
    double centerWeight = 0;
    double edgePenalty = 0;

    for (int y = 0; y < sample.height; y += 1) {
      for (int x = 0; x < sample.width; x += 1) {
        final double dx = x - centerX;
        final double dy = y - centerY;
        final double radial = math.sqrt((dx * dx) + (dy * dy)) / maxDistance;
        final double centrality = (1 - radial).clamp(0.0, 1.0);
        final double localSignal = sample.at(x, y) / 255.0;
        centerWeightedSignal += localSignal * centrality;
        centerWeight += centrality;
        if (radial > 0.78) {
          edgePenalty += localSignal;
        }
      }
    }

    final double centeredSignal = centerWeight == 0
        ? 0
        : centerWeightedSignal / centerWeight;
    final double averageEdge =
        edgePenalty /
        math.max(1, ((sample.width * sample.height) * 0.2).round());
    return ((centeredSignal * 0.72) +
            ((1 - averageEdge).clamp(0.0, 1.0) * 0.28))
        .clamp(0.0, 1.0);
  }

  double _stableFocus(FrameSample sample) {
    if (sample.width < 5 || sample.height < 5) {
      return 0;
    }

    final int xStart = sample.width ~/ 4;
    final int xEnd = (sample.width * 3) ~/ 4;
    final int yStart = sample.height ~/ 4;
    final int yEnd = (sample.height * 3) ~/ 4;

    double centralLaplacian = 0;
    int centralCount = 0;
    for (int y = yStart + 1; y < yEnd - 1; y += 1) {
      for (int x = xStart + 1; x < xEnd - 1; x += 1) {
        final double center = sample.at(x, y);
        final double laplacian =
            (4 * center) -
            sample.at(x - 1, y) -
            sample.at(x + 1, y) -
            sample.at(x, y - 1) -
            sample.at(x, y + 1);
        centralLaplacian += laplacian.abs();
        centralCount += 1;
      }
    }

    final double meanCentralLaplacian = centralCount == 0
        ? 0
        : centralLaplacian / centralCount;
    return (meanCentralLaplacian / 56).clamp(0.0, 1.0);
  }
}
