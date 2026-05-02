import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:nexthria_cv/nexthria_cv.dart';
import 'package:nexthria_domain/nexthria_domain.dart';

import '../../shared/mock_scan_sequence.dart';
import '../../shared/sample_preview_state.dart';
import '../export/capture_exporter.dart';
import 'gold_frame_bucket.dart';
import 'live_frame_sampler.dart';
import 'live_mosaic_engine.dart';
import 'live_utility_scorer.dart';

enum CaptureInputMode { mock, live }

const String nexEyeCaptureProfileVersion = 'nexeye-capture-v1';

class CaptureController extends ChangeNotifier {
  CaptureController({NexthriaCvPlugin? plugin})
    : _plugin = plugin ?? NexthriaCvPlugin.instance,
      _scorer = const LiveUtilityScorer(),
      _exporter = const CaptureExporter(),
      _bucket = GoldFrameBucket(),
      _mosaicEngine = LiveMosaicEngine();

  final NexthriaCvPlugin _plugin;
  final LiveUtilityScorer _scorer;
  final CaptureExporter _exporter;
  final GoldFrameBucket _bucket;
  final LiveMosaicEngine _mosaicEngine;

  Timer? _pollTimer;
  String _sessionId = idlePreviewState.sessionId;
  int _mockStepIndex = 0;
  EyeLaterality _selectedEyeLaterality = EyeLaterality.right;
  CaptureInputMode _inputMode = CaptureInputMode.mock;
  CameraController? _cameraController;
  bool _isCameraInitializing = false;
  bool _isProcessingFrame = false;
  int _liveFrameCounter = 0;
  String _cameraStatusMessage = 'Mock scan ready';
  LiveMosaicSolution? _liveMosaicSolution;
  RetainedGoldFrame? _bestDiagnosticFrame;
  bool _manualDiagnosticOverride = false;

  CapturePreviewState _previewState = idlePreviewState;
  CapturePreviewState get previewState => _previewState;
  MockScanStep get currentMockStep => mockScanSequence[_mockStepIndex];
  String get liveAssetPath => mockFundusAssetPath;
  EyeLaterality get selectedEyeLaterality => _selectedEyeLaterality;
  bool get mirrorHorizontally => _selectedEyeLaterality == EyeLaterality.left;
  CaptureInputMode get inputMode => _inputMode;
  CameraController? get cameraController => _cameraController;
  bool get isLiveCameraReady => _cameraController?.value.isInitialized ?? false;
  bool get canUseLiveInput => isLiveCameraReady && !kIsWeb;
  String get cameraStatusMessage => _cameraStatusMessage;
  List<double>? get liveCoverageGrid => _liveMosaicSolution?.coverageGrid;
  List<double>? get liveMosaicIntensityGrid =>
      _liveMosaicSolution?.mosaicIntensityGrid;
  int? get liveMosaicResolution => _liveMosaicSolution?.mosaicResolution;
  double get latestAlignmentConfidence =>
      _liveMosaicSolution?.alignmentConfidence ?? 0;
  int get latestMatchCount => _liveMosaicSolution?.matchCount ?? 0;
  int get latestAnchorKeypoints => _liveMosaicSolution?.anchorKeypoints ?? 0;
  int get latestCurrentKeypoints => _liveMosaicSolution?.currentKeypoints ?? 0;
  RetainedGoldFrame? get bestDiagnosticFrame => _bestDiagnosticFrame;
  RetainedGoldFrame? get suggestedDiagnosticFrame =>
      _bucket.frames.isEmpty ? null : _bucket.frames.first;
  bool get isManualDiagnosticOverride => _manualDiagnosticOverride;
  SelectionMode get selectionMode =>
      _manualDiagnosticOverride ? SelectionMode.manual : SelectionMode.auto;
  String get bestDiagnosticSelectionReason {
    final RetainedGoldFrame? frame = _bestDiagnosticFrame;
    if (frame == null) {
      return 'The app is still coaching toward a NexEye-grade frame.';
    }
    return _selectionReasonForFrame(
      frame,
      manualOverride: _manualDiagnosticOverride,
    );
  }

