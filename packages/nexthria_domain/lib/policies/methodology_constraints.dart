class MethodologyConstraints {
  const MethodologyConstraints._();

  static const List<String> requiredConstraints = <String>[
    'continuous stream only',
    'no discrete shutter trigger logic',
    'no fixed burst-mode sequence',
    'non-linear black-hole fill-in is mandatory',
    'operator-vector guidance directs the hand, not the patient',
  ];

  static const String patentBoundarySummary =
      'Continuous extraction and dynamic projection only. Avoid trigger-based and burst-mode flows.';
}
