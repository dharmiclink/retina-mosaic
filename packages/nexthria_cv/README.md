# nexthria_cv

Native Phase 0 plugin facade for the Nexthria retinal mosaicking system.

## Responsibilities

- expose one Dart plugin facade for session lifecycle
- compile shared C++ code on Android and iOS
- return stub preview and export payloads while the full CV loop is under construction

## Public facade

- `initializeSession`
- `startStreamProcessing`
- `stopStreamProcessing`
- `getLatestPreviewState`
- `exportSession`
