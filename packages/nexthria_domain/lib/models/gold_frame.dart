import 'utility_score.dart';

class GoldFrame {
  const GoldFrame({
    required this.frameId,
    required this.acceptedAt,
    required this.utilityScore,
    required this.keypointCount,
    required this.descriptorCount,
  });

  final String frameId;
  final DateTime acceptedAt;
  final UtilityScore utilityScore;
  final int keypointCount;
  final int descriptorCount;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'frameId': frameId,
      'acceptedAt': acceptedAt.toIso8601String(),
      'utilityScore': utilityScore.toJson(),
      'keypointCount': keypointCount,
      'descriptorCount': descriptorCount,
    };
  }

  factory GoldFrame.fromJson(Map<String, dynamic> json) {
    return GoldFrame(
      frameId: json['frameId'] as String? ?? 'frame-0',
      acceptedAt: DateTime.parse(
        json['acceptedAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
      utilityScore: UtilityScore.fromJson(
        json['utilityScore'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      keypointCount: json['keypointCount'] as int? ?? 0,
      descriptorCount: json['descriptorCount'] as int? ?? 0,
    );
  }
}
