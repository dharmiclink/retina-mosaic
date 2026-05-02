import 'dart:convert';
import 'dart:io';

import 'package:nexthria_bench/nexthria_bench.dart';

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln(
      'Usage: dart run bin/enrich_label_manifest.dart <input_json> <output_json> [dataset_root]',
    );
    exitCode = 64;
    return;
  }

  final File inputFile = File(args[0]);
  if (!inputFile.existsSync()) {
    stderr.writeln('Input manifest not found: ${inputFile.path}');
    exitCode = 66;
    return;
  }

  final List<dynamic> decoded =
      jsonDecode(inputFile.readAsStringSync()) as List<dynamic>;
  final ReferenceQualityScorer scorer = const ReferenceQualityScorer();
  final Directory? datasetRoot = args.length >= 3 ? Directory(args[2]) : null;

  final List<Map<String, dynamic>> enriched = decoded
      .map((dynamic item) {
        final CaptureGateRecord record = CaptureGateRecord.fromJson(
          item as Map<String, dynamic>,
        );
        if (record.path == null || record.path!.isEmpty) {
          return record.toJson();
        }

        final File imageFile = _resolveImageFile(
          record.path!,
          manifestFile: inputFile,
          datasetRoot: datasetRoot,
        );
        if (!imageFile.existsSync()) {
          return record.toJson();
        }

        final score = scorer.scoreFile(imageFile);
        return CaptureGateRecord(
          id: record.id,
          label: record.label,
          path: record.path,
          eyeLaterality: record.eyeLaterality,
          sourceType: record.sourceType,
          drGradeReference: record.drGradeReference,
          sharpnessScore: record.sharpnessScore,
          glareScore: record.glareScore,
          illuminationScore: record.illuminationScore,
          vascularContrastScore: record.vascularContrastScore,
          posteriorPoleFramingScore: record.posteriorPoleFramingScore,
          stableFocusScore: record.stableFocusScore,
          notes: record.notes,
          reviewer: record.reviewer,
          score: score,
        ).toJson();
      })
      .toList(growable: false);

  final File outputFile = File(args[1]);
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(enriched),
  );

  stdout.writeln(
    'Wrote ${enriched.length} enriched entries to ${outputFile.path}',
  );
}

File _resolveImageFile(
  String path, {
  required File manifestFile,
  required Directory? datasetRoot,
}) {
  final File directFile = File(path);
  if (directFile.isAbsolute) {
    return directFile;
  }
  if (datasetRoot != null) {
    return File('${datasetRoot.path}${Platform.pathSeparator}$path');
  }
  return File(
    '${manifestFile.parent.path}${Platform.pathSeparator}$path',
  );
}
