#include "nexthria_cv.h"

#include <string>

#include "nexthria_cv_core.h"

namespace {

std::string BuildPreviewStateJson() {
  return std::string("{") +
      "\"sessionId\":\"phase0-session\"," +
      "\"eyeLaterality\":\"unknown\"," +
      "\"utilityScore\":" + nexthria::utility_score_json() + "," +
      "\"guidanceVector\":" + nexthria::guidance_vector_json() + "," +
      "\"mosaicUpdate\":" + nexthria::mosaic_update_json() + "," +
      "\"bucketSize\":18," +
      "\"qualityLabel\":\"Diagnostic frame locked for NexEye\"," +
      "\"processingActive\":true," +
      "\"bestDiagnosticFrameId\":\"frame-18\"," +
      "\"bestDiagnosticScore\":0.89," +
      "\"diagnosticCapturePassed\":true," +
      "\"captureLocked\":true," +
      "\"guidanceStage\":\"contextCapture\"," +
      "\"selectionMode\":\"auto\"," +
      "\"autoSuggestedFrameId\":\"frame-18\"," +
      "\"rejectionReasons\":[]," +
      "\"goldFrameSummary\":" + nexthria::gold_frame_summary_json() +
      "}";
}

}  // namespace

int32_t nexthria_phase0_ping(void) { return 2026; }

const char* nexthria_phase0_preview_state_json(void) {
  static std::string preview_state = BuildPreviewStateJson();
  return preview_state.c_str();
}

const char* nexthria_phase0_export_json(void) {
  static std::string export_payload = nexthria::export_json();
  return export_payload.c_str();
}

const char* nexthria_phase1_estimate_transform_json(
    const double* anchor_values,
    int32_t anchor_width,
    int32_t anchor_height,
    const double* current_values,
    int32_t current_width,
    int32_t current_height) {
  static std::string transform_payload;
  transform_payload = nexthria::estimate_transform_json(
      anchor_values, anchor_width, anchor_height, current_values, current_width,
      current_height);
  return transform_payload.c_str();
}

const char* nexthria_phase1_accumulate_mosaic_json(
    const double* sample_values,
    int32_t sample_width,
    int32_t sample_height,
    const double* transform_values,
    const double* coverage_values,
    int32_t coverage_length,
    const double* intensity_values,
    int32_t intensity_length,
    const double* weight_values,
    int32_t weight_length,
    double utility_weight,
    int32_t grid_size,
    int32_t mosaic_resolution) {
  static std::string mosaic_payload;
  mosaic_payload = nexthria::accumulate_mosaic_json(
      sample_values, sample_width, sample_height, transform_values,
      coverage_values, coverage_length, intensity_values, intensity_length,
      weight_values, weight_length, utility_weight, grid_size,
      mosaic_resolution);
  return mosaic_payload.c_str();
}
