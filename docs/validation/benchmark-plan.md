# Benchmark Plan

Phase 0 benchmark harness is file-driven and uses prerecorded retinal sequences.

## Metrics

- utility scoring latency per frame
- preview update latency
- estimated memory footprint
- bucket acceptance ratio
- coverage progression over time

## Inputs

- prerecorded `.mp4` or extracted retinal frame folders in `assets/demo_sequences`
- synthetic session configuration payloads from `nexthria_domain`
- handheld capture manifests labeled with the rubric in [`nexeye-capture-quality-rubric.md`](/Users/tarmarajapadrasono/retina-mosaic/docs/validation/nexeye-capture-quality-rubric.md)
- fundus-camera reference folders used as quality ceiling examples, not as direct capture accept/reject labels

## Outputs

- console summary from `packages/nexthria_bench/bin/benchmark_stub.dart`
- JSON benchmark summaries for future regression tracking

## Manifest Generation

Generate a pending-review template from a dataset folder with:

```bash
cd /Users/tarmarajapadrasono/retina-mosaic/packages/nexthria_bench
dart run bin/generate_label_manifest.dart \
  "/Users/tarmarajapadrasono/Downloads/DR Sample Images" \
  "/Users/tarmarajapadrasono/retina-mosaic/docs/validation/manifests/dr-sample-images-template.json"
```

This template is for manual rubric labeling and starts with `pendingReview` entries.

Enrich a manifest with offline quality scores from the current heuristic capture gate:

```bash
cd /Users/tarmarajapadrasono/retina-mosaic/packages/nexthria_bench
dart run bin/enrich_label_manifest.dart \
  "/Users/tarmarajapadrasono/retina-mosaic/docs/validation/manifests/dr-sample-images-template.json" \
  "/Users/tarmarajapadrasono/retina-mosaic/docs/validation/manifests/dr-sample-images-scored.json"
```

This does not assign the human `accept / borderline / reject` label.
It only fills the machine score fields so reviewers can compare their labels against the current scorer.
