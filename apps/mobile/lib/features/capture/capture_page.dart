import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexthria_domain/nexthria_domain.dart';
import 'package:nexthria_ui/nexthria_ui.dart';

import '../export/export_summary_card.dart';
import '../guidance/guidance_overlay.dart';
import '../mosaic/mosaic_preview.dart';
import 'capture_controller.dart';
import 'diagnostic_frame_card.dart';
import 'live_camera_surface.dart';
import 'mock_fundus_live_view.dart';

class CapturePage extends StatefulWidget {
  const CapturePage({super.key});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  late final CaptureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CaptureController()..addListener(_onChanged);
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    unawaited(_controller.shutdown());
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final CapturePreviewState preview = _controller.previewState;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const _CaptureBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool singleColumn = constraints.maxWidth < 960;

                  final Widget livePanel = PanelCard(
                    backgroundColor: const Color(0x991E293B),
                    padding: const EdgeInsets.all(0),
                    child: SizedBox(
                      height: singleColumn ? 380 : 520,
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child:
                                _controller.inputMode ==
                                        CaptureInputMode.live &&
                                    _controller.cameraController != null &&
                                    _controller.isLiveCameraReady
                                ? LiveCameraSurface(
                                    controller: _controller.cameraController!,
                                    processingActive: preview.processingActive,
                                  )
                                : MockFundusLiveView(
                                    assetPath: _controller.liveAssetPath,
                                    alignment:
                                        _controller.currentMockStep.alignment,
                                    zoom: _controller.currentMockStep.zoom,
                                    mirrorHorizontally:
                                        _controller.mirrorHorizontally,
                                    processingActive: preview.processingActive,
                                  ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    Colors.transparent,
                                    NexthriaTheme.bg.withValues(alpha: 0.08),
                                    NexthriaTheme.bg.withValues(alpha: 0.22),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_controller.inputMode == CaptureInputMode.live &&
                              !_controller.isLiveCameraReady)
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: const Color(0xAA04070B),
                                ),
                                child: Center(
                                  child: Text(
                                    _controller.cameraStatusMessage,
                                    style: const TextStyle(
                                      color: NexthriaTheme.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: GuidanceOverlay(
                                  guidanceVector: preview.guidanceVector,
                                  processingActive: preview.processingActive,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 18,
                            top: 18,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: NexthriaTheme.bg.withValues(alpha: 0.62),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                'Live Fundus Guidance',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: NexthriaTheme.textPrimary,
                                      fontSize: 13,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  final Widget rightColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      PanelCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const _SectionHeading(
                              title: 'Context Mosaic',
                              subtitle:
                                  'Secondary operator context after the primary NexEye diagnostic frame is secured.',
                            ),
                            const SizedBox(height: 12),
                            MosaicPreview(
                              mosaicUpdate: preview.mosaicUpdate,
                              coverageGrid: _controller.liveCoverageGrid,
                              mosaicIntensityGrid:
                                  _controller.liveMosaicIntensityGrid,
                              mosaicResolution:
                                  _controller.liveMosaicResolution,
                              imageAssetPath:
                                  _controller.inputMode == CaptureInputMode.mock
                                  ? _controller.liveAssetPath
                                  : null,
                              mirrorHorizontally:
                                  _controller.mirrorHorizontally,
                            ),
                            const SizedBox(height: 16),
                            StatusMeter(
                              label: 'Coverage',
                              value: preview.mosaicUpdate.coveragePercent / 100,
                              color: NexthriaTheme.emerald,
                            ),
                            const SizedBox(height: 12),
                            StatusMeter(
                              label: 'Mean Confidence',
                              value: preview
                                  .mosaicUpdate
                                  .confidenceSummary
                                  .meanConfidence,
                              color: NexthriaTheme.cyan,
                            ),
                            const SizedBox(height: 16),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white.withValues(alpha: 0.04),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: <Widget>[
                                    InfoChip(
                                      label: 'Alignment',
                                      value:
                                          '${(_controller.latestAlignmentConfidence * 100).round()}%',
                                      color: const Color(0xFF6C8DFF),
                                    ),
                                    InfoChip(
                                      label: 'Matches',
                                      value: _controller.latestMatchCount
                                          .toString(),
                                      color: NexthriaTheme.cyan,
                                    ),
                                    InfoChip(
                                      label: 'Anchor KP',
                                      value: _controller.latestAnchorKeypoints
                                          .toString(),
                                      color: NexthriaTheme.emerald,
                                    ),
                                    InfoChip(
                                      label: 'Current KP',
                                      value: _controller.latestCurrentKeypoints
                                          .toString(),
                                      color: NexthriaTheme.amber,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      DiagnosticFrameCard(
                        bestDiagnosticFrame: _controller.bestDiagnosticFrame,
                        suggestedDiagnosticFrame:
                            _controller.suggestedDiagnosticFrame,
                        candidateFrames: _controller.topDiagnosticFrames,
                        diagnosticPassed: preview.diagnosticCapturePassed,
                        bestDiagnosticScore: preview.bestDiagnosticScore,
                        selectionReason:
                            _controller.bestDiagnosticSelectionReason,
                        mirrorHorizontally: _controller.mirrorHorizontally,
                        isManualOverride:
                            _controller.isManualDiagnosticOverride,
                        onSelectCandidate:
                            _controller.selectDiagnosticCandidate,
                        onUseAutoSelection:
                            _controller.useAutoDiagnosticSelection,
                        fallbackAssetPath:
                            _controller.inputMode == CaptureInputMode.mock
                            ? _controller.liveAssetPath
                            : null,
                      ),
                      const SizedBox(height: 16),
                      ExportSummaryCard(
                        exportPayload: _controller.exportPayload,
                        coveragePercent: preview.mosaicUpdate.coveragePercent,
                        retainedFrameCount: preview.bucketSize,
                        exportReady: _controller.canExport,
                        diagnosticPassed: preview.diagnosticCapturePassed,
                        bestDiagnosticScore: preview.bestDiagnosticScore,
                      ),
                    ],
                  );

                  final Widget controls = PanelCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const _CaptureHeader(),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            InfoChip(
                              label: 'Session',
                              value: preview.sessionId,
                              color: NexthriaTheme.cyan,
                            ),
                            InfoChip(
                              label: 'Diagnostic',
                              value: preview.diagnosticCapturePassed
                                  ? 'Locked'
                                  : 'Pending',
                              color: preview.diagnosticCapturePassed
                                  ? NexthriaTheme.emerald
                                  : NexthriaTheme.coral,
                            ),
                            InfoChip(
                              label: 'Best Frame',
                              value: preview.bestDiagnosticFrameId ?? 'None',
                              color: NexthriaTheme.blue,
                            ),
                            InfoChip(
                              label: 'Eye',
                              value: preview.eyeLaterality.label,
                              color: const Color(0xFFE879F9),
                            ),
                            InfoChip(
                              label: 'Input',
                              value:
                                  _controller.inputMode == CaptureInputMode.live
                                  ? 'Live camera'
                                  : 'Mock fundus',
                              color: const Color(0xFF818CF8),
                            ),
                            InfoChip(
                              label: 'Status',
                              value: preview.qualityLabel,
                              color: NexthriaTheme.amber,
                            ),
                            InfoChip(
                              label: 'Guidance',
                              value: preview.guidanceStage.name,
                              color: const Color(0xFF60A5FA),
                            ),
                            InfoChip(
                              label: 'Selection',
                              value: preview.selectionMode.name,
                              color: const Color(0xFFA78BFA),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        if (_controller.canUseLiveInput) ...<Widget>[
                          const _SectionHeading(
                            title: 'Capture Source',
                            subtitle:
                                'Switch between real camera input and a bundled demo fundus sequence.',
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<CaptureInputMode>(
                            segments: const <ButtonSegment<CaptureInputMode>>[
                              ButtonSegment<CaptureInputMode>(
                                value: CaptureInputMode.live,
                                label: Text('Live'),
                                icon: Icon(Icons.videocam_outlined),
                              ),
                              ButtonSegment<CaptureInputMode>(
                                value: CaptureInputMode.mock,
                                label: Text('Mock'),
                                icon: Icon(Icons.science_outlined),
                              ),
                            ],
                            selected: <CaptureInputMode>{_controller.inputMode},
                            onSelectionChanged:
                                (Set<CaptureInputMode> nextSelection) {
                                  _controller.setInputMode(nextSelection.first);
                                },
                          ),
                          const SizedBox(height: 18),
                        ],
                        const _SectionHeading(
                          title: 'Eye Selection',
                          subtitle:
                              'Laterality is carried into export so NexEye receives correct eye context.',
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<EyeLaterality>(
                          segments: const <ButtonSegment<EyeLaterality>>[
                            ButtonSegment<EyeLaterality>(
                              value: EyeLaterality.right,
                              label: Text('Right Eye'),
                              icon: Icon(Icons.visibility_outlined),
                            ),
                            ButtonSegment<EyeLaterality>(
                              value: EyeLaterality.left,
                              label: Text('Left Eye'),
                              icon: Icon(Icons.visibility),
                            ),
                          ],
                          selected: <EyeLaterality>{
                            _controller.selectedEyeLaterality,
                          },
                          onSelectionChanged:
                              (Set<EyeLaterality> nextSelection) {
                                _controller.setEyeLaterality(
                                  nextSelection.first,
                                );
                              },
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _controller.cameraStatusMessage,
                          style: const TextStyle(
                            color: NexthriaTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _SectionHeading(
                          title: 'Capture Gate',
                          subtitle:
                              'Primary objective is one NexEye-grade diagnostic frame. Mosaic utility is secondary.',
                        ),
                        const SizedBox(height: 12),
                        StatusMeter(
                          label: 'Diagnostic Quality',
                          value: preview.utilityScore.diagnosticQuality,
                          color: preview.utilityScore.diagnosticPass
                              ? NexthriaTheme.emerald
                              : NexthriaTheme.coral,
                        ),
                        const SizedBox(height: 12),
                        StatusMeter(
                          label: 'Mosaic Utility',
                          value: preview.utilityScore.mosaicUtility,
                          color: preview.utilityScore.retainForMosaic
                              ? NexthriaTheme.blue
                              : NexthriaTheme.amber,
                        ),
                        if (preview.rejectionReasons.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 18),
                          const _SectionHeading(
                            title: 'Capture Coaching',
                            subtitle:
                                'These are the current reasons a frame is being rejected from primary diagnostic use.',
                          ),
                          const SizedBox(height: 8),
                          for (final String reason
                              in preview.rejectionReasons.take(3))
                            _CoachingBullet(reason: reason),
                        ],
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: _controller.isBusy
                                  ? null
                                  : _controller.startPainting,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Start Painting'),
                            ),
                            OutlinedButton.icon(
                              onPressed: preview.processingActive
                                  ? _controller.stopPainting
                                  : null,
                              icon: const Icon(Icons.stop_circle_outlined),
                              label: const Text('Stop'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _controller.canExport
                                  ? _controller.exportCapture
                                  : null,
                              icon: const Icon(Icons.file_download_outlined),
                              label: const Text('Export'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );

                  return ListView(
                    children: <Widget>[
                      controls,
                      const SizedBox(height: 16),
                      if (singleColumn) ...<Widget>[
                        livePanel,
                        const SizedBox(height: 16),
                        rightColumn,
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(flex: 6, child: livePanel),
                            const SizedBox(width: 16),
                            Expanded(flex: 5, child: rightColumn),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureBackground extends StatelessWidget {
  const _CaptureBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: NexthriaTheme.bg),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -120,
            left: -80,
            child: _GlowOrb(
              diameter: 280,
              color: NexthriaTheme.cyan,
              opacity: 0.12,
            ),
          ),
          Positioned(
            top: 140,
            right: -110,
            child: _GlowOrb(
              diameter: 320,
              color: NexthriaTheme.blue,
              opacity: 0.12,
            ),
          ),
          Positioned(
            bottom: -120,
            left: 120,
            child: _GlowOrb(
              diameter: 300,
              color: NexthriaTheme.indigo,
              opacity: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.diameter,
    required this.color,
    required this.opacity,
  });

  final double diameter;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: opacity * 1.4),
              blurRadius: diameter * 0.42,
              spreadRadius: diameter * 0.08,
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureHeader extends StatelessWidget {
  const _CaptureHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const BrandMark(size: 56),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'NexEye Capture Coach',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Same NexEye visual language, but focused on guided acquisition of one diagnostic-grade fundus frame for downstream AI analysis.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CoachingBullet extends StatelessWidget {
  const _CoachingBullet({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: NexthriaTheme.cyan,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                color: NexthriaTheme.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
