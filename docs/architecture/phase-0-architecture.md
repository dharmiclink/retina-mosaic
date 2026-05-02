# Phase 0 Architecture

The workspace is organized around a Flutter app shell and a shared native C++ core.

## Runtime split

- `apps/mobile` owns UX, orchestration, overlay rendering, session lifecycle, and export flow.
- `packages/nexthria_cv` owns the native boundary and the C++ compilation surface.
- `packages/nexthria_domain` owns shared contracts between the app, benchmark harness, and plugin facade.
- `packages/nexthria_ui` owns reusable interface primitives for guidance, coverage, and quality instrumentation.
- `packages/nexthria_bench` owns prerecorded-sequence performance harnesses.

## Native boundary

Flutter calls a single Dart facade in `nexthria_cv`:

- `initializeSession`
- `startStreamProcessing`
- `stopStreamProcessing`
- `getLatestPreviewState`
- `exportSession`

Phase 0 returns deterministic stub payloads from native code so the app and benchmark harness can be wired before the full CV loop lands.
