import 'eye_laterality.dart';
import 'selection_mode.dart';

class CaptureSessionExport {
  const CaptureSessionExport({
    required this.primaryDiagnosticJpegPath,
    required this.mosaicJpegPath,
    required this.goldFramesArchivePath,
    required this.metadataJsonPath,
    required this.eyeLaterality,
    this.bestDiagnosticFrameId,
    this.bestDiagnosticScore = 0,
    this.diagnosticCapturePassed = false,
    this.selectionMode = SelectionMode.auto,
    this.autoSuggestedFrameId,
    this.finalSelectedFrameId,
    this.captureProfileVersion = 'nexeye-capture-v1',
  });

  final String primaryDiagnosticJpegPath;
  final String mosaicJpegPath;
  final String goldFramesArchivePath;
  final String metadataJsonPath;
  final EyeLaterality eyeLaterality;
  final String? bestDiagnosticFrameId;
  final double bestDiagnosticScore;
  final bool diagnosticCapturePassed;
  final SelectionMode selectionMode;
  final String? autoSuggestedFrameId;
  final String? finalSelectedFrameId;
  final String captureProfileVersion;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'primaryDiagnosticJpegPath': primaryDiagnosticJpegPath,
      'mosaicJpegPath': mosaicJpegPath,
      'goldFramesArchivePath': goldFramesArchivePath,
      'metadataJsonPath': metadataJsonPath,
      'eyeLaterality': eyeLaterality.name,
      'bestDiagnosticFrameId': bestDiagnosticFrameId,
      'bestDiagnosticScore': bestDiagnosticScore,
      'diagnosticCapturePassed': diagnosticCapturePassed,
      'selectionMode': selectionMode.name,
      'autoSuggestedFrameId': autoSuggestedFrameId,
      'finalSelectedFrameId': finalSelectedFrameId,
      'captureProfileVersion': captureProfileVersion,
    };
  }

  factory CaptureSessionExport.fromJson(Map<String, dynamic> json) {
    return CaptureSessionExport(
      primaryDiagnosticJpegPath:
          json['primaryDiagnosticJpegPath'] as String? ??
          (json['mosaicJpegPath'] as String? ?? ''),
      mosaicJpegPath: json['mosaicJpegPath'] as String? ?? '',
      goldFramesArchivePath: json['goldFramesArchivePath'] as String? ?? '',
      metadataJsonPath: json['metadataJsonPath'] as String? ?? '',
      eyeLaterality: EyeLaterality.values.firstWhere(
        (EyeLaterality value) =>
            value.name == (json['eyeLaterality'] as String? ?? ''),
        orElse: () => EyeLaterality.unknown,
      ),
      bestDiagnosticFrameId: json['bestDiagnosticFrameId'] as String?,
      bestDiagnosticScore:
          (json['bestDiagnosticScore'] as num?)?.toDouble() ?? 0,
      diagnosticCapturePassed:
          json['diagnosticCapturePassed'] as bool? ?? false,
      selectionMode: SelectionMode.values.firstWhere(
        (SelectionMode value) =>
            value.name == (json['selectionMode'] as String? ?? ''),
        orElse: () => SelectionMode.auto,
      ),
      autoSuggestedFrameId: json['autoSuggestedFrameId'] as String?,
      finalSelectedFrameId:
          json['finalSelectedFrameId'] as String? ??
          json['bestDiagnosticFrameId'] as String?,
      captureProfileVersion:
          json['captureProfileVersion'] as String? ?? 'nexeye-capture-v1',
    );
  }
}
