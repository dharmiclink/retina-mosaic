import 'dart:convert';

import 'package:nexthria_domain/nexthria_domain.dart';

export 'src/reference_quality_scorer.dart';

class BenchmarkReport {
  const BenchmarkReport({
    required this.frameScoringLatencyMs,
    required this.previewUpdateLatencyMs,
    required this.memoryFootprintMb,
    required this.snapshot,
  });

  final double frameScoringLatencyMs;
  final double previewUpdateLatencyMs;
  final double memoryFootprintMb;
  final CapturePreviewState snapshot;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'frameScoringLatencyMs': frameScoringLatencyMs,
      'previewUpdateLatencyMs': previewUpdateLatencyMs,
      'memoryFootprintMb': memoryFootprintMb,
      'snapshot': snapshot.toJson(),
    };
  }
}

enum CaptureLabel { pendingReview, accept, borderline, reject }

class CaptureGateRecord {
  const CaptureGateRecord({
    required this.id,
    required this.label,
    required this.score,
    this.path,
    this.eyeLaterality,
    this.sourceType,
    this.drGradeReference,
    this.sharpnessScore,
    this.glareScore,
    this.illuminationScore,
    this.vascularContrastScore,
    this.posteriorPoleFramingScore,
    this.stableFocusScore,
    this.notes,
    this.reviewer,
  });

  final String id;
  final CaptureLabel label;
  final UtilityScore score;
  final String? path;
  final String? eyeLaterality;
  final String? sourceType;
  final String? drGradeReference;
  final int? sharpnessScore;
  final int? glareScore;
  final int? illuminationScore;
  final int? vascularContrastScore;
  final int? posteriorPoleFramingScore;
  final int? stableFocusScore;
  final String? notes;
  final String? reviewer;

  static CaptureLabel _parseLabel(String? rawLabel) {
    switch ((rawLabel ?? '').trim().toLowerCase()) {
      case 'acceptable':
      case 'accept':
        return CaptureLabel.accept;
      case 'unacceptable':
      case 'reject':
        return CaptureLabel.reject;
      case 'borderline':
        return CaptureLabel.borderline;
      case 'pending_review':
      case 'pending-review':
      case 'pending':
      case 'review_required':
      case 'review-required':
      case '':
        return CaptureLabel.pendingReview;
      default:
        return CaptureLabel.pendingReview;
    }
  }

  factory CaptureGateRecord.fromJson(Map<String, dynamic> json) {
    return CaptureGateRecord(
      id: json['id'] as String? ?? 'sample',
      label: _parseLabel(json['label'] as String?),
      score: UtilityScore.fromJson(
        json['score'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      path: json['path'] as String?,
      eyeLaterality: json['eyeLaterality'] as String?,
      sourceType: json['sourceType'] as String?,
      drGradeReference: json['drGradeReference'] as String?,
      sharpnessScore: json['sharpnessScore'] as int?,
      glareScore: json['glareScore'] as int?,
      illuminationScore: json['illuminationScore'] as int?,
      vascularContrastScore: json['vascularContrastScore'] as int?,
      posteriorPoleFramingScore: json['posteriorPoleFramingScore'] as int?,
      stableFocusScore: json['stableFocusScore'] as int?,
      notes: json['notes'] as String?,
      reviewer: json['reviewer'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label.name,
      'path': path,
      'eyeLaterality': eyeLaterality,
      'sourceType': sourceType,
      'drGradeReference': drGradeReference,
      'sharpnessScore': sharpnessScore,
      'glareScore': glareScore,
      'illuminationScore': illuminationScore,
      'vascularContrastScore': vascularContrastScore,
      'posteriorPoleFramingScore': posteriorPoleFramingScore,
      'stableFocusScore': stableFocusScore,
      'notes': notes,
      'reviewer': reviewer,
      'score': score.toJson(),
    };
  }
}

class CaptureGateConfusion {
  const CaptureGateConfusion({
    required this.truePositive,
    required this.falsePositive,
    required this.trueNegative,
    required this.falseNegative,
  });

  final int truePositive;
  final int falsePositive;
  final int trueNegative;
  final int falseNegative;

  double get precision {
    final int denominator = truePositive + falsePositive;
    return denominator == 0 ? 0 : truePositive / denominator;
  }

  double get recall {
    final int denominator = truePositive + falseNegative;
    return denominator == 0 ? 0 : truePositive / denominator;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'truePositive': truePositive,
      'falsePositive': falsePositive,
      'trueNegative': trueNegative,
      'falseNegative': falseNegative,
      'precision': precision,
      'recall': recall,
    };
  }
}

class CaptureGateBenchmarkReport {
  const CaptureGateBenchmarkReport({
    required this.captureProfileVersion,
    required this.recordCount,
    required this.evaluatedRecordCount,
    required this.pendingReviewCount,
    required this.borderlineCount,
    required this.confusion,
    required this.mismatches,
  });

  final String captureProfileVersion;
  final int recordCount;
  final int evaluatedRecordCount;
  final int pendingReviewCount;
  final int borderlineCount;
  final CaptureGateConfusion confusion;
  final List<String> mismatches;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'captureProfileVersion': captureProfileVersion,
      'recordCount': recordCount,
      'evaluatedRecordCount': evaluatedRecordCount,
      'pendingReviewCount': pendingReviewCount,
      'borderlineCount': borderlineCount,
      'confusion': confusion.toJson(),
      'mismatches': mismatches,
    };
  }
}

class CaptureGateBenchmarkRunner {
  const CaptureGateBenchmarkRunner({
    this.captureProfileVersion = 'nexeye-capture-v1',
  });

  final String captureProfileVersion;

  List<CaptureGateRecord> parseManifest(String rawJson) {
    final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
    return decoded
        .map(
          (dynamic item) =>
              CaptureGateRecord.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  CaptureGateBenchmarkReport run(List<CaptureGateRecord> records) {
    int truePositive = 0;
    int falsePositive = 0;
    int trueNegative = 0;
    int falseNegative = 0;
    int evaluatedRecordCount = 0;
    int pendingReviewCount = 0;
    int borderlineCount = 0;
    final List<String> mismatches = <String>[];

    for (final CaptureGateRecord record in records) {
      if (record.label == CaptureLabel.pendingReview) {
        pendingReviewCount += 1;
        continue;
      }
      if (record.label == CaptureLabel.borderline) {
        borderlineCount += 1;
        continue;
      }

      final bool predicted = record.score.diagnosticPass;
      final bool actual = record.label == CaptureLabel.accept;
      evaluatedRecordCount += 1;

      if (predicted && actual) {
        truePositive += 1;
      } else if (predicted && !actual) {
        falsePositive += 1;
        mismatches.add('${record.id}: predicted acceptable');
      } else if (!predicted && actual) {
        falseNegative += 1;
        mismatches.add('${record.id}: rejected acceptable capture');
      } else {
        trueNegative += 1;
      }
    }

    return CaptureGateBenchmarkReport(
      captureProfileVersion: captureProfileVersion,
      recordCount: records.length,
      evaluatedRecordCount: evaluatedRecordCount,
      pendingReviewCount: pendingReviewCount,
      borderlineCount: borderlineCount,
      confusion: CaptureGateConfusion(
        truePositive: truePositive,
        falsePositive: falsePositive,
        trueNegative: trueNegative,
        falseNegative: falseNegative,
      ),
      mismatches: mismatches,
    );
  }
}
