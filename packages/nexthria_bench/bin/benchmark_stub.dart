import 'dart:convert';
import 'dart:io';

import 'package:nexthria_bench/nexthria_bench.dart';

const String _sampleManifest = '''
[
  {
    "id": "capture-001",
    "label": "accept",
    "score": {
      "sharpness": 0.79,
      "glareRatio": 0.08,
      "vascularContrast": 0.71,
      "illumination": 0.77,
      "posteriorPoleFraming": 0.75,
      "stableFocus": 0.7,
      "diagnosticQuality": 0.78,
      "mosaicUtility": 0.74,
      "diagnosticPass": true,
      "retainForMosaic": true,
      "weightedTotal": 0.74,
      "keepFrame": true
    }
  },
  {
    "id": "capture-002",
    "label": "reject",
    "score": {
      "sharpness": 0.29,
      "glareRatio": 0.26,
      "vascularContrast": 0.24,
      "illumination": 0.41,
      "posteriorPoleFraming": 0.31,
      "stableFocus": 0.28,
      "diagnosticQuality": 0.27,
      "mosaicUtility": 0.33,
      "diagnosticPass": false,
      "retainForMosaic": false,
      "rejectionReasons": ["Reduce corneal glare"],
      "weightedTotal": 0.33,
      "keepFrame": false
    }
  }
  ,
  {
    "id": "capture-003",
    "label": "pendingReview",
    "score": {
      "sharpness": 0.55,
      "glareRatio": 0.14,
      "vascularContrast": 0.48,
      "illumination": 0.61,
      "posteriorPoleFraming": 0.5,
      "stableFocus": 0.46,
      "diagnosticQuality": 0.58,
      "mosaicUtility": 0.57,
      "diagnosticPass": false,
      "retainForMosaic": true,
      "weightedTotal": 0.57,
      "keepFrame": true
    }
  }
]
''';

void main(List<String> args) {
  final CaptureGateBenchmarkRunner runner = const CaptureGateBenchmarkRunner();
  final String rawJson = args.isEmpty
      ? _sampleManifest
      : File(args.first).readAsStringSync();
  final List<CaptureGateRecord> records = runner.parseManifest(rawJson);
  final CaptureGateBenchmarkReport report = runner.run(records);

  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'manifestPath': args.isEmpty ? 'embedded-sample' : args.first,
      ...report.toJson(),
    }),
  );
}