  List<RetainedGoldFrame> get topDiagnosticFrames =>
      _bucket.frames.take(3).toList(growable: false);

  bool get canExport {
    if (_previewState.processingActive || isBusy) {
      return false;
    }
    if (_inputMode == CaptureInputMode.live) {
      return _bestDiagnosticFrame != null && _liveMosaicSolution != null;
    }
    return true;
  }

  CaptureSessionExport? exportPayload;
  bool isBusy = false;

  Future<void> initialize() async {
    if (kIsWeb) {
      _cameraStatusMessage = 'Web preview uses the mock scan path';
      notifyListeners();
      return;
    }
    if (_isCameraInitializing || isLiveCameraReady) {
      return;
    }

    _isCameraInitializing = true;
    _cameraStatusMessage = 'Initializing live camera';
    notifyListeners();

    try {
      final List<CameraDescription> cameras = await availableCameras();
      final CameraDescription selectedCamera = cameras.firstWhere(
        (CameraDescription camera) =>
            camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final ImageFormatGroup imageFormatGroup =
          defaultTargetPlatform == TargetPlatform.iOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.yuv420;

      final CameraController controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: imageFormatGroup,
      );

      await controller.initialize();
      _cameraController = controller;
      _inputMode = CaptureInputMode.live;
      _cameraStatusMessage = 'Live stream ready';
      _resetLivePipeline();
      _applyStandbyPreview('Live camera armed for utility scoring');
    } catch (_) {
      _inputMode = CaptureInputMode.mock;
      _cameraStatusMessage = 'Camera unavailable, using mock scan';
    } finally {
      _isCameraInitializing = false;
      notifyListeners();
    }
  }

  void setInputMode(CaptureInputMode value) {
    if (value == CaptureInputMode.live && !canUseLiveInput) {
      return;
    }
    if (_inputMode == value) {
      return;
    }

    _inputMode = value;
    exportPayload = null;
    if (value == CaptureInputMode.live) {
      _resetLivePipeline();
    }
    _applyStandbyPreview(
      value == CaptureInputMode.live
          ? 'Live camera armed for utility scoring'
          : 'Mock scan armed with demo fundus image',
    );
  }

  void setEyeLaterality(EyeLaterality value) {
    if (_selectedEyeLaterality == value) {
      return;
    }

    _selectedEyeLaterality = value;
    exportPayload = null;
    _applyStandbyPreview('Laterality set to ${value.label}');
  }

  void selectDiagnosticCandidate(String frameId) {
    RetainedGoldFrame? candidate;
    for (final RetainedGoldFrame frame in _bucket.frames) {
      if (frame.goldFrame.frameId == frameId) {
        candidate = frame;
        break;
      }
    }
    if (candidate == null) {
      return;
    }

    _bestDiagnosticFrame = candidate;
    _manualDiagnosticOverride = true;
    _cameraStatusMessage = 'Operator selected ${candidate.goldFrame.frameId}';
    _refreshPreviewSelectionState();
  }

  void useAutoDiagnosticSelection() {
    final RetainedGoldFrame? candidate = suggestedDiagnosticFrame;
    _manualDiagnosticOverride = false;
    _bestDiagnosticFrame = candidate;
    _cameraStatusMessage = candidate == null
        ? 'Auto-selection re-armed'
        : 'Auto-selection restored to ${candidate.goldFrame.frameId}';
    _refreshPreviewSelectionState();
  }

  Future<void> startPainting() async {
    if (isBusy || _previewState.processingActive) {
      return;
    }

    isBusy = true;
    notifyListeners();

    _sessionId = await _plugin.initializeSession(
      patientId: '${_inputMode.name}-${_selectedEyeLaterality.name}',
    );
    await _plugin.startStreamProcessing();

    if (_inputMode == CaptureInputMode.live && canUseLiveInput) {
      _resetLivePipeline();
      await _startLiveCapture();
    } else {
      _mockStepIndex = 0;
      _applyMockStep(processingActive: true);

      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(milliseconds: 850), (_) {
        if (_mockStepIndex >= mockScanSequence.length - 1) {
          unawaited(_completeCapture());
          return;
        }

        _mockStepIndex += 1;
        _applyMockStep(processingActive: true);
      });
    }

