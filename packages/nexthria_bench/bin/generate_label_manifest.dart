import 'dart:convert';
import 'dart:io';

import 'package:nexthria_bench/nexthria_bench.dart';
import 'package:nexthria_domain/nexthria_domain.dart';

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln(
      'Usage: dart run bin/generate_label_manifest.dart <dataset_root> <output_json>',
    );
    exitCode = 64;
    return;
  }

  final Directory datasetRoot = Directory(args[0]);
  if (!datasetRoot.existsSync()) {
    stderr.writeln('Dataset root not found: ${datasetRoot.path}');
    exitCode = 66;
    return;
  }

  final File outputFile = File(args[1]);
  outputFile.parent.createSync(recursive: true);

  final List<FileSystemEntity> files =
      datasetRoot
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where(_isSupportedImage)
          .toList()
        ..sort(
          (FileSystemEntity a, FileSystemEntity b) => a.path.compareTo(b.path),
        );

  final List<Map<String, dynamic>> manifest = files
      .map((FileSystemEntity entity) {
        final File file = entity as File;
        final String basename = file.uri.pathSegments.last;
        final String stem = basename.contains('.')
            ? basename.substring(0, basename.lastIndexOf('.'))
            : basename;
        final String parent = file.parent.uri.pathSegments.isNotEmpty
            ? file.parent.uri.pathSegments[file.parent.uri.pathSegments.length -
                  2]
            : '';

        return CaptureGateRecord(
          id: stem,
          label: CaptureLabel.pendingReview,
          path: file.path,
          eyeLaterality: _parseLaterality(basename).name,
          sourceType: 'fundus_camera_reference',
          drGradeReference: parent,
          sharpnessScore: null,
          glareScore: null,
          illuminationScore: null,
          vascularContrastScore: null,
          posteriorPoleFramingScore: null,
          stableFocusScore: null,
          notes: '',
          reviewer: '',
          score: const UtilityScore(
            sharpness: 0,
            glareRatio: 0,
            vascularContrast: 0,
            illumination: 0,
            posteriorPoleFraming: 0,
            stableFocus: 0,
            diagnosticQuality: 0,
            mosaicUtility: 0,
            diagnosticPass: false,
            retainForMosaic: false,
            weightedTotal: 0,
            keepFrame: false,
          ),
        ).toJson();
      })
      .toList(growable: false);

  outputFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );

  stdout.writeln(
    'Wrote ${manifest.length} manifest entries to ${outputFile.path}',
  );
}

bool _isSupportedImage(File file) {
  final String lowercase = file.path.toLowerCase();
  return lowercase.endsWith('.jpg') ||
      lowercase.endsWith('.jpeg') ||
      lowercase.endsWith('.png');
}

EyeLaterality _parseLaterality(String basename) {
  final String lowercase = basename.toLowerCase();
  if (lowercase.contains('left')) {
    return EyeLaterality.left;
  }
  if (lowercase.contains('right')) {
    return EyeLaterality.right;
  }
  return EyeLaterality.unknown;
}
