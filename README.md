# Nexthria Retina Mosaic

Phase 0 monorepo for the Nexthria live-painting retinal mosaicking system described in the January 2026 pitch deck.

## Workspace

- `apps/mobile`: Flutter capture app for iOS 16+ and Android 12+.
- `packages/nexthria_cv`: Native C++ FFI plugin facade for scoring, guidance, mosaicking, and export stubs.
- `packages/nexthria_domain`: Shared contracts for frame metadata, utility scores, guidance vectors, mosaic updates, and export payloads.
- `packages/nexthria_ui`: Shared UI theme, meters, and overlays.
- `packages/nexthria_bench`: Benchmark harness for prerecorded retinal sequences.
- `archive/legacy-scaffold`: Archived JS/Python scaffold removed from the default product path.

## Methodology Constraints

- Continuous stream only.
- No shutter-trigger workflow.
- No fixed burst-mode workflow.
- Non-linear fill-in of mosaic black holes is mandatory.
- Operator guidance directs the device hand, not the patient.

## Quick Start

```bash
git clone https://github.com/dharmiclink/retina-mosaic.git
cd retina-mosaic
dart pub get
dart run melos bootstrap
cd apps/mobile
flutter run
```

## Phase 0 Scope

- Flutter app shell and placeholder capture screen.
- Shared domain contracts with JSON serialization.
- Native plugin skeleton with C++ compilation targets for Android and iOS.
- Benchmark package skeleton for prerecorded sequence playback.
- Documentation and diagrams aligned to the pitch deck methodology.

## Verification Targets

- `dart run melos bootstrap`
- `flutter analyze`
- `flutter test`
- iOS and Android builds resolve the `nexthria_cv` plugin.

## Validation Docs

- Capture-quality labeling rubric: [`docs/validation/nexeye-capture-quality-rubric.md`](docs/validation/nexeye-capture-quality-rubric.md)
- Remote contributor onboarding: [`docs/architecture/remote-contributor-onboarding.md`](docs/architecture/remote-contributor-onboarding.md)
