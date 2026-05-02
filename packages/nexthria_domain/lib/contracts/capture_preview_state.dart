import '../models/eye_laterality.dart';
import '../models/guidance_stage.dart';
import '../models/guidance_vector.dart';
import '../models/mosaic_update.dart';
import '../models/selection_mode.dart';
import '../models/utility_score.dart';

class CapturePreviewState {
  const CapturePreviewState({
    required this.sessionId,
    required this.eyeLaterality,
    required this.utilityScore,
    required this.guidanceVector,
    required this.mosaicUpdate,
    required this.bucketSize,
    required this.qualityLabel,
    required this.processingActive,
    this.bestDiagnosticFrameId,
    this.bestDiagnosticScore = 0,
    this.diagnosticCapturePassed = false,
    this.captureLocked = false,
    this.rejectionReasons = const <String>[],
    this.guidanceStage = GuidanceStage.findReflex,
    this.selectionMode = SelectionMode.auto,
    this.autoSuggestedFrameId,
  });

  final String sessionId;
  final EyeLaterality eyeLaterality;
  final UtilityScore utilityScore;
  final GuidanceVector guidanceVector;
  final MosaicUpdate mosaicUpdate;
  final int bucketSize;
  final String qualityLabel;
  final bool processingActive;
  final String? bestDiagnosticFrameId;
  final double bestDiagnosticScore;
  final bool diagnosticCapturePassed;
  final bool captureLocked;
  final List<String> rejectionReasons;
  final GuidanceStage guidanceStage;
  final SelectionMode selectionMode;
  final String? autoSuggestedFrameId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'eyeLaterality': eyeLaterality.name,
      'utilityScore': utilityScore.toJson(),
      'guidanceVector': guidanceVector.toJson(),
      'mosaicUpdate': mosaicUpdate.toJson(),
      'bucketSize': bucketSize,
      'qualityLabel': qualityLabel,
      'processingActive': processingActive,
      'bestDiagnosticFrameId': bestDiagnosticFrameId,
      'bestDiagnosticScore': bestDiagnosticScore,
      'diagnosticCapturePassed': diagnosticCapturePassed,
      'captureLocked': captureLocked,
      'rejectionReasons': rejectionReasons,
      'guidanceStage': guidanceStage.name,
      'selectionMode': selectionMode.name,
      'autoSuggestedFrameId': autoSuggestedFrameId,
    };
  }

  factory CapturePreviewState.fromJson(Map<String, dynamic> json) {
    return CapturePreviewState(
      sessionId: json['sessionId'] as String? ?? 'phase0-session',
      eyeLaterality: EyeLaterality.values.firstWhere(
        (EyeLaterality value) =>
            value.name == (json['eyeLaterality'] as String? ?? ''),
        orElse: () => EyeLaterality.unknown,
      ),
      utilityScore: UtilityScore.fromJson(
        json['utilityScore'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      guidanceVector: GuidanceVector.fromJson(
        json['guidanceVector'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      mosaicUpdate: MosaicUpdate.fromJson(
        json['mosaicUpdate'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      bucketSize: json['bucketSize'] as int? ?? 0,
      qualityLabel: json['qualityLabel'] as String? ?? 'Initializing',
      processingActive: json['processingActive'] as bool? ?? false,
      bestDiagnosticFrameId: json['bestDiagnosticFrameId'] as String?,
      bestDiagnosticScore:
          (json['bestDiagnosticScore'] as num?)?.toDouble() ?? 0,
      diagnosticCapturePassed:
          json['diagnosticCapturePassed'] as bool? ?? false,
      captureLocked: json['captureLocked'] as bool? ?? false,
      rejectionReasons:
          (json['rejectionReasons'] as List<dynamic>? ?? const <dynamic>[])
              .map((dynamic value) => value.toString())
              .toList(growable: false),
      guidanceStage: GuidanceStage.values.firstWhere(
        (GuidanceStage value) =>
            value.name == (json['guidanceStage'] as String? ?? ''),
        orElse: () => GuidanceStage.findReflex,
      ),
      selectionMode: SelectionMode.values.firstWhere(
        (SelectionMode value) =>
            value.name == (json['selectionMode'] as String? ?? ''),
        orElse: () => SelectionMode.auto,
      ),
      autoSuggestedFrameId: json['autoSuggestedFrameId'] as String?,
    );
  }
}
