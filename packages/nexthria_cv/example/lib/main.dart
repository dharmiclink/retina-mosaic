import 'package:flutter/material.dart';
import 'package:nexthria_cv/nexthria_cv.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final NexthriaCvPlugin _plugin = NexthriaCvPlugin.instance;
  dynamic _previewState;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _plugin.initializeSession();
    await _plugin.startStreamProcessing();
    final dynamic previewState = await _plugin.getLatestPreviewState();
    setState(() {
      _previewState = previewState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Nexthria CV Example')),
        body: Center(
          child: _previewState == null
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Ping ${_plugin.ping()} | Coverage ${_previewState!.mosaicUpdate.coveragePercent.toStringAsFixed(1)}%',
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
      ),
    );
  }
}
