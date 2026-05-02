#include "nexthria_cv_core.h"

#include <algorithm>
#include <cmath>
#include <numeric>
#include <sstream>
#include <string>
#include <vector>

namespace nexthria {

namespace {

struct SampleView {
  const double* values;
  int width;
  int height;

  double at(int x, int y) const { return values[(y * width) + x]; }
};

struct Point {
  double x;
  double y;
};

Point ApplyTransform(const std::vector<double>& transform, double x, double y) {
  const double w = (transform[6] * x) + (transform[7] * y) + transform[8];
  if (std::abs(w) < 1e-6) {
    return {transform[2], transform[5]};
  }
  return {
      ((transform[0] * x) + (transform[1] * y) + transform[2]) / w,
      ((transform[3] * x) + (transform[4] * y) + transform[5]) / w,
  };
}

void AccumulatePixel(std::vector<double>& intensity_grid,
                     std::vector<double>& weight_grid,
                     int mosaic_resolution,
                     int x,
                     int y,
                     double intensity,
                     double weight) {
  if (weight <= 0.0 || x < 0 || y < 0 || x >= mosaic_resolution ||
      y >= mosaic_resolution) {
    return;
  }

  const int index = (y * mosaic_resolution) + x;
  const double existing_weight = weight_grid[index];
  const double total_weight = existing_weight + weight;
  if (total_weight <= 0.0) {
    return;
  }

  intensity_grid[index] =
      ((intensity_grid[index] * existing_weight) + (intensity * weight)) /
      total_weight;
  weight_grid[index] = std::clamp(total_weight, 0.0, 4.0);
}

void SplatOntoCanvas(std::vector<double>& intensity_grid,
                     std::vector<double>& weight_grid,
                     int mosaic_resolution,
                     double x,
                     double y,
                     double intensity,
                     double weight) {
  const int x0 = static_cast<int>(std::floor(x));
  const int y0 = static_cast<int>(std::floor(y));
  const double fx = x - static_cast<double>(x0);
  const double fy = y - static_cast<double>(y0);

  AccumulatePixel(intensity_grid, weight_grid, mosaic_resolution, x0, y0,
                  intensity, weight * (1.0 - fx) * (1.0 - fy));
  AccumulatePixel(intensity_grid, weight_grid, mosaic_resolution, x0 + 1, y0,
                  intensity, weight * fx * (1.0 - fy));
  AccumulatePixel(intensity_grid, weight_grid, mosaic_resolution, x0, y0 + 1,
                  intensity, weight * (1.0 - fx) * fy);
  AccumulatePixel(intensity_grid, weight_grid, mosaic_resolution, x0 + 1,
                  y0 + 1, intensity, weight * fx * fy);
}

double CoveragePercent(const std::vector<double>& coverage_grid) {
  const int painted = static_cast<int>(std::count_if(
      coverage_grid.begin(), coverage_grid.end(),
      [](double value) { return value >= 0.16; }));
  return std::clamp(
      (static_cast<double>(painted) / static_cast<double>(coverage_grid.size())) *
          100.0,
      0.0, 95.0);
}

std::string SuggestedDirection(const std::vector<double>& coverage_grid,
                               int grid_size) {
  double left_sum = 0.0;
  double right_sum = 0.0;
  double top_sum = 0.0;
  double bottom_sum = 0.0;

  for (int y = 0; y < grid_size; ++y) {
    for (int x = 0; x < grid_size; ++x) {
      const double gap = 1.0 - coverage_grid[(y * grid_size) + x];
      if (x < grid_size / 2) {
        left_sum += gap;
      } else {
        right_sum += gap;
      }
      if (y < grid_size / 2) {
        top_sum += gap;
      } else {
        bottom_sum += gap;
      }
    }
  }

  double best = left_sum;
  std::string direction = "left";
  if (right_sum > best) {
    best = right_sum;
    direction = "right";
  }
  if (top_sum > best) {
    best = top_sum;
    direction = "up";
  }
  if (bottom_sum > best) {
    direction = "down";
  }
  return direction;
}

}  // namespace

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
                                   int32_t mosaic_resolution) {
  if (sample_values == nullptr || transform_values == nullptr ||
      coverage_values == nullptr || intensity_values == nullptr ||
      weight_values == nullptr || sample_width <= 0 || sample_height <= 0 ||
      grid_size <= 0 || mosaic_resolution <= 0 ||
      coverage_length != (grid_size * grid_size) ||
      intensity_length != (mosaic_resolution * mosaic_resolution) ||
      weight_length != intensity_length) {
    return "{}";
  }

  const SampleView sample{sample_values, sample_width, sample_height};
  const std::vector<double> transform(transform_values, transform_values + 9);
  std::vector<double> coverage_grid(coverage_values,
                                    coverage_values + coverage_length);
  std::vector<double> intensity_grid(intensity_values,
                                     intensity_values + intensity_length);
  std::vector<double> weight_grid(weight_values, weight_values + weight_length);

  const std::vector<Point> corners = {
      ApplyTransform(transform, 0.0, 0.0),
      ApplyTransform(transform, static_cast<double>(sample_width), 0.0),
      ApplyTransform(transform, static_cast<double>(sample_width),
                     static_cast<double>(sample_height)),
      ApplyTransform(transform, 0.0, static_cast<double>(sample_height)),
  };

  double min_x = corners.front().x;
  double max_x = corners.front().x;
  double min_y = corners.front().y;
  double max_y = corners.front().y;
  for (size_t i = 1; i < corners.size(); ++i) {
    min_x = std::min(min_x, corners[i].x);
    max_x = std::max(max_x, corners[i].x);
    min_y = std::min(min_y, corners[i].y);
    max_y = std::max(max_y, corners[i].y);
  }

  const double pixels_per_grid_unit =
      static_cast<double>(mosaic_resolution) / static_cast<double>(grid_size);
  const Point center = ApplyTransform(transform, sample_width / 2.0,
                                      sample_height / 2.0);
  const double grid_center_x = std::clamp(
      center.x / pixels_per_grid_unit, 0.0, static_cast<double>(grid_size - 1));
  const double grid_center_y = std::clamp(
      center.y / pixels_per_grid_unit, 0.0, static_cast<double>(grid_size - 1));
  const double radius_x =
      std::max(2.2, ((max_x - min_x) / pixels_per_grid_unit) / 2.0);
  const double radius_y =
      std::max(2.2, ((max_y - min_y) / pixels_per_grid_unit) / 2.0);

  for (int y = 0; y < grid_size; ++y) {
    for (int x = 0; x < grid_size; ++x) {
      const double dx = (static_cast<double>(x) - grid_center_x) / radius_x;
      const double dy = (static_cast<double>(y) - grid_center_y) / radius_y;
      const double distance = (dx * dx) + (dy * dy);
      if (distance > 1.0) {
        continue;
      }
      const double gain = (1.0 - distance) * utility_weight;
      const int index = (y * grid_size) + x;
      coverage_grid[index] =
          std::clamp(coverage_grid[index] + gain, 0.0, 1.0);
    }
  }

  const double sample_center_x = sample_width / 2.0;
  const double sample_center_y = sample_height / 2.0;
  const double max_distance =
      std::sqrt((sample_center_x * sample_center_x) +
                (sample_center_y * sample_center_y));

  for (int sy = 0; sy < sample_height; ++sy) {
    for (int sx = 0; sx < sample_width; ++sx) {
      const double dx = static_cast<double>(sx) - sample_center_x;
      const double dy = static_cast<double>(sy) - sample_center_y;
      const double radial_weight =
          1.0 - (std::sqrt((dx * dx) + (dy * dy)) / max_distance);
      const double weight =
          std::clamp(radial_weight, 0.0, 1.0) * utility_weight;
      if (weight <= 0.02) {
        continue;
      }

      const Point canvas_point =
          ApplyTransform(transform, static_cast<double>(sx), static_cast<double>(sy));
      SplatOntoCanvas(intensity_grid, weight_grid, mosaic_resolution,
                      canvas_point.x, canvas_point.y,
                      sample.at(sx, sy) / 255.0, weight);
    }
  }

  const double mean_confidence =
      std::accumulate(coverage_grid.begin(), coverage_grid.end(), 0.0) /
      static_cast<double>(coverage_grid.size());
  const double min_confidence =
      *std::min_element(coverage_grid.begin(), coverage_grid.end());
  const double max_confidence =
      *std::max_element(coverage_grid.begin(), coverage_grid.end());

  std::ostringstream output;
  output << "{";
  output << "\"transform\":[";
  for (size_t i = 0; i < transform.size(); ++i) {
    if (i > 0) {
      output << ",";
    }
    output << transform[i];
  }
  output << "],";
  output << "\"coveragePercent\":" << CoveragePercent(coverage_grid) << ",";
  output << "\"canvasOffset\":{\"x\":" << grid_center_x << ",\"y\":"
         << grid_center_y << "},";
  output << "\"confidenceSummary\":{\"meanConfidence\":" << mean_confidence
         << ",\"minConfidence\":" << min_confidence
         << ",\"maxConfidence\":" << max_confidence << "},";
  output << "\"suggestedSweepDirection\":\""
         << SuggestedDirection(coverage_grid, grid_size) << "\",";
  output << "\"coverageGrid\":[";
  for (size_t i = 0; i < coverage_grid.size(); ++i) {
    if (i > 0) {
      output << ",";
    }
    output << coverage_grid[i];
  }
  output << "],";
  output << "\"mosaicIntensityGrid\":[";
  for (size_t i = 0; i < intensity_grid.size(); ++i) {
    if (i > 0) {
      output << ",";
    }
    output << intensity_grid[i];
  }
  output << "],";
  output << "\"mosaicWeightGrid\":[";
  for (size_t i = 0; i < weight_grid.size(); ++i) {
    if (i > 0) {
      output << ",";
    }
    output << weight_grid[i];
  }
  output << "]}";
  return output.str();
}

}  // namespace nexthria
