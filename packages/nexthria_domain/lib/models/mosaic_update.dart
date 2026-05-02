import 'confidence_summary.dart';

class MosaicUpdate {
  const MosaicUpdate({
    required this.transform,
    required this.coveragePercent,
    required this.unresolvedHolesMask,
    required this.confidenceSummary,
  });

  final List<double> transform;
  final double coveragePercent;
  final String unresolvedHolesMask;
  final ConfidenceSummary confidenceSummary;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'transform': transform,
      'coveragePercent': coveragePercent,
      'unresolvedHolesMask': unresolvedHolesMask,
      'confidenceSummary': confidenceSummary.toJson(),
    };
  }

  factory MosaicUpdate.fromJson(Map<String, dynamic> json) {
    return MosaicUpdate(
      transform: ((json['transform'] as List<dynamic>?) ?? const <dynamic>[])
          .map((dynamic value) => (value as num).toDouble())
          .toList(),
      coveragePercent: (json['coveragePercent'] as num?)?.toDouble() ?? 0,
      unresolvedHolesMask:
          json['unresolvedHolesMask'] as String? ?? 'mask://none',
      confidenceSummary: ConfidenceSummary.fromJson(
        json['confidenceSummary'] as Map<String, dynamic>? ??
            <String, dynamic>{},
      ),
    );
  }
}
