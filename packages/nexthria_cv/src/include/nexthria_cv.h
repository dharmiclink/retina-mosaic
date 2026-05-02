#ifndef FLUTTER_PLUGIN_NEXTHRIA_CV_H_
#define FLUTTER_PLUGIN_NEXTHRIA_CV_H_

#include <stdint.h>

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

FFI_PLUGIN_EXPORT int32_t nexthria_phase0_ping(void);
FFI_PLUGIN_EXPORT const char* nexthria_phase0_preview_state_json(void);
FFI_PLUGIN_EXPORT const char* nexthria_phase0_export_json(void);
FFI_PLUGIN_EXPORT const char* nexthria_phase1_estimate_transform_json(
    const double* anchor_values,
    int32_t anchor_width,
    int32_t anchor_height,
    const double* current_values,
    int32_t current_width,
    int32_t current_height);
FFI_PLUGIN_EXPORT const char* nexthria_phase1_accumulate_mosaic_json(
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
    int32_t mosaic_resolution);

#ifdef __cplusplus
}
#endif

#endif  // FLUTTER_PLUGIN_NEXTHRIA_CV_H_
