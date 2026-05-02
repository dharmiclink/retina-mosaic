class ConfidenceSummary {
  const ConfidenceSummary({
    required this.meanConfidence,
    required this.minConfidence,
    required this.maxConfidence,
  });

  final double meanConfidence;
  final double minConfidence;
  final double maxConfidence;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'meanConfidence': meanConfidence,
      'minConfidence': minConfidence,
      'maxConfidence': maxConfidence,
    };
  }

  factory ConfidenceSummary.fromJson(Map<String, dynamic> json) {
    return ConfidenceSummary(
      meanConfidence: (json['meanConfidence'] as num?)?.toDouble() ?? 0,
      minConfidence: (json['minConfidence'] as num?)?.toDouble() ?? 0,
      maxConfidence: (json['maxConfidence'] as num?)?.toDouble() ?? 0,
    );
  }
}
