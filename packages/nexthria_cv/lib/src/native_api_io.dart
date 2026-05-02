import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'native_api_stub.dart';

const String _libName = 'nexthria_cv';

typedef _PingNative = Int32 Function();
typedef _PingDart = int Function();
typedef _StringNative = Pointer<Utf8> Function();
typedef _StringDart = Pointer<Utf8> Function();
typedef _EstimateTransformNative =
    Pointer<Utf8> Function(
      Pointer<Double>,
      Int32,
      Int32,
      Pointer<Double>,
      Int32,
      Int32,
    );
typedef _EstimateTransformDart =
    Pointer<Utf8> Function(
      Pointer<Double>,
      int,
      int,
      Pointer<Double>,
      int,
      int,
    );
typedef _AccumulateMosaicNative =
    Pointer<Utf8> Function(
      Pointer<Double>,
      Int32,
      Int32,
      Pointer<Double>,
      Pointer<Double>,
      Int32,
      Pointer<Double>,
      Int32,
      Pointer<Double>,
      Int32,
      Double,
      Int32,
      Int32,
    );
typedef _AccumulateMosaicDart =
    Pointer<Utf8> Function(
      Pointer<Double>,
      int,
      int,
      Pointer<Double>,
      Pointer<Double>,
      int,
      Pointer<Double>,
      int,
      Pointer<Double>,
      int,
      double,
      int,
      int,
    );

