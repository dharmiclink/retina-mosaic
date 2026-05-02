import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:nexthria_domain/nexthria_domain.dart';

import '../capture/gold_frame_bucket.dart';
import 'capture_export_models.dart';

class CaptureExporter {
  const CaptureExporter();

  Future<CaptureSessionExport> export(CaptureExportRequest request) async {
    final Directory root = await Directory.systemTemp.createTemp(
      'nexthria_export_${request.sessionId}_',
    );
    final Directory framesDir = Directory('${root.path}/gold_frames');
    await framesDir.create(recursive: true);

    final File mosaicFile = File('${root.path}/mosaic.jpg');
    final File primaryDiagnosticFile = File(
      '${root.path}/primary_diagnostic.jpg',
    );
    final File metadataFile = File('${root.path}/metadata.json');
    final File retainedFramesFile = File('${root.path}/gold_frames.json');

    final img.Image mosaicImage = img.Image(
      width: request.mosaicResolution,
      height: request.mosaicResolution,
    );
    for (int y = 0; y < request.mosaicResolution; y += 1) {
      for (int x = 0; x < request.mosaicResolution; x += 1) {
        final double intensity =
            request.mosaicIntensityGrid[(y * request.mosaicResolution) + x];
        final int value = (intensity.clamp(0.0, 1.0) * 255).round();
        mosaicImage.setPixelRgb(
          x,
          y,
          value,
          (value * 0.74).round(),
          (value * 0.46).round(),
        );
      }
    }
    await mosaicFile.writeAsBytes(img.encodeJpg(mosaicImage, quality: 92));

    final List<Map<String, dynamic>> retainedFrameEntries =
        <Map<String, dynamic>>[];
    String bestDiagnosticFramePath = '';
    for (final RetainedGoldFrame retainedFrame in request.retainedFrames) {
      final File frameFile = File(
        '${framesDir.path}/${retainedFrame.goldFrame.frameId}.jpg',
      );
      final img.Image frameImage = img.Image(
        width: retainedFrame.sample.width,
        height: retainedFrame.sample.height,
      );

      for (int y = 0; y < retainedFrame.sample.height; y += 1) {
        for (int x = 0; x < retainedFrame.sample.width; x += 1) {
          final int value = retainedFrame.sample
              .at(x, y)
              .round()
              .clamp(0, 255)
              .toInt();
          frameImage.setPixelRgb(
            x,
            y,
            value,
            (value * 0.74).round(),
            (value * 0.46).round(),
          );
        }
      }

      await frameFile.writeAsBytes(img.encodeJpg(frameImage, quality: 88));
      if (retainedFrame.goldFrame.frameId ==
          request.bestDiagnosticFrame.goldFrame.frameId) {
        bestDiagnosticFramePath = frameFile.path;
        await primaryDiagnosticFile.writeAsBytes(
          img.encodeJpg(frameImage, quality: 92),
        );
      }
      retainedFrameEntries.add(<String, dynamic>{
        'goldFrame': retainedFrame.goldFrame.toJson(),
        'frameEnvelope': retainedFrame.frameEnvelope.toJson(),
        'canvasTransform': retainedFrame.canvasTransform,
        'canvasOffset': <double>[
          retainedFrame.canvasOffset.dx,
          retainedFrame.canvasOffset.dy,
        ],
        'alignmentConfidence': retainedFrame.alignmentConfidence,
        'retainedFramePath': frameFile.path,
      });
    }

    await retainedFramesFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(retainedFrameEntries),
    );

    await metadataFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'sessionId': request.sessionId,
        'eyeLaterality': request.eyeLaterality.name,
        'diagnosticCapturePassed': request.diagnosticCapturePassed,
        'selectionMode': request.selectionMode.name,
        'autoSuggestedFrameId': request.autoSuggestedFrame?.goldFrame.frameId,
        'finalSelectedFrameId': request.bestDiagnosticFrame.goldFrame.frameId,
        'bestDiagnosticFrameId': request.bestDiagnosticFrame.goldFrame.frameId,
        'bestDiagnosticScore': request.bestDiagnosticScore,
        'bestDiagnosticFramePath': bestDiagnosticFramePath,
        'selectionReason': request.selectionReason,
        'captureProfileVersion': request.captureProfileVersion,
        'coveragePercent': request.coveragePercent,
        'retainedFrameCount': request.retainedFrames.length,
        'primaryDiagnosticPath': primaryDiagnosticFile.path,
        'mosaicPath': mosaicFile.path,
      }),
    );

    return CaptureSessionExport(
      primaryDiagnosticJpegPath: primaryDiagnosticFile.path,
      mosaicJpegPath: mosaicFile.path,
      goldFramesArchivePath: retainedFramesFile.path,
      metadataJsonPath: metadataFile.path,
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
