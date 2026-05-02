# Remote Contributor Onboarding

This document is for engineers contributing to the NexEye capture coach from outside the primary build and validation environment.

## Product Purpose

This repository is not the NexEye diagnosis engine.

This app is an acquisition assistant that helps a non-expert operator capture at least one diagnostic-grade retinal frame through a handheld fundus lens. The primary product output is:

- one best diagnostic frame for NexEye
- session metadata explaining why that frame was selected
- an optional context mosaic for operator guidance and audit

Diagnosis remains downstream in NexEye.

## Current State

The repo is a strong prototype, not yet a fully calibrated production capture system.

What is already in place:

- Flutter app shell and NexEye-style UI
- live camera and mock capture flows
- diagnostic-first capture stages
- best-frame auto-selection plus manual override
- shared contracts for capture preview, export, laterality, and selection metadata
- native CV package with projective transform estimation and low-resolution mosaic accumulation
- benchmark tooling for capture-quality manifest generation and offline scoring

What is still incomplete:

- NexEye-calibrated capture gate based on real labeled handheld-lens data
- final OpenCV ORB plus descriptor matching plus RANSAC homography path
- device and operator validation on real lens workflows
- downstream NexEye ingestion validation for exported bundles

## Who Can Contribute Remotely

Remote contributors can work effectively on:

- Flutter UI and session flow
- capture-state logic
- export contract hardening
- benchmark tooling
- native CV package structure and algorithm implementation
- documentation and validation workflows

Remote contributors are limited on:

- real capture tuning without handheld fundus lens access
- validating true diagnostic acceptance without labeled NexEye capture-quality data
- confirming operator ergonomics without field testing

## Tooling Prerequisites

Minimum environment:

- Git
- Flutter SDK
- Dart SDK
- Android toolchain if building the mobile app locally
- C++ toolchain for the native `nexthria_cv` package

Recommended checks:

```bash
flutter --version
dart --version
```

## Repository Layout

- `apps/mobile`: main Flutter capture application
- `packages/nexthria_domain`: shared contracts and models
- `packages/nexthria_ui`: shared UI theme and widgets
- `packages/nexthria_cv`: native CV boundary and FFI layer
- `packages/nexthria_bench`: offline benchmark and labeling tools
- `docs/validation`: rubric, benchmark plan, manifests

## Local Setup

Bootstrap the workspace:

```bash
git clone https://github.com/dharmiclink/retina-mosaic.git
cd retina-mosaic
dart pub get
dart run melos bootstrap
```

Run the main validation set:

```bash
cd apps/mobile
flutter analyze
flutter test
```

Validate the benchmark package:

```bash
cd packages/nexthria_bench
dart analyze
flutter test
```

## Working Modes

There are two useful ways to work on the app remotely:

### 1. Browser And Mock Mode

Best for:

- UI work
- capture-state logic
- diagnostic selection flow
- export summaries

Typical run path:

```bash
cd apps/mobile
flutter run -d chrome
```

### 2. Device-Oriented Flutter Work

Best for:

- camera integration
- frame sampling changes
- capture flow timing
- live preview behavior

This still does not replace real handheld fundus-lens validation.

## Product Guardrails

These constraints are deliberate and should not be violated:

- continuous stream workflow only
- no auto-trigger shutter workflow
- no fixed burst-mode capture workflow
- guidance directs the operator hand, not the patient
- success is defined by obtaining a NexEye-usable frame, not by maximizing mosaic size alone

## Data And Benchmarking

Reference-quality images:

- fundus-camera images can be used as quality ceiling references
- they are not direct accept or reject labels for handheld capture quality

Capture-quality labeling:

- use the rubric in [`nexeye-capture-quality-rubric.md`](../validation/nexeye-capture-quality-rubric.md)
- use the benchmark workflow in [`benchmark-plan.md`](../validation/benchmark-plan.md)

Generate a manifest template:

```bash
cd packages/nexthria_bench
dart run bin/generate_label_manifest.dart \
  "/path/to/dataset" \
  "/path/to/output-manifest.json"
```

Enrich an existing manifest with current heuristic scores:

```bash
cd packages/nexthria_bench
dart run bin/enrich_label_manifest.dart \
  "/path/to/input-manifest.json" \
  "/path/to/output-manifest.json" \
  "/path/to/dataset-root"
```

## Safe Enhancement Policy

Enhancement work must preserve pathology and avoid inventing detail.

Allowed directions:

- illumination normalization
- glare suppression
- denoising
- conservative contrast normalization
- conservative sharpness recovery if validated

Not acceptable for the primary diagnostic path:

- generative inpainting
- hallucinated vessel restoration
- lesion synthesis
- aggressive super-resolution that invents clinical detail

## Recommended Task Split

Good remote work packages:

- `Flutter UI`: refine guidance, diagnostic preview, export UX
- `Domain contracts`: tighten metadata and session state
- `Benchmarking`: improve manifest tools, scoring reports, calibration scripts
- `Native CV`: improve transform estimation and mosaic quality in `packages/nexthria_cv`
- `Docs`: strengthen setup, validation, and calibration documentation

Tasks that should be paired with local validation support:

- camera tuning
- handheld lens focus and glare mitigation logic
- diagnostic acceptance threshold calibration
- final operator workflow validation

## Delivery Standard

Before opening a PR, contributors should run:

```bash
cd retina-mosaic
dart run melos bootstrap
cd apps/mobile
flutter analyze
flutter test
```

If work touches `packages/nexthria_bench` or `packages/nexthria_cv`, run package-local analysis and tests as well.

## What To Ask The Project Owner For

If a contributor is blocked, the missing dependency is usually one of these:

- labeled handheld capture-quality dataset
- sample export bundle expected by NexEye ingestion
- target phone and lens combination
- real-world operator workflow examples
- calibration target for accept versus borderline versus reject

Without those, a contributor can still improve the software, but cannot fully validate product truth.