class NativeApi {
  DynamicLibrary? _tryLoadLibrary() {
    try {
      if (Platform.isMacOS || Platform.isIOS) {
        return DynamicLibrary.open('$_libName.framework/$_libName');
      }
      if (Platform.isAndroid || Platform.isLinux) {
        return DynamicLibrary.open('lib$_libName.so');
      }
      if (Platform.isWindows) {
        return DynamicLibrary.open('$_libName.dll');
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  late final DynamicLibrary? _dylib = _tryLoadLibrary();

  _PingDart? _lookupPing() {
    final DynamicLibrary? dylib = _dylib;
    if (dylib == null) {
      return null;
    }
    return dylib
        .lookup<NativeFunction<_PingNative>>('nexthria_phase0_ping')
        .asFunction();
  }

  _StringDart? _lookupPreviewStateJson() {
    final DynamicLibrary? dylib = _dylib;
    if (dylib == null) {
      return null;
    }
    return dylib
        .lookup<NativeFunction<_StringNative>>(
          'nexthria_phase0_preview_state_json',
        )
        .asFunction();
  }

  _StringDart? _lookupExportJson() {
    final DynamicLibrary? dylib = _dylib;
    if (dylib == null) {
      return null;
    }
    return dylib
        .lookup<NativeFunction<_StringNative>>('nexthria_phase0_export_json')
        .asFunction();
  }

  _EstimateTransformDart? _lookupEstimateTransformJson() {
    final DynamicLibrary? dylib = _dylib;
    if (dylib == null) {
      return null;
    }
    return dylib
        .lookup<NativeFunction<_EstimateTransformNative>>(
          'nexthria_phase1_estimate_transform_json',
        )
        .asFunction();
  }

  _AccumulateMosaicDart? _lookupAccumulateMosaicJson() {
    final DynamicLibrary? dylib = _dylib;
    if (dylib == null) {
      return null;
    }
    return dylib
        .lookup<NativeFunction<_AccumulateMosaicNative>>(
          'nexthria_phase1_accumulate_mosaic_json',
        )
        .asFunction();
  }

  late final _PingDart? _ping = _lookupPing();
  late final _StringDart? _previewStateJson = _lookupPreviewStateJson();
  late final _StringDart? _exportJson = _lookupExportJson();
  late final _EstimateTransformDart? _estimateTransformJson =
      _lookupEstimateTransformJson();
  late final _AccumulateMosaicDart? _accumulateMosaicJson =
      _lookupAccumulateMosaicJson();

  int ping() => _ping?.call() ?? 2026;

  String previewStateJson() {
    final Pointer<Utf8>? pointer = _previewStateJson?.call();
    return pointer?.toDartString() ?? fallbackPreviewStateJson;
  }

  String exportJson() {
    final Pointer<Utf8>? pointer = _exportJson?.call();
    return pointer?.toDartString() ?? fallbackExportJson;
  }

  String estimateTransformJson({
    required List<double> anchorValues,
    required int anchorWidth,
    required int anchorHeight,
    required List<double> currentValues,
    required int currentWidth,
    required int currentHeight,
  }) {
    final _EstimateTransformDart? estimate = _estimateTransformJson;
    if (estimate == null ||
        anchorValues.isEmpty ||
        currentValues.isEmpty ||
        anchorWidth <= 0 ||
        anchorHeight <= 0 ||
        currentWidth <= 0 ||
        currentHeight <= 0) {
      return '{}';
    }

    final Pointer<Double> anchorPointer = calloc<Double>(anchorValues.length);
    final Pointer<Double> currentPointer = calloc<Double>(currentValues.length);
    try {
      for (int index = 0; index < anchorValues.length; index += 1) {
        anchorPointer[index] = anchorValues[index];
      }
      for (int index = 0; index < currentValues.length; index += 1) {
        currentPointer[index] = currentValues[index];
      }

      final Pointer<Utf8> pointer = estimate(
        anchorPointer,
        anchorWidth,
        anchorHeight,
        currentPointer,
        currentWidth,
        currentHeight,
      );
      return pointer.toDartString();
    } finally {
      calloc.free(anchorPointer);
      calloc.free(currentPointer);
    }
  }

  String accumulateMosaicJson({
    required List<double> sampleValues,
    required int sampleWidth,
    required int sampleHeight,
    required List<double> transformValues,
    required List<double> coverageValues,
    required List<double> intensityValues,
    required List<double> weightValues,
    required double utilityWeight,
    required int gridSize,
    required int mosaicResolution,
  }) {
    final _AccumulateMosaicDart? accumulate = _accumulateMosaicJson;
    if (accumulate == null ||
        sampleValues.isEmpty ||
        sampleWidth <= 0 ||
        sampleHeight <= 0 ||
        transformValues.length != 9 ||
        coverageValues.length != gridSize * gridSize ||
        intensityValues.length != mosaicResolution * mosaicResolution ||
        weightValues.length != intensityValues.length) {
      return '{}';
    }

    final Pointer<Double> samplePointer = calloc<Double>(sampleValues.length);
    final Pointer<Double> transformPointer = calloc<Double>(
      transformValues.length,
    );
    final Pointer<Double> coveragePointer = calloc<Double>(
      coverageValues.length,
    );
    final Pointer<Double> intensityPointer = calloc<Double>(
      intensityValues.length,
    );
    final Pointer<Double> weightPointer = calloc<Double>(weightValues.length);
    try {
      for (int index = 0; index < sampleValues.length; index += 1) {
        samplePointer[index] = sampleValues[index];
      }
      for (int index = 0; index < transformValues.length; index += 1) {
        transformPointer[index] = transformValues[index];
      }
      for (int index = 0; index < coverageValues.length; index += 1) {
        coveragePointer[index] = coverageValues[index];
      }
      for (int index = 0; index < intensityValues.length; index += 1) {
        intensityPointer[index] = intensityValues[index];
      }
      for (int index = 0; index < weightValues.length; index += 1) {
        weightPointer[index] = weightValues[index];
      }

      final Pointer<Utf8> pointer = accumulate(
        samplePointer,
        sampleWidth,
        sampleHeight,
        transformPointer,
        coveragePointer,
        coverageValues.length,
        intensityPointer,
        intensityValues.length,
        weightPointer,
        weightValues.length,
        utilityWeight,
        gridSize,
        mosaicResolution,
      );
      return pointer.toDartString();
    } finally {
      calloc.free(samplePointer);
      calloc.free(transformPointer);
      calloc.free(coveragePointer);
      calloc.free(intensityPointer);
      calloc.free(weightPointer);
    }
  }
}
