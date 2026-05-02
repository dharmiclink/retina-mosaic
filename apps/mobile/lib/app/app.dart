import 'package:flutter/material.dart';
import 'package:nexthria_ui/nexthria_ui.dart';

import '../features/capture/capture_page.dart';

class NexthriaApp extends StatelessWidget {
  const NexthriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexEye Capture Coach',
      debugShowCheckedModeBanner: false,
      theme: NexthriaTheme.darkTheme(),
      home: const CapturePage(),
    );
  }
}
