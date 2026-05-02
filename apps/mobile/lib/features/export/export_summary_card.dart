import 'package:flutter/material.dart';
import 'package:nexthria_domain/nexthria_domain.dart';
import 'package:nexthria_ui/nexthria_ui.dart';

class ExportSummaryCard extends StatelessWidget {
  const ExportSummaryCard({
    super.key,
    required this.exportPayload,
    required this.coveragePercent,
    required this.retainedFrameCount,
    required this.exportReady,
    required this.diagnosticPassed,
    required this.bestDiagnosticScore,
  });

  final CaptureSessionExport? exportPayload;
  final double coveragePercent;
  final int retainedFrameCount;
  final bool exportReady;
  final bool diagnosticPassed;
  final double bestDiagnosticScore;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Export Bundle',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: NexthriaTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            exportPayload == null
                ? exportReady
                      ? 'Export is ready. The bundle will package the primary diagnostic frame, context mosaic, retained gold frames, and metadata manifest.'
                      : 'Export unlocks after capture stops and at least one NexEye-grade frame is locked.'
                : 'Latest package paths are ready for downstream NexEye ingestion and validation.',
            style: const TextStyle(color: NexthriaTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              InfoChip(
                label: 'Diagnostic',
                value: diagnosticPassed ? 'Locked' : 'Pending',
                color: diagnosticPassed
                    ? const Color(0xFF34C6A0)
                    : const Color(0xFFF26A5D),
              ),
              InfoChip(
                label: 'Export',
                value: exportReady ? 'Ready' : 'Blocked',
                color: exportReady
                    ? const Color(0xFF6C8DFF)
                    : const Color(0xFFF26A5D),
              ),
              InfoChip(
                label: 'Best Score',
                value: bestDiagnosticScore.toStringAsFixed(2),
                color: const Color(0xFF17B7E5),
              ),
              if (exportPayload != null)
                InfoChip(
                  label: 'Selection',
                  value: exportPayload!.selectionMode.name,
                  color: const Color(0xFF6C8DFF),
                ),
              InfoChip(
                label: 'Coverage',
                value: '${coveragePercent.toStringAsFixed(0)}%',
                color: const Color(0xFFF3A63D),
              ),
              InfoChip(
                label: 'Retained',
                value: '$retainedFrameCount frames',
                color: const Color(0xFF9A7DFF),
              ),
            ],
          ),
          if (exportPayload != null) ...<Widget>[
            const SizedBox(height: 18),
            _PathLine(label: 'Eye', path: exportPayload!.eyeLaterality.label),
            _PathLine(
              label: 'Profile',
              path: exportPayload!.captureProfileVersion,
            ),
            _PathLine(
              label: 'Primary Diagnostic',
              path: exportPayload!.primaryDiagnosticJpegPath,
            ),
            _PathLine(
              label: 'Context Mosaic',
              path: exportPayload!.mosaicJpegPath,
            ),
            _PathLine(
              label: 'Gold Frames',
              path: exportPayload!.goldFramesArchivePath,
            ),
            _PathLine(label: 'Metadata', path: exportPayload!.metadataJsonPath),
          ],
        ],
      ),
    );
  }
}

class _PathLine extends StatelessWidget {
  const _PathLine({required this.label, required this.path});

  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: NexthriaTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            path,
            style: const TextStyle(color: NexthriaTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
