const String fallbackPreviewStateJson = '''
{
  "sessionId":"phase0-session",
  "eyeLaterality":"unknown",
  "utilityScore":{
    "sharpness":0.9,
    "glareRatio":0.08,
    "vascularContrast":0.78,
    "illumination":0.84,
    "posteriorPoleFraming":0.81,
    "stableFocus":0.86,
    "diagnosticQuality":0.88,
    "mosaicUtility":0.85,
    "diagnosticPass":true,
    "retainForMosaic":true,
    "rejectionReasons":[],
    "weightedTotal":0.85,
    "keepFrame":true
  },
  "guidanceVector":{
    "direction":"left",
    "magnitude":5.0,
    "instruction":"Tilt device 5° left",
    "confidence":0.91
  },
  "mosaicUpdate":{
    "transform":[1.0,0.0,18.0,0.0,1.0,-10.0,0.0,0.0,1.0],
    "coveragePercent":67.0,
    "unresolvedHolesMask":"mask://phase0/holes",
    "confidenceSummary":{
      "meanConfidence":0.84,
      "minConfidence":0.52,
      "maxConfidence":0.98
    }
  },
  "bucketSize":18,
  "qualityLabel":"Diagnostic frame locked for NexEye",
  "processingActive":true,
  "bestDiagnosticFrameId":"frame-18",
  "bestDiagnosticScore":0.88,
  "diagnosticCapturePassed":true,
  "captureLocked":true,
  "guidanceStage":"contextCapture",
  "selectionMode":"auto",
  "autoSuggestedFrameId":"frame-18",
  "rejectionReasons":[]
}
''';

const String fallbackExportJson = '''
{
  "primaryDiagnosticJpegPath":"exports/phase0/primary_diagnostic.jpeg",
  "mosaicJpegPath":"exports/phase0/mosaic.jpeg",
  "goldFramesArchivePath":"exports/phase0/gold_frames.zip",
  "metadataJsonPath":"exports/phase0/metadata.json",
  "eyeLaterality":"unknown",
  "bestDiagnosticFrameId":"frame-18",
  "bestDiagnosticScore":0.88,
  "diagnosticCapturePassed":true,
  "selectionMode":"auto",
  "autoSuggestedFrameId":"frame-18",
  "finalSelectedFrameId":"frame-18",
  "captureProfileVersion":"nexeye-capture-v1"
}
''';

class NativeApi {
  int ping() => 2026;

  String previewStateJson() => fallbackPreviewStateJson;

  String exportJson() => fallbackExportJson;

  String estimateTransformJson({
    required List<double> anchorValues,
    required int anchorWidth,
    required int anchorHeight,
    required List<double> currentValues,
    required int currentWidth,
    required int currentHeight,
  }) => '{}';

  String accumulateMosaicJson({
    required List<double> sampleValues,
    required int sampleWidth,
    required int sampleHeight,
    required List<double> transformValues,
    required List<double> coverageValues,
    required List<double> intensityValues,
    required List<double> weightValues,
    required double utilityWeight,
    required int gridSize,
    required int mosaicResolution,
  }) => '{}';
}
