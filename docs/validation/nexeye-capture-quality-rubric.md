# NexEye Capture Quality Rubric

This rubric is for labeling handheld fundus-lens captures as input candidates for NexEye.

It is not a diabetic-retinopathy severity rubric.
It is not a grading rubric for lesion burden.
It answers one question only:

`Is this image good enough to preserve NexEye diagnostic performance?`

## Label Set

Use exactly one of these labels per image:

- `accept`: safe for NexEye primary inference
- `borderline`: usable only for internal review, not preferred for production inference
- `reject`: recapture required

## Core Criteria

Each image must be reviewed on six dimensions.
Score each dimension `0`, `1`, or `2`.

| Criterion | 0 | 1 | 2 |
|---|---|---|---|
| `Sharpness` | vessels blurred, fine retinal detail lost | mild blur but major structures visible | vessels and central detail crisp |
| `Glare / Reflection` | glare obscures clinically important retina | glare present but does not fully block interpretation | minimal glare, retina clearly visible |
| `Illumination` | too dark, blown out, or highly uneven | usable but imperfect exposure | balanced and clinically usable exposure |
| `Vascular Contrast` | vessels poorly separable from background | moderate vessel visibility | vessels stand out clearly |
| `Posterior Pole Framing` | posterior pole not properly captured | partially centered or off-axis but still partly usable | posterior pole centered and well framed |
| `Stable Focus Through Lens` | obvious focus instability or soft central field | mild instability | central field stably focused |

Maximum total score: `12`

## Label Rules

Assign labels using both the total score and hard fails.

### `accept`

Label as `accept` only if:

- total score is `10-12`
- no criterion is `0`
- `Sharpness` is at least `2`
- `Glare / Reflection` is at least `1`
- `Posterior Pole Framing` is at least `1`

### `borderline`

Label as `borderline` if:

- total score is `7-9`
- no more than one criterion is `0`
- the image is still clinically interpretable enough that a reviewer would consider it usable for secondary review

### `reject`

Label as `reject` if any of these are true:

- total score is `0-6`
- two or more criteria are `0`
- posterior pole is not meaningfully visible
- glare blocks the critical retinal region
- focus loss makes vascular or lesion detail unreliable

## Hard Rejection Conditions

Immediately label `reject` if any of these apply:

- no retinal signal
- pupil/reflex not acquired
- image dominated by corneal reflection
- retinal field mostly outside frame
- central field fully out of focus
- severe motion smear

## Reviewer Guidance

Reviewers should compare handheld captures against the best available reference-quality fundus-camera examples, but should not force handheld images to match desktop-camera perfection.

The benchmark intent is:

- fundus-camera images define the `quality ceiling`
- handheld captures are judged on whether they remain `NexEye-safe`

## Dataset Columns

Recommended manifest columns for calibration:

| Field | Meaning |
|---|---|
| `id` | unique image id |
| `path` | dataset-relative or absolute image path |
| `eyeLaterality` | `left` or `right` |
| `sourceType` | `handheld_lens` or `fundus_camera_reference` |
| `label` | `accept`, `borderline`, or `reject` |
| `sharpnessScore` | `0`, `1`, `2` |
| `glareScore` | `0`, `1`, `2` |
| `illuminationScore` | `0`, `1`, `2` |
| `vascularContrastScore` | `0`, `1`, `2` |
| `posteriorPoleFramingScore` | `0`, `1`, `2` |
| `stableFocusScore` | `0`, `1`, `2` |
| `notes` | short human rationale |
| `reviewer` | who labeled it |
| `captureProfileVersion` | scorer version used later |

## Mapping To Current App Metrics

Current app metrics already align to this rubric:

- `sharpness`
- `glareRatio`
- `vascularContrast`
- `illumination`
- `posteriorPoleFraming`
- `stableFocus`

This rubric is the human-label layer that should be used to calibrate the app thresholds in `apps/mobile/lib/features/capture/live_utility_scorer.dart`.

## Safe Enhancement Policy

Allowed preprocessing before scoring or NexEye handoff:

- illumination normalization
- contrast normalization
- conservative denoising
- glare suppression
- non-generative color normalization

Not allowed for primary diagnostic export:

- generative inpainting
- lesion hallucination
- vessel hallucination
- aggressive super-resolution that invents detail

## Benchmark Use

Use the real fundus-camera folders as `reference benchmark images`.
Do not treat DR severity class folders as capture-quality labels.

For true NexEye calibration, the required dataset is:

- handheld captures labeled with this rubric
- optional paired fundus-camera references when available
