enum EyeLaterality { left, right, unknown }

extension EyeLateralityX on EyeLaterality {
  String get label {
    switch (this) {
      case EyeLaterality.left:
        return 'Left Eye';
      case EyeLaterality.right:
        return 'Right Eye';
      case EyeLaterality.unknown:
        return 'Unknown Eye';
    }
  }
}
