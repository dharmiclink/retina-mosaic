enum GuidanceDirection { left, right, up, down, hold, center }

class GuidanceVector {
  const GuidanceVector({
    required this.direction,
    required this.magnitude,
    required this.instruction,
    required this.confidence,
  });

  final GuidanceDirection direction;
  final double magnitude;
  final String instruction;
  final double confidence;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'direction': direction.name,
      'magnitude': magnitude,
      'instruction': instruction,
      'confidence': confidence,
    };
  }

  factory GuidanceVector.fromJson(Map<String, dynamic> json) {
    final String rawDirection =
        json['direction'] as String? ?? GuidanceDirection.hold.name;
    return GuidanceVector(
      direction: GuidanceDirection.values.firstWhere(
        (GuidanceDirection value) => value.name == rawDirection,
        orElse: () => GuidanceDirection.hold,
      ),
      magnitude: (json['magnitude'] as num?)?.toDouble() ?? 0,
      instruction: json['instruction'] as String? ?? 'Hold steady',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}
