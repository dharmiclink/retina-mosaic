import 'package:nexthria_domain/nexthria_domain.dart';

import 'capture_export_models.dart';

class CaptureExporter {
  const CaptureExporter();

  Future<CaptureSessionExport> export(CaptureExportRequest request) async {
    return CaptureSessionExport(
      primaryDiagnosticJpegPath: 'web-preview/no-local-primary-diagnostic.jpg',
      mosaicJpegPath: 'web-preview/no-local-export.jpg',
      goldFramesArchivePath: 'web-preview/no-local-export.json',
      metadataJsonPath: 'web-preview/no-local-export.metadata.json',
      eyeLaterality: request.eyeLaterality,
      bestDiagnosticFrameId: request.bestDiagnosticFrame.goldFrame.frameId,
      bestDiagnosticScore: request.bestDiagnosticScore,
      diagnosticCapturePassed: request.diagnosticCapturePassed,
      selectionMode: request.selectionMode,
      autoSuggestedFrameId: request.autoSuggestedFrame?.goldFrame.frameId,
      finalSelectedFrameId: request.bestDiagnosticFrame.goldFrame.frameId,
      captureProfileVersion: request.captureProfileVersion,
    );
  }
}
