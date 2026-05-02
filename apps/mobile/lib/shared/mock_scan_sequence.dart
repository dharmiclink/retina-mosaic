import 'package:flutter/material.dart';
import 'package:nexthria_domain/nexthria_domain.dart';

const String mockFundusAssetPath =
    'assets/demo_sequences/fundus_normal_right_eye_cc0.jpg';

class MockScanStep {
  const MockScanStep({
    required this.sequenceNumber,
    required this.alignment,
    required this.zoom,
    required this.utilityScore,
    required this.guidanceVector,
    required this.coveragePercent,
    required this.bucketSize,
    required this.qualityLabel,
    required this.confidenceSummary,
    required this.transform,
  });

  final int sequenceNumber;
  final Alignment alignment;
  final double zoom;
  final UtilityScore utilityScore;
  final GuidanceVector guidanceVector;
  final double coveragePercent;
  final int bucketSize;
  final String qualityLabel;
  final ConfidenceSummary confidenceSummary;
  final List<double> transform;
}

const List<MockScanStep> mockScanSequence = <MockScanStep>[
  MockScanStep(
    sequenceNumber: 1,
    alignment: Alignment(-0.58, 0.14),
    zoom: 1.26,
    utilityScore: UtilityScore(
      sharpness: 0.72,
      glareRatio: 0.06,
      vascularContrast: 0.71,
      illumination: 0.78,
      weightedTotal: 0.74,
      keepFrame: true,
    ),
    guidanceVector: GuidanceVector(
      direction: GuidanceDirection.left,
      magnitude: 5,
      instruction: 'Sweep left to pull the optic disc into view',
      confidence: 0.84,
    ),
    coveragePercent: 18,
    bucketSize: 3,
    qualityLabel: 'Gold frame accepted from inferior arcade',
    confidenceSummary: ConfidenceSummary(
      meanConfidence: 0.63,
      minConfidence: 0.34,
      maxConfidence: 0.88,
    ),
    transform: <double>[1, 0, -16, 0, 1, 12, 0, 0, 1],
  ),
  MockScanStep(
    sequenceNumber: 2,
    alignment: Alignment(-0.28, -0.02),
    zoom: 1.22,
    utilityScore: UtilityScore(
      sharpness: 0.76,
      glareRatio: 0.05,
      vascularContrast: 0.75,
      illumination: 0.81,
      weightedTotal: 0.78,
      keepFrame: true,
    ),
    guidanceVector: GuidanceVector(
      direction: GuidanceDirection.up,
      magnitude: 4,
      instruction: 'Tilt 4° up to expand superior vessel coverage',
      confidence: 0.86,
    ),
    coveragePercent: 31,
    bucketSize: 6,
    qualityLabel: 'Bucket filling with stable vessel contrast',
    confidenceSummary: ConfidenceSummary(
      meanConfidence: 0.69,
      minConfidence: 0.42,
      maxConfidence: 0.9,
    ),
    transform: <double>[1, 0, -9, 0, 1, 6, 0, 0, 1],
  ),
  MockScanStep(
    sequenceNumber: 3,
    alignment: Alignment(0.02, -0.18),
    zoom: 1.18,
    utilityScore: UtilityScore(
      sharpness: 0.82,
      glareRatio: 0.04,
      vascularContrast: 0.8,
      illumination: 0.83,
      weightedTotal: 0.81,
      keepFrame: true,
    ),
    guidanceVector: GuidanceVector(
      direction: GuidanceDirection.right,
      magnitude: 3,
      instruction: 'Drift right to close the upper nasal gap',
      confidence: 0.88,
    ),
    coveragePercent: 45,
    bucketSize: 9,
    qualityLabel: 'Mosaic broadening across the macula',
    confidenceSummary: ConfidenceSummary(
      meanConfidence: 0.74,
      minConfidence: 0.49,
      maxConfidence: 0.93,
    ),
    transform: <double>[1, 0, 2, 0, 1, -2, 0, 0, 1],
  ),
  MockScanStep(
    sequenceNumber: 4,
    alignment: Alignment(0.28, -0.24),
    zoom: 1.16,
    utilityScore: UtilityScore(
      sharpness: 0.8,
      glareRatio: 0.05,
      vascularContrast: 0.79,
      illumination: 0.8,
      weightedTotal: 0.79,
      keepFrame: true,
    ),
    guidanceVector: GuidanceVector(
      direction: GuidanceDirection.down,
      magnitude: 4,
      instruction: 'Sweep down slightly to fill the temporal edge',
      confidence: 0.85,
    ),
    coveragePercent: 58,
    bucketSize: 12,
    qualityLabel: 'Temporal canvas projection remains locked',
    confidenceSummary: ConfidenceSummary(
      meanConfidence: 0.78,
      minConfidence: 0.54,
      maxConfidence: 0.95,
    ),
    transform: <double>[1, 0, 10, 0, 1, -7, 0, 0, 1],
  ),
  MockScanStep(
    sequenceNumber: 5,
    alignment: Alignment(0.18, 0.08),
    zoom: 1.15,
    utilityScore: UtilityScore(
      sharpness: 0.84,
      glareRatio: 0.03,
      vascularContrast: 0.82,
      illumination: 0.85,
      weightedTotal: 0.83,
      keepFrame: true,
    ),
    guidanceVector: GuidanceVector(
      direction: GuidanceDirection.left,
      magnitude: 2,
      instruction: 'Ease left to back-fill the mid-field hole',
      confidence: 0.9,
    ),
    coveragePercent: 69,
    bucketSize: 15,
    qualityLabel: 'Back-fill pass added a high-utility frame',
    confidenceSummary: ConfidenceSummary(
      meanConfidence: 0.82,
      minConfidence: 0.6,
      maxConfidence: 0.97,
    ),
    transform: <double>[1, 0, 7, 0, 1, 3, 0, 0, 1],
  ),
  MockScanStep(
    sequenceNumber: 6,
    alignment: Alignment(-0.04, 0.18),
    zoom: 1.12,
    utilityScore: UtilityScore(
      sharpness: 0.86,
      glareRatio: 0.03,
      vascularContrast: 0.84,
      illumination: 0.87,
      weightedTotal: 0.85,
      keepFrame: true,
    ),
    guidanceVector: GuidanceVector(
      direction: GuidanceDirection.up,
      magnitude: 2,
      instruction: 'Sweep up slowly to close the superior crescent',
      confidence: 0.91,
    ),
    coveragePercent: 79,
    bucketSize: 18,
    qualityLabel: 'Non-linear stitch recovered superior coverage',
    confidenceSummary: ConfidenceSummary(
      meanConfidence: 0.86,
      minConfidence: 0.66,
      maxConfidence: 0.98,
    ),
    transform: <double>[1, 0, -1, 0, 1, 9, 0, 0, 1],
  ),
  MockScanStep(
    sequenceNumber: 7,
    alignment: Alignment(0.1, -0.06),
    zoom: 1.1,
    utilityScore: UtilityScore(
      sharpness: 0.88,
      glareRatio: 0.02,
      vascularContrast: 0.85,
      illumination: 0.88,
      weightedTotal: 0.87,
      keepFrame: true,
    ),
    guidanceVector: GuidanceVector(
      direction: GuidanceDirection.center,
      magnitude: 1,
      instruction: 'Re-center and hold for final coverage lock',
      confidence: 0.94,
    ),
    coveragePercent: 88,
    bucketSize: 21,
    qualityLabel: 'Canvas nearly closed with clean disc detail',
    confidenceSummary: ConfidenceSummary(
      meanConfidence: 0.89,
      minConfidence: 0.72,
      maxConfidence: 0.99,
    ),
    transform: <double>[1, 0, 3, 0, 1, 1, 0, 0, 1],
  ),
  MockScanStep(
    sequenceNumber: 8,
    alignment: Alignment.center,
    zoom: 1.08,
    utilityScore: UtilityScore(
      sharpness: 0.9,
      glareRatio: 0.02,
      vascularContrast: 0.87,
      illumination: 0.9,
      weightedTotal: 0.89,
      keepFrame: true,
    ),
    guidanceVector: GuidanceVector(
      direction: GuidanceDirection.hold,
      magnitude: 0,
      instruction: 'Hold steady, export-ready mosaic reached',
      confidence: 0.96,
    ),
    coveragePercent: 95,
    bucketSize: 24,
    qualityLabel: 'Coverage threshold reached with export confidence',
    confidenceSummary: ConfidenceSummary(
      meanConfidence: 0.92,
      minConfidence: 0.78,
      maxConfidence: 1.0,
    ),
    transform: <double>[1, 0, 0, 0, 1, 0, 0, 0, 1],
  ),
];