    isBusy = false;
    notifyListeners();
  }

  Future<void> stopPainting() async {
    _pollTimer?.cancel();
    await _stopLiveCapture();
    await _plugin.stopStreamProcessing();
    _setProcessingState(
      false,
      _inputMode == CaptureInputMode.live
          ? 'Live capture paused at ${previewState.mosaicUpdate.coveragePercent.toStringAsFixed(0)}% coverage'
          : 'Mock scan paused at ${previewState.mosaicUpdate.coveragePercent.toStringAsFixed(0)}% coverage',
    );
  }

  Future<void> exportCapture() async {
    if (!canExport) {
      return;
    }

    isBusy = true;
    _cameraStatusMessage = 'Packaging export bundle';
    notifyListeners();

    try {
      if (_inputMode == CaptureInputMode.live &&
          _liveMosaicSolution != null &&
          _bestDiagnosticFrame != null) {
        exportPayload = await _exporter.export(
          CaptureExportRequest(
            sessionId: _sessionId,
            eyeLaterality: _selectedEyeLaterality,
            retainedFrames: _bucket.frames,
            bestDiagnosticFrame: _bestDiagnosticFrame!,
            autoSuggestedFrame: suggestedDiagnosticFrame,
            bestDiagnosticScore:
                _bestDiagnosticFrame!.goldFrame.utilityScore.diagnosticQuality,
            diagnosticCapturePassed: true,
            selectionMode: selectionMode,
            selectionReason: _selectionReasonForFrame(
              _bestDiagnosticFrame!,
              manualOverride: _manualDiagnosticOverride,
            ),
            captureProfileVersion: nexEyeCaptureProfileVersion,
            mosaicIntensityGrid: _liveMosaicSolution!.mosaicIntensityGrid,
            mosaicResolution: _liveMosaicSolution!.mosaicResolution,
            coveragePercent: _liveMosaicSolution!.coveragePercent,
          ),
        );
        _cameraStatusMessage = 'Export bundle ready';
        return;
      }

      final CaptureSessionExport export = await _plugin.exportSession();
      exportPayload = CaptureSessionExport(
        primaryDiagnosticJpegPath: export.mosaicJpegPath,
        mosaicJpegPath: export.mosaicJpegPath,
        goldFramesArchivePath: export.goldFramesArchivePath,
        metadataJsonPath: export.metadataJsonPath,
        eyeLaterality: _selectedEyeLaterality,
        bestDiagnosticFrameId: _previewState.bestDiagnosticFrameId,
        bestDiagnosticScore: _previewState.bestDiagnosticScore,
        diagnosticCapturePassed: _previewState.diagnosticCapturePassed,
        selectionMode: _previewState.selectionMode,
        autoSuggestedFrameId: _previewState.autoSuggestedFrameId,
        finalSelectedFrameId: _previewState.bestDiagnosticFrameId,
        captureProfileVersion: nexEyeCaptureProfileVersion,
      );
      _cameraStatusMessage = 'Export bundle ready';
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _completeCapture() async {
    _pollTimer?.cancel();
    await _stopLiveCapture();
    await _plugin.stopStreamProcessing();
    _setProcessingState(
      false,
      _inputMode == CaptureInputMode.live
          ? (_bestDiagnosticFrame != null
                ? 'Diagnostic capture locked and context mosaic completed'
                : 'Live capture complete without diagnostic lock')
          : 'Mock scan complete: coverage target reached',
    );
  }

  void _resetLivePipeline() {
    _bucket.reset();
    _mosaicEngine.reset();
    _liveMosaicSolution = _mosaicEngine.snapshot();
    _liveFrameCounter = 0;
    _bestDiagnosticFrame = null;
    _manualDiagnosticOverride = false;
  }

  void _applyStandbyPreview(String qualityLabel) {
    if (_inputMode == CaptureInputMode.live) {
      _liveMosaicSolution ??= _mosaicEngine.snapshot();
      final LiveMosaicSolution mosaic = _liveMosaicSolution!;
      _previewState = CapturePreviewState(
        sessionId: _sessionId,
        eyeLaterality: _selectedEyeLaterality,
        utilityScore: const UtilityScore(
          sharpness: 0.24,
          glareRatio: 0.04,
          vascularContrast: 0.18,
          illumination: 0.3,
          posteriorPoleFraming: 0.2,
          stableFocus: 0.22,
          diagnosticQuality: 0.22,
          mosaicUtility: 0.21,
          rejectionReasons: <String>['Find pupil reflex and center fundus'],
        ),
        guidanceVector: _guidanceForLaterality(
          const GuidanceVector(
            direction: GuidanceDirection.center,
            magnitude: 0,
            instruction: 'Find reflex and center the posterior pole',
            confidence: 0.68,
          ),
        ),
        mosaicUpdate: MosaicUpdate(
          transform: mosaic.transform,
          coveragePercent: mosaic.coveragePercent,
          unresolvedHolesMask: 'mask://live/standby',
          confidenceSummary: mosaic.confidenceSummary,
        ),
        bucketSize: _bucket.size,
        qualityLabel: qualityLabel,
        processingActive: false,
        bestDiagnosticFrameId: _bestDiagnosticFrame?.goldFrame.frameId,
        bestDiagnosticScore:
            _bestDiagnosticFrame?.goldFrame.utilityScore.diagnosticQuality ?? 0,
        diagnosticCapturePassed: _bestDiagnosticFrame != null,
        captureLocked: _bestDiagnosticFrame != null,
        guidanceStage: _deriveGuidanceStage(
          score: const UtilityScore(
            sharpness: 0.24,
            glareRatio: 0.04,
            vascularContrast: 0.18,
            illumination: 0.3,
            posteriorPoleFraming: 0.2,
            stableFocus: 0.22,
            diagnosticQuality: 0.22,
            mosaicUtility: 0.21,
          ),
          processingActive: false,
          diagnosticPassed: _bestDiagnosticFrame != null,
        ),
        selectionMode: selectionMode,
        autoSuggestedFrameId: suggestedDiagnosticFrame?.goldFrame.frameId,
      );
      notifyListeners();
      return;
    }

    _applyMockStep(processingActive: false, qualityLabel: qualityLabel);
  }

  void _setProcessingState(bool processingActive, String qualityLabel) {
    _previewState = CapturePreviewState(
      sessionId: _previewState.sessionId,
      eyeLaterality: _previewState.eyeLaterality,
      utilityScore: _previewState.utilityScore,
      guidanceVector: _previewState.guidanceVector,
      mosaicUpdate: _previewState.mosaicUpdate,
      bucketSize: _previewState.bucketSize,
      qualityLabel: qualityLabel,
      processingActive: processingActive,
      bestDiagnosticFrameId: _previewState.bestDiagnosticFrameId,
      bestDiagnosticScore: _previewState.bestDiagnosticScore,
      diagnosticCapturePassed: _previewState.diagnosticCapturePassed,
      captureLocked: _previewState.captureLocked,
      rejectionReasons: _previewState.rejectionReasons,
      guidanceStage: _previewState.guidanceStage,
      selectionMode: _previewState.selectionMode,
      autoSuggestedFrameId: _previewState.autoSuggestedFrameId,
    );
    notifyListeners();
  }

  void _refreshPreviewSelectionState() {
    _previewState = CapturePreviewState(
      sessionId: _previewState.sessionId,
      eyeLaterality: _previewState.eyeLaterality,
      utilityScore: _previewState.utilityScore,
      guidanceVector: _previewState.guidanceVector,
      mosaicUpdate: _previewState.mosaicUpdate,
      bucketSize: _previewState.bucketSize,
      qualityLabel: _bestDiagnosticFrame == null
          ? _previewState.qualityLabel
          : (_manualDiagnosticOverride
                ? 'Operator override selected ${_bestDiagnosticFrame!.goldFrame.frameId}'
                : _previewState.qualityLabel),
      processingActive: _previewState.processingActive,
      bestDiagnosticFrameId: _bestDiagnosticFrame?.goldFrame.frameId,
      bestDiagnosticScore:
          _bestDiagnosticFrame?.goldFrame.utilityScore.diagnosticQuality ?? 0,
      diagnosticCapturePassed: _bestDiagnosticFrame != null,
      captureLocked: _bestDiagnosticFrame != null,
      rejectionReasons: _previewState.rejectionReasons,
      guidanceStage: _previewState.guidanceStage,
      selectionMode: selectionMode,
      autoSuggestedFrameId: suggestedDiagnosticFrame?.goldFrame.frameId,
    );
    notifyListeners();
  }

  void _applyMockStep({required bool processingActive, String? qualityLabel}) {
    final MockScanStep step = currentMockStep;
    final bool diagnosticPassed =
        step.utilityScore.diagnosticPass || step.utilityScore.keepFrame;
    _previewState = CapturePreviewState(
      sessionId: _sessionId,
      eyeLaterality: _selectedEyeLaterality,
      utilityScore: step.utilityScore,
      guidanceVector: _guidanceForLaterality(step.guidanceVector),
      mosaicUpdate: MosaicUpdate(
        transform: step.transform,
        coveragePercent: step.coveragePercent,
        unresolvedHolesMask: 'mask://mock/${step.sequenceNumber}',
        confidenceSummary: step.confidenceSummary,
      ),
      bucketSize: step.bucketSize,
      qualityLabel: qualityLabel ?? step.qualityLabel,
      processingActive: processingActive,
      bestDiagnosticFrameId: diagnosticPassed
          ? 'mock-${step.sequenceNumber}'
          : null,
      bestDiagnosticScore: step.utilityScore.diagnosticQuality > 0
          ? step.utilityScore.diagnosticQuality
          : step.utilityScore.weightedTotal,
      diagnosticCapturePassed: diagnosticPassed,
      captureLocked: diagnosticPassed,
      rejectionReasons: step.utilityScore.rejectionReasons,
      guidanceStage: processingActive
          ? (diagnosticPassed
                ? GuidanceStage.contextCapture
                : GuidanceStage.holdSteady)
          : (diagnosticPassed
                ? GuidanceStage.exportReady
                : GuidanceStage.findReflex),
      selectionMode: selectionMode,
      autoSuggestedFrameId: diagnosticPassed
          ? 'mock-${step.sequenceNumber}'
          : null,
    );
    notifyListeners();
  }

  Future<void> _startLiveCapture() async {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _inputMode = CaptureInputMode.mock;
      _cameraStatusMessage = 'Live camera failed, falling back to mock scan';
      _mockStepIndex = 0;
      _applyMockStep(processingActive: true);
      return;
    }

    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }

    final LiveMosaicSolution mosaic =
        _liveMosaicSolution ?? _mosaicEngine.snapshot();
    _previewState = CapturePreviewState(
      sessionId: _sessionId,
      eyeLaterality: _selectedEyeLaterality,
      utilityScore: const UtilityScore(
        sharpness: 0,
        glareRatio: 0,
        vascularContrast: 0,
        illumination: 0,
        posteriorPoleFraming: 0,
        stableFocus: 0,
        diagnosticQuality: 0,
        mosaicUtility: 0,
        rejectionReasons: <String>['Find reflex and center the posterior pole'],
      ),
      guidanceVector: _guidanceForLaterality(
        const GuidanceVector(
          direction: GuidanceDirection.center,
          magnitude: 0,
          instruction: 'Find reflex, center pole, then hold steady',
          confidence: 0.7,
        ),
      ),
      mosaicUpdate: MosaicUpdate(
        transform: mosaic.transform,
        coveragePercent: mosaic.coveragePercent,
        unresolvedHolesMask: 'mask://live/boot',
        confidenceSummary: mosaic.confidenceSummary,
      ),
      bucketSize: _bucket.size,
      qualityLabel: 'Live stream started: hunting for NexEye diagnostic frame',
      processingActive: true,
      bestDiagnosticFrameId: _bestDiagnosticFrame?.goldFrame.frameId,
      bestDiagnosticScore:
          _bestDiagnosticFrame?.goldFrame.utilityScore.diagnosticQuality ?? 0,
      diagnosticCapturePassed: _bestDiagnosticFrame != null,
      captureLocked: _bestDiagnosticFrame != null,
      guidanceStage: GuidanceStage.findReflex,
      selectionMode: selectionMode,
      autoSuggestedFrameId: suggestedDiagnosticFrame?.goldFrame.frameId,
    );
    notifyListeners();

    await controller.startImageStream(_processLiveFrame);
  }

  Future<void> _stopLiveCapture() async {
    final CameraController? controller = _cameraController;
    if (controller != null && controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
  }

  Future<void> _processLiveFrame(CameraImage image) async {
    if (!_previewState.processingActive || _isProcessingFrame) {
      return;
    }

    _liveFrameCounter += 1;
    if (_liveFrameCounter % 4 != 0) {
      return;
    }

    _isProcessingFrame = true;
    try {
      final FrameSample sample = FrameSample.fromCameraImage(image);
      final UtilityScore score = _scorer.scoreSample(sample);

      LiveMosaicSolution mosaic =
          _liveMosaicSolution ?? _mosaicEngine.snapshot();

      if (score.retainForMosaic) {
        final RetainedGoldFrame? anchor = _bucket.latestAccepted;
        mosaic = _mosaicEngine.ingest(
          sample: sample,
          utilityScore: score,
          anchor: anchor,
        );
        _liveMosaicSolution = mosaic;

        final FrameEnvelope envelope = FrameEnvelope(
          frameId: 'live-${_liveFrameCounter.toString().padLeft(5, '0')}',
          timestamp: DateTime.now(),
          width: image.width,
          height: image.height,
          pixelFormat: image.format.group.name,
        );

        final int keypointCount = sample.estimateKeypointCount();
        final RetainedGoldFrame retainedFrame = RetainedGoldFrame(
          goldFrame: GoldFrame(
            frameId: envelope.frameId,
            acceptedAt: envelope.timestamp,
            utilityScore: score,
            keypointCount: mosaic.currentKeypoints > 0
                ? mosaic.currentKeypoints
                : keypointCount,
            descriptorCount: mosaic.matchCount > 0
                ? mosaic.matchCount
                : keypointCount,
          ),
          frameEnvelope: envelope,
          sample: sample,
          canvasTransform: mosaic.transform,
          canvasOffset: mosaic.canvasOffset,
          alignmentConfidence: mosaic.alignmentConfidence,
          retainedFramePath: '',
        );
        _bucket.add(retainedFrame);
        if (!_manualDiagnosticOverride &&
            score.diagnosticPass &&
            _isBetterDiagnosticCandidate(retainedFrame)) {
          _bestDiagnosticFrame = retainedFrame;
        }
      }

      final GuidanceVector guidance = _buildLiveGuidance(
        score: score,
        mosaic: mosaic,
      );

      _previewState = CapturePreviewState(
        sessionId: _sessionId,
        eyeLaterality: _selectedEyeLaterality,
        utilityScore: score,
        guidanceVector: guidance,
        mosaicUpdate: MosaicUpdate(
          transform: mosaic.transform,
          coveragePercent: mosaic.coveragePercent,
          unresolvedHolesMask: 'mask://live/${_bucket.size}',
          confidenceSummary: mosaic.confidenceSummary,
        ),
        bucketSize: _bucket.size,
        qualityLabel: _qualityLabelForScore(
          score: score,
          alignmentConfidence: mosaic.alignmentConfidence,
        ),
        processingActive: true,
        bestDiagnosticFrameId: _bestDiagnosticFrame?.goldFrame.frameId,
        bestDiagnosticScore:
            _bestDiagnosticFrame?.goldFrame.utilityScore.diagnosticQuality ?? 0,
        diagnosticCapturePassed: _bestDiagnosticFrame != null,
        captureLocked: _bestDiagnosticFrame != null,
        rejectionReasons: score.rejectionReasons,
        guidanceStage: _deriveGuidanceStage(
          score: score,
          processingActive: true,
          diagnosticPassed: _bestDiagnosticFrame != null,
        ),
        selectionMode: selectionMode,
        autoSuggestedFrameId: suggestedDiagnosticFrame?.goldFrame.frameId,
      );
      notifyListeners();

      if (_bestDiagnosticFrame != null && mosaic.coveragePercent >= 70) {
        await _completeCapture();
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  GuidanceVector _buildLiveGuidance({
    required UtilityScore score,
    required LiveMosaicSolution mosaic,
  }) {
    if (_bestDiagnosticFrame != null) {
      final GuidanceVector vector = switch (mosaic.suggestedSweepDirection) {
        GuidanceDirection.left => const GuidanceVector(
          direction: GuidanceDirection.left,
          magnitude: 4,
          instruction: 'Diagnostic frame locked. Sweep left for context mosaic',
          confidence: 0.88,
        ),
        GuidanceDirection.right => const GuidanceVector(
          direction: GuidanceDirection.right,
          magnitude: 4,
          instruction:
              'Diagnostic frame locked. Sweep right to enrich context mosaic',
          confidence: 0.88,
        ),
        GuidanceDirection.up => const GuidanceVector(
          direction: GuidanceDirection.up,
          magnitude: 3,
          instruction: 'Diagnostic frame locked. Tilt up for superior context',
          confidence: 0.89,
        ),
        GuidanceDirection.down => const GuidanceVector(
          direction: GuidanceDirection.down,
          magnitude: 3,
          instruction:
              'Diagnostic frame locked. Sweep down to close inferior context',
          confidence: 0.89,
        ),
        GuidanceDirection.center ||
        GuidanceDirection.hold => const GuidanceVector(
          direction: GuidanceDirection.center,
          magnitude: 1,
          instruction: 'Diagnostic frame locked. Hold or stop capture',
          confidence: 0.9,
        ),
      };
      return _guidanceForLaterality(vector);
    }

    if (score.glareRatio > 0.18) {
      return _guidanceForLaterality(
        const GuidanceVector(
          direction: GuidanceDirection.hold,
          magnitude: 0,
          instruction: 'Reduce glare and re-enter the pupil reflex',
          confidence: 0.83,
        ),
      );
    }
    if (score.posteriorPoleFraming < 0.48) {
      return _guidanceForLaterality(
        const GuidanceVector(
          direction: GuidanceDirection.center,
          magnitude: 2,
          instruction: 'Center the posterior pole before capturing',
          confidence: 0.82,
        ),
      );
    }
    if (score.illumination < 0.48) {
      return _guidanceForLaterality(
        const GuidanceVector(
          direction: GuidanceDirection.center,
          magnitude: 0,
          instruction: 'Find the pupil reflex and re-center illumination',
          confidence: 0.79,
        ),
      );
    }
    if (score.sharpness < 0.42 || score.stableFocus < 0.44) {
      return _guidanceForLaterality(
        const GuidanceVector(
          direction: GuidanceDirection.hold,
          magnitude: 0,
          instruction: 'Hold steady for sharp vessel and disc detail',
          confidence: 0.81,
        ),
      );
    }
    if (score.vascularContrast < 0.34) {
      return _guidanceForLaterality(
        const GuidanceVector(
          direction: GuidanceDirection.center,
          magnitude: 0,
          instruction: 'Micro-adjust tilt to improve vessel contrast',
          confidence: 0.77,
        ),
      );
    }
    if (score.diagnosticPass) {
      return _guidanceForLaterality(
        const GuidanceVector(
          direction: GuidanceDirection.hold,
          magnitude: 0,
          instruction: 'Capture locked. NexEye-grade frame acquired',
          confidence: 0.94,
        ),
      );
    }
    return _guidanceForLaterality(
      const GuidanceVector(
        direction: GuidanceDirection.hold,
        magnitude: 0,
        instruction: 'Hold steady. Hunting for NexEye diagnostic frame',
        confidence: 0.86,
      ),
    );
  }

  String _qualityLabelForScore({
    required UtilityScore score,
    required double alignmentConfidence,
  }) {
    if (score.diagnosticPass) {
      return 'Diagnostic frame locked for NexEye';
    }
    if (score.retainForMosaic) {
      if (alignmentConfidence < 0.45) {
        return 'Context frame retained with weak alignment confidence';
      }
      return 'Context frame retained while hunting diagnostic lock';
    }
    if (score.rejectionReasons.isNotEmpty) {
      return 'Rejected: ${score.rejectionReasons.first}';
    }
    return 'Rejected: insufficient diagnostic quality';
  }

  GuidanceStage _deriveGuidanceStage({
    required UtilityScore score,
    required bool processingActive,
    required bool diagnosticPassed,
  }) {
    if (!processingActive) {
      return diagnosticPassed
          ? GuidanceStage.exportReady
          : GuidanceStage.findReflex;
    }
    if (diagnosticPassed) {
      return GuidanceStage.contextCapture;
    }
    if (score.posteriorPoleFraming < 0.48 || score.illumination < 0.48) {
      return GuidanceStage.centerPosteriorPole;
    }
    if (score.glareRatio > 0.18 ||
        score.sharpness < 0.42 ||
        score.stableFocus < 0.44) {
      return GuidanceStage.holdSteady;
    }
    if (score.diagnosticPass) {
      return GuidanceStage.diagnosticLock;
    }
    return GuidanceStage.holdSteady;
  }

  bool _isBetterDiagnosticCandidate(RetainedGoldFrame candidate) {
    final RetainedGoldFrame? currentBest = _bestDiagnosticFrame;
    if (currentBest == null) {
      return true;
    }

    final UtilityScore candidateScore = candidate.goldFrame.utilityScore;
    final UtilityScore currentScore = currentBest.goldFrame.utilityScore;
    if (candidateScore.diagnosticQuality != currentScore.diagnosticQuality) {
      return candidateScore.diagnosticQuality > currentScore.diagnosticQuality;
    }
    if (candidateScore.sharpness != currentScore.sharpness) {
      return candidateScore.sharpness > currentScore.sharpness;
    }
    return candidate.alignmentConfidence > currentBest.alignmentConfidence;
  }

  String _selectionReasonForFrame(
    RetainedGoldFrame frame, {
    required bool manualOverride,
  }) {
    final UtilityScore score = frame.goldFrame.utilityScore;
    final String prefix = manualOverride
        ? 'Operator override selected this frame for NexEye. '
        : 'Auto-selected for NexEye. ';
    return '$prefix'
        'Diagnostic quality '
        '${score.diagnosticQuality.toStringAsFixed(2)} with '
        'sharpness ${score.sharpness.toStringAsFixed(2)}, '
        'glare ${score.glareRatio.toStringAsFixed(2)}, '
        'posterior pole ${score.posteriorPoleFraming.toStringAsFixed(2)}.';
  }

  GuidanceVector _guidanceForLaterality(GuidanceVector base) {
    if (_selectedEyeLaterality != EyeLaterality.left) {
      return base;
    }

    final GuidanceDirection direction = switch (base.direction) {
      GuidanceDirection.left => GuidanceDirection.right,
      GuidanceDirection.right => GuidanceDirection.left,
      _ => base.direction,
    };

    final String instruction = base.instruction
        .replaceAll('left', '__tmp__')
        .replaceAll('right', 'left')
        .replaceAll('__tmp__', 'right')
        .replaceAll('Left', '__tmp__')
        .replaceAll('Right', 'Left')
        .replaceAll('__tmp__', 'Right');

    return GuidanceVector(
      direction: direction,
      magnitude: base.magnitude,
      instruction: instruction,
      confidence: base.confidence,
    );
  }

  Future<void> shutdown() async {
    _pollTimer?.cancel();
    await _stopLiveCapture();
    await _cameraController?.dispose();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
