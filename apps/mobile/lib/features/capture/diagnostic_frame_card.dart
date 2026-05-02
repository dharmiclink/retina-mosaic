import 'package:flutter/material.dart';
import 'package:nexthria_ui/nexthria_ui.dart';

import 'gold_frame_bucket.dart';

class DiagnosticFrameCard extends StatelessWidget {
  const DiagnosticFrameCard({
    super.key,
    required this.bestDiagnosticFrame,
    required this.suggestedDiagnosticFrame,
    required this.candidateFrames,
    required this.diagnosticPassed,
    required this.bestDiagnosticScore,
    required this.selectionReason,
    required this.mirrorHorizontally,
    required this.isManualOverride,
    required this.onSelectCandidate,
    required this.onUseAutoSelection,
    this.fallbackAssetPath,
  });

  final RetainedGoldFrame? bestDiagnosticFrame;
  final RetainedGoldFrame? suggestedDiagnosticFrame;
  final List<RetainedGoldFrame> candidateFrames;
  final bool diagnosticPassed;
  final double bestDiagnosticScore;
  final String selectionReason;
  final bool mirrorHorizontally;
  final bool isManualOverride;
  final ValueChanged<String> onSelectCandidate;
  final VoidCallback onUseAutoSelection;
  final String? fallbackAssetPath;

  @override
  Widget build(BuildContext context) {
    final RetainedGoldFrame? frame = bestDiagnosticFrame;

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Primary Diagnostic Frame',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: NexthriaTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.15,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFF14202D)),
                child: frame != null
                    ? CustomPaint(
                        painter: _SamplePainter(
                          frame: frame,
                          mirrorHorizontally: mirrorHorizontally,
                        ),
                      )
                    : fallbackAssetPath != null && diagnosticPassed
                    ? Transform.flip(
                        flipX: mirrorHorizontally,
                        child: Image.asset(
                          fallbackAssetPath!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Waiting for a NexEye-grade frame lock',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: NexthriaTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              InfoChip(
                label: 'Status',
                value: diagnosticPassed ? 'Locked' : 'Pending',
                color: diagnosticPassed
                    ? const Color(0xFF34C6A0)
                    : const Color(0xFFF26A5D),
              ),
              InfoChip(
                label: 'Score',
                value: bestDiagnosticScore.toStringAsFixed(2),
                color: const Color(0xFF17B7E5),
              ),
              InfoChip(
                label: 'Frame',
                value: frame?.goldFrame.frameId ?? 'Not yet selected',
                color: const Color(0xFF6C8DFF),
              ),
              InfoChip(
                label: 'Mode',
                value: isManualOverride ? 'Manual' : 'Auto',
                color: isManualOverride
                    ? const Color(0xFFF3A63D)
                    : const Color(0xFF9A7DFF),
              ),
            ],
          ),
          if (isManualOverride &&
              suggestedDiagnosticFrame != null &&
              bestDiagnosticFrame != null &&
              suggestedDiagnosticFrame!.goldFrame.frameId !=
                  bestDiagnosticFrame!.goldFrame.frameId) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'Manual override active. Auto-best suggested '
              '${suggestedDiagnosticFrame!.goldFrame.frameId}, but the final export will use '
              '${bestDiagnosticFrame!.goldFrame.frameId}.',
              style: const TextStyle(
                color: NexthriaTheme.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          if (isManualOverride && suggestedDiagnosticFrame != null) ...<Widget>[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onUseAutoSelection,
              icon: const Icon(Icons.auto_fix_high_outlined),
              label: Text(
                'Use Auto Best (${suggestedDiagnosticFrame!.goldFrame.frameId})',
              ),
            ),
          ],
          if (candidateFrames.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            const Text(
              'Compare Candidates',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: NexthriaTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (BuildContext context, int index) {
                  final RetainedGoldFrame candidate = candidateFrames[index];
                  final bool isSelected =
                      candidate.goldFrame.frameId ==
                      bestDiagnosticFrame?.goldFrame.frameId;
                  return _CandidateTile(
                    frame: candidate,
                    mirrorHorizontally: mirrorHorizontally,
                    isSelected: isSelected,
                    onTap: () => onSelectCandidate(candidate.goldFrame.frameId),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemCount: candidateFrames.length,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            selectionReason,
            style: const TextStyle(
              color: NexthriaTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.frame,
    required this.mirrorHorizontally,
    required this.isSelected,
    required this.onTap,
  });

  final RetainedGoldFrame frame;
  final bool mirrorHorizontally;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: isSelected
                    ? NexthriaTheme.emerald
                    : Colors.white.withValues(alpha: 0.08),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomPaint(
                        painter: _SamplePainter(
                          frame: frame,
                          mirrorHorizontally: mirrorHorizontally,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    frame.goldFrame.frameId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: NexthriaTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'DQ ${frame.goldFrame.utilityScore.diagnosticQuality.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: NexthriaTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SamplePainter extends CustomPainter {
  const _SamplePainter({required this.frame, required this.mirrorHorizontally});

  final RetainedGoldFrame frame;
  final bool mirrorHorizontally;

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / frame.sample.width;
    final double cellHeight = size.height / frame.sample.height;

    for (int y = 0; y < frame.sample.height; y += 1) {
      for (int x = 0; x < frame.sample.width; x += 1) {
        final int sourceX = mirrorHorizontally ? frame.sample.width - 1 - x : x;
        final double intensity = frame.sample.at(sourceX, y) / 255.0;
        final Rect cell = Rect.fromLTWH(
          x * cellWidth,
          y * cellHeight,
          cellWidth + 0.2,
          cellHeight + 0.2,
        );
        final Paint paint = Paint()
          ..color = Color.lerp(
            const Color(0xFF180C08),
            const Color(0xFFFFC78A),
            intensity.clamp(0.0, 1.0),
          )!;
        canvas.drawRect(cell, paint);
      }
    }

    final Paint vignette = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.transparent,
          const Color(0xFF06090E).withValues(alpha: 0.18),
          const Color(0xFF04070B).withValues(alpha: 0.68),
        ],
        stops: const <double>[0.52, 0.82, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);

    final Paint framePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
        const Radius.circular(18),
      ),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SamplePainter oldDelegate) {
    return oldDelegate.frame != frame ||
        oldDelegate.mirrorHorizontally != mirrorHorizontally;
  }
}
