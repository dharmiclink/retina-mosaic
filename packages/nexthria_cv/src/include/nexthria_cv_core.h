#ifndef FLUTTER_PLUGIN_NEXTHRIA_CV_CORE_H_
#define FLUTTER_PLUGIN_NEXTHRIA_CV_CORE_H_

#include <cstdint>
#include <string>

namespace nexthria {

std::string utility_score_json();
std::string guidance_vector_json();
std::string mosaic_update_json();
std::string export_json();
std::string gold_frame_summary_json();
std::string estimate_transform_json(const double* anchor_values,
                                    int32_t anchor_width,
                                    int32_t anchor_height,
                                    const double* current_values,
                                    int32_t current_width,
                                    int32_t current_height);
std::string accumulate_mosaic_json(const double* sample_values,
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

}  // namespace nexthria

#endif  // FLUTTER_PLUGIN_NEXTHRIA_CV_CORE_H_
