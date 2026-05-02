import 'device_pose.dart';

class FrameEnvelope {
  const FrameEnvelope({
    required this.frameId,
    required this.timestamp,
    required this.width,
    required this.height,
    required this.pixelFormat,
    this.exposureDurationMicros,
    this.iso,
    this.devicePose,
  });

  final String frameId;
  final DateTime timestamp;
  final int width;
  final int height;
  final String pixelFormat;
  final int? exposureDurationMicros;
  final double? iso;
  final DevicePose? devicePose;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'frameId': frameId,
      'timestamp': timestamp.toIso8601String(),
      'width': width,
      'height': height,
      'pixelFormat': pixelFormat,
      'exposureDurationMicros': exposureDurationMicros,
      'iso': iso,
      'devicePose': devicePose?.toJson(),
    };
  }

  factory FrameEnvelope.fromJson(Map<String, dynamic> json) {
    return FrameEnvelope(
      frameId: json['frameId'] as String? ?? 'frame-0',
      timestamp: DateTime.parse(
        json['timestamp'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      pixelFormat: json['pixelFormat'] as String? ?? 'unknown',
      exposureDurationMicros: json['exposureDurationMicros'] as int?,
      iso: (json['iso'] as num?)?.toDouble(),
      devicePose: json['devicePose'] == null
          ? null
          : DevicePose.fromJson(json['devicePose'] as Map<String, dynamic>),
    );
  }
}
