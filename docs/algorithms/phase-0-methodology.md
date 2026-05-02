# Phase 0 Methodology Notes

This repository intentionally follows the method boundaries stated in the deck:

1. Use a continuous video stream, not discrete capture events.
2. Score every frame for utility and keep only high-value gold frames.
3. Project accepted frames onto a live canvas non-sequentially.
4. Show visible holes so the operator can paint them in without restarting.
5. Provide vector guidance that directs the operator hand.

Phase 0 does not implement production CV yet. It establishes the data contracts and native execution path needed for:

- utility scoring
- gold-frame bucketing
- live mosaicking
- confidence heatmaps
- export packaging
