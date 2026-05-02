class UtilityScore {
  const UtilityScore({
    required this.sharpness,
    required this.glareRatio,
    required this.vascularContrast,
    required this.illumination,
    this.posteriorPoleFraming = 0,
    this.stableFocus = 0,
    this.diagnosticQuality = 0,
    this.mosaicUtility = 0,
    this.diagnosticPass = false,
    this.retainForMosaic = false,
    this.rejectionReasons = const <String>[],
    double? weightedTotal,
    bool? keepFrame,
  }) : weightedTotal = weightedTotal ?? mosaicUtility,
       keepFrame = keepFrame ?? retainForMosaic;

  final double sharpness;
  final double glareRatio;
  final double vascularContrast;
  final double illumination;
  final double posteriorPoleFraming;
  final double stableFocus;
  final double diagnosticQuality;
  final double mosaicUtility;
  final bool diagnosticPass;
  final bool retainForMosaic;
  final List<String> rejectionReasons;
  final double weightedTotal;
  final bool keepFrame;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sharpness': sharpness,
      'glareRatio': glareRatio,
      'vascularContrast': vascularContrast,
      'illumination': illumination,
      'posteriorPoleFraming': posteriorPoleFraming,
      'stableFocus': stableFocus,
      'diagnosticQuality': diagnosticQuality,
      'mosaicUtility': mosaicUtility,
      'diagnosticPass': diagnosticPass,
      'retainForMosaic': retainForMosaic,
      'rejectionReasons': rejectionReasons,
      'weightedTotal': weightedTotal,
      'keepFrame': keepFrame,
    };
  }

  factory UtilityScore.fromJson(Map<String, dynamic> json) {
    final double fallbackWeightedTotal =
        (json['weightedTotal'] as num?)?.toDouble() ?? 0;
    final bool fallbackKeepFrame = json['keepFrame'] as bool? ?? false;
    return UtilityScore(
      sharpness: (json['sharpness'] as num?)?.toDouble() ?? 0,
      glareRatio: (json['glareRatio'] as num?)?.toDouble() ?? 0,
      vascularContrast: (json['vascularContrast'] as num?)?.toDouble() ?? 0,
      illumination: (json['illumination'] as num?)?.toDouble() ?? 0,
      posteriorPoleFraming:
          (json['posteriorPoleFraming'] as num?)?.toDouble() ?? 0,
      stableFocus: (json['stableFocus'] as num?)?.toDouble() ?? 0,
      diagnosticQuality:
          (json['diagnosticQuality'] as num?)?.toDouble() ??
          fallbackWeightedTotal,
      mosaicUtility:
          (json['mosaicUtility'] as num?)?.toDouble() ?? fallbackWeightedTotal,
      diagnosticPass: json['diagnosticPass'] as bool? ?? fallbackKeepFrame,
      retainForMosaic: json['retainForMosaic'] as bool? ?? fallbackKeepFrame,
      rejectionReasons:
          (json['rejectionReasons'] as List<dynamic>? ?? const <dynamic>[])
              .map((dynamic value) => value.toString())
              .toList(growable: false),
      weightedTotal: fallbackWeightedTotal,
      keepFrame: fallbackKeepFrame,
    );
  }
}
