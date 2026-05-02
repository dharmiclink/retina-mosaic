class DevicePose {
  const DevicePose({
    required this.pitchDegrees,
    required this.yawDegrees,
    required this.rollDegrees,
  });

  final double pitchDegrees;
  final double yawDegrees;
  final double rollDegrees;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'pitchDegrees': pitchDegrees,
      'yawDegrees': yawDegrees,
      'rollDegrees': rollDegrees,
    };
  }

  factory DevicePose.fromJson(Map<String, dynamic> json) {
    return DevicePose(
      pitchDegrees: (json['pitchDegrees'] as num?)?.toDouble() ?? 0,
      yawDegrees: (json['yawDegrees'] as num?)?.toDouble() ?? 0,
      rollDegrees: (json['rollDegrees'] as num?)?.toDouble() ?? 0,
    );
  }
}
