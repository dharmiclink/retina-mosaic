#include "nexthria_cv_core.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
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

struct FeaturePoint {
  int x;
  int y;
  double score;
  std::vector<double> descriptor;
};

struct FeatureMatch {
  FeaturePoint anchor;
  FeaturePoint current;
  double distance;
};

struct HomographyEstimate {
  std::vector<double> transform;
  double scale;
  double rotation_radians;
  std::vector<FeatureMatch> inliers;
  double mean_error;
};

double DescriptorDistance(const std::vector<double>& a,
                          const std::vector<double>& b) {
  double sum = 0.0;
  for (size_t i = 0; i < a.size(); ++i) {
    const double delta = a[i] - b[i];
    sum += delta * delta;
  }
  return std::sqrt(sum);
}

std::vector<double> Descriptor(const SampleView& sample, int x, int y) {
  std::vector<double> descriptor;
  descriptor.reserve(11);
  for (int dy = -2; dy <= 2; dy += 2) {
    for (int dx = -2; dx <= 2; dx += 2) {
      descriptor.push_back(sample.at(x + dx, y + dy) / 255.0);
    }
  }
  descriptor.push_back((sample.at(x + 1, y) - sample.at(x - 1, y)) / 255.0);
  descriptor.push_back((sample.at(x, y + 1) - sample.at(x, y - 1)) / 255.0);
  return descriptor;
}

std::vector<FeaturePoint> Detect(const SampleView& sample, int max_points = 48) {
  if (sample.width < 7 || sample.height < 7) {
    return {};
  }

  std::vector<FeaturePoint> candidates;
  for (int y = 3; y < sample.height - 3; ++y) {
    for (int x = 3; x < sample.width - 3; ++x) {
      const double gx = std::abs(sample.at(x + 1, y) - sample.at(x - 1, y));
      const double gy = std::abs(sample.at(x, y + 1) - sample.at(x, y - 1));
      const double g1 =
          std::abs(sample.at(x + 1, y + 1) - sample.at(x - 1, y - 1));
      const double g2 =
          std::abs(sample.at(x + 1, y - 1) - sample.at(x - 1, y + 1));
      const double corner_score = (gx * gy) + (g1 * g2 * 0.5);
      if (corner_score < 400.0) {
        continue;
      }

      candidates.push_back(
          FeaturePoint{x, y, corner_score, Descriptor(sample, x, y)});
    }
  }

  std::sort(candidates.begin(), candidates.end(),
            [](const FeaturePoint& a, const FeaturePoint& b) {
              return a.score > b.score;
            });

  std::vector<FeaturePoint> selected;
  for (const FeaturePoint& point : candidates) {
    bool too_close = false;
    for (const FeaturePoint& existing : selected) {
      if (std::abs(existing.x - point.x) <= 3 &&
          std::abs(existing.y - point.y) <= 3) {
        too_close = true;
        break;
      }
    }
    if (too_close) {
      continue;
    }
    selected.push_back(point);
    if (static_cast<int>(selected.size()) >= max_points) {
      break;
    }
  }
  return selected;
}

std::vector<FeatureMatch> Match(const std::vector<FeaturePoint>& anchor,
                                const std::vector<FeaturePoint>& current) {
  std::vector<FeatureMatch> candidates;
  for (const FeaturePoint& current_point : current) {
    const FeaturePoint* best = nullptr;
    const FeaturePoint* second_best = nullptr;
    double best_distance = std::numeric_limits<double>::infinity();
    double second_distance = std::numeric_limits<double>::infinity();

    for (const FeaturePoint& anchor_point : anchor) {
      const double distance =
          DescriptorDistance(anchor_point.descriptor, current_point.descriptor);
      if (distance < best_distance) {
        second_distance = best_distance;
        second_best = best;
        best_distance = distance;
        best = &anchor_point;
      } else if (distance < second_distance) {
        second_distance = distance;
        second_best = &anchor_point;
      }
    }

    if (best == nullptr) {
      continue;
    }
    if (second_best != nullptr &&
        second_distance > 0.0 &&
        (best_distance / second_distance) > 0.82) {
      continue;
    }
    candidates.push_back(FeatureMatch{*best, current_point, best_distance});
  }

  std::sort(candidates.begin(), candidates.end(),
            [](const FeatureMatch& a, const FeatureMatch& b) {
              return a.distance < b.distance;
            });

  std::vector<FeatureMatch> selected;
  std::vector<std::string> used;
  for (const FeatureMatch& match : candidates) {
    const std::string key = std::to_string(match.anchor.x) + ":" +
                            std::to_string(match.anchor.y);
    if (std::find(used.begin(), used.end(), key) != used.end()) {
      continue;
    }
    used.push_back(key);
    selected.push_back(match);
    if (static_cast<int>(selected.size()) >= 18) {
      break;
    }
  }
  return selected;
}

bool SolveLinearSystem(std::vector<double>* matrix,
                       std::vector<double>* rhs,
                       int n) {
  for (int pivot = 0; pivot < n; ++pivot) {
    int best_row = pivot;
    double best_value = std::abs((*matrix)[(pivot * n) + pivot]);
    for (int row = pivot + 1; row < n; ++row) {
      const double value = std::abs((*matrix)[(row * n) + pivot]);
      if (value > best_value) {
        best_value = value;
        best_row = row;
      }
    }

    if (best_value < 1e-8) {
      return false;
    }

    if (best_row != pivot) {
      for (int col = 0; col < n; ++col) {
        std::swap((*matrix)[(pivot * n) + col], (*matrix)[(best_row * n) + col]);
      }
      std::swap((*rhs)[pivot], (*rhs)[best_row]);
    }

    const double pivot_value = (*matrix)[(pivot * n) + pivot];
    for (int col = pivot; col < n; ++col) {
      (*matrix)[(pivot * n) + col] /= pivot_value;
    }
    (*rhs)[pivot] /= pivot_value;

    for (int row = 0; row < n; ++row) {
      if (row == pivot) {
        continue;
      }
      const double factor = (*matrix)[(row * n) + pivot];
      if (std::abs(factor) < 1e-9) {
        continue;
      }
      for (int col = pivot; col < n; ++col) {
        (*matrix)[(row * n) + col] -= factor * (*matrix)[(pivot * n) + col];
      }
      (*rhs)[row] -= factor * (*rhs)[pivot];
    }
  }

  return true;
}

void AddHomographyRows(const FeatureMatch& match,
                       std::vector<double>* normal,
                       std::vector<double>* rhs) {
  const double x = static_cast<double>(match.current.x);
  const double y = static_cast<double>(match.current.y);
  const double xp = static_cast<double>(match.anchor.x);
  const double yp = static_cast<double>(match.anchor.y);

  const std::array<double, 8> row_x = {x, y, 1.0, 0.0, 0.0, 0.0, -x * xp,
                                       -y * xp};
  const std::array<double, 8> row_y = {0.0, 0.0, 0.0, x, y, 1.0, -x * yp,
                                       -y * yp};

  for (int i = 0; i < 8; ++i) {
    (*rhs)[i] += row_x[i] * xp;
    for (int j = 0; j < 8; ++j) {
      (*normal)[(i * 8) + j] += row_x[i] * row_x[j];
    }
  }
  for (int i = 0; i < 8; ++i) {
    (*rhs)[i] += row_y[i] * yp;
    for (int j = 0; j < 8; ++j) {
      (*normal)[(i * 8) + j] += row_y[i] * row_y[j];
    }
  }
}

std::vector<double> EstimateHomography(
    const std::vector<const FeatureMatch*>& subset) {
  if (subset.size() < 4) {
    return {};
  }

  std::vector<double> normal(64, 0.0);
  std::vector<double> rhs(8, 0.0);
  for (const FeatureMatch* match : subset) {
    AddHomographyRows(*match, &normal, &rhs);
  }

  if (!SolveLinearSystem(&normal, &rhs, 8)) {
    return {};
  }

  return {rhs[0], rhs[1], rhs[2], rhs[3], rhs[4],
          rhs[5], rhs[6], rhs[7], 1.0};
}

std::pair<double, double> ApplyHomography(const std::vector<double>& transform,
                                          double x,
                                          double y) {
  const double w = (transform[6] * x) + (transform[7] * y) + transform[8];
  if (std::abs(w) < 1e-6) {
    return {std::numeric_limits<double>::infinity(),
            std::numeric_limits<double>::infinity()};
  }
  return {((transform[0] * x) + (transform[1] * y) + transform[2]) / w,
          ((transform[3] * x) + (transform[4] * y) + transform[5]) / w};
}

double ApproximateScale(const std::vector<double>& transform) {
  const double scale_x =
      std::sqrt((transform[0] * transform[0]) + (transform[3] * transform[3]));
  const double scale_y =
      std::sqrt((transform[1] * transform[1]) + (transform[4] * transform[4]));
  return std::clamp((scale_x + scale_y) * 0.5, 0.7, 1.35);
}

double ApproximateRotation(const std::vector<double>& transform) {
  return std::clamp(std::atan2(transform[3], transform[0]), -0.65, 0.65);
}

HomographyEstimate EvaluateHomography(const std::vector<double>& transform,
                                      const std::vector<FeatureMatch>& matches) {
  if (transform.size() != 9) {
    return HomographyEstimate{{}, 1.0, 0.0, {}, std::numeric_limits<double>::infinity()};
  }

  std::vector<FeatureMatch> inliers;
  double error_sum = 0.0;
  for (const FeatureMatch& match : matches) {
    const auto projection =
        ApplyHomography(transform, static_cast<double>(match.current.x),
                        static_cast<double>(match.current.y));
    if (!std::isfinite(projection.first) || !std::isfinite(projection.second)) {
      continue;
    }
    const double error = std::sqrt(
        std::pow(projection.first - match.anchor.x, 2.0) +
        std::pow(projection.second - match.anchor.y, 2.0));
    if (error <= 4.2) {
      inliers.push_back(match);
      error_sum += error;
    }
  }

  const double mean_error =
      inliers.empty() ? std::numeric_limits<double>::infinity()
                      : error_sum / static_cast<double>(inliers.size());
  return HomographyEstimate{transform, ApproximateScale(transform),
                            ApproximateRotation(transform), inliers,
                            mean_error};
}

bool IsBetter(const HomographyEstimate& candidate,
              const HomographyEstimate* best) {
  if (candidate.transform.size() != 9 || candidate.inliers.size() < 4) {
    return false;
  }
  if (best == nullptr) {
    return true;
  }
  if (candidate.inliers.size() != best->inliers.size()) {
    return candidate.inliers.size() > best->inliers.size();
  }
  return candidate.mean_error < best->mean_error;
}

HomographyEstimate RefineHomography(const std::vector<FeatureMatch>& inliers,
                                    const std::vector<FeatureMatch>& matches) {
  if (inliers.size() < 4) {
    return HomographyEstimate{{}, 1.0, 0.0, {}, std::numeric_limits<double>::infinity()};
  }

  std::vector<const FeatureMatch*> subset;
  subset.reserve(inliers.size());
  for (const FeatureMatch& match : inliers) {
    subset.push_back(&match);
  }

  const std::vector<double> transform = EstimateHomography(subset);
  return EvaluateHomography(transform, matches);
}

std::string EstimateTransformJsonInternal(const double* anchor_values,
                                          int32_t anchor_width,
                                          int32_t anchor_height,
                                          const double* current_values,
                                          int32_t current_width,
                                          int32_t current_height) {
  if (anchor_values == nullptr || current_values == nullptr ||
      anchor_width <= 0 || anchor_height <= 0 || current_width <= 0 ||
      current_height <= 0) {
    return "{}";
  }

  const SampleView anchor{anchor_values, anchor_width, anchor_height};
  const SampleView current{current_values, current_width, current_height};

  const std::vector<FeaturePoint> anchor_points = Detect(anchor);
  const std::vector<FeaturePoint> current_points = Detect(current);
  const std::vector<FeatureMatch> matches = Match(anchor_points, current_points);
  if (matches.size() < 4) {
    return "{}";
  }

  HomographyEstimate best{{}, 1.0, 0.0, {}, std::numeric_limits<double>::infinity()};
  bool found = false;
  const int candidate_count = std::min(static_cast<int>(matches.size()), 10);
  for (int i = 0; i < candidate_count; ++i) {
    for (int j = i + 1; j < candidate_count; ++j) {
      for (int k = j + 1; k < candidate_count; ++k) {
        for (int l = k + 1; l < candidate_count; ++l) {
          const std::vector<const FeatureMatch*> subset = {&matches[i], &matches[j],
                                                           &matches[k], &matches[l]};
          const HomographyEstimate candidate =
              EvaluateHomography(EstimateHomography(subset), matches);
          if (IsBetter(candidate, found ? &best : nullptr)) {
            best = candidate;
            found = true;
          }
        }
      }
    }
  }

  if (found && best.inliers.size() >= 4) {
    const HomographyEstimate refined = RefineHomography(best.inliers, matches);
    if (IsBetter(refined, &best)) {
      best = refined;
    }
  }

  if (!found || best.transform.size() != 9 || best.inliers.size() < 4) {
    return "{}";
  }

  const double mean_distance =
      matches.empty()
          ? 999.0
          : std::accumulate(matches.begin(), matches.end(), 0.0,
                            [](double sum, const FeatureMatch& match) {
                              return sum + match.distance;
                            }) /
                static_cast<double>(matches.size());
  const double confidence = std::clamp(
      ((static_cast<double>(best.inliers.size()) /
        static_cast<double>(std::max(static_cast<int>(matches.size()), 6))) *
           0.55) +
          ((1.0 - std::clamp(best.mean_error / 6.0, 0.0, 1.0)) * 0.3) +
          ((static_cast<double>(
                std::min(anchor_points.size(), current_points.size())) /
            36.0) *
           0.15),
      0.28, 0.995);

  std::ostringstream output;
  output << "{";
  output << "\"dx\":" << best.transform[2] << ",";
  output << "\"dy\":" << best.transform[5] << ",";
  output << "\"scale\":" << best.scale << ",";
  output << "\"rotationRadians\":" << best.rotation_radians << ",";
  output << "\"confidence\":" << confidence << ",";
  output << "\"anchorKeypoints\":" << anchor_points.size() << ",";
  output << "\"currentKeypoints\":" << current_points.size() << ",";
  output << "\"inlierCount\":" << best.inliers.size() << ",";
  output << "\"meanReprojectionError\":"
         << (std::isfinite(best.mean_error) ? best.mean_error : 999.0) << ",";
  output << "\"meanDescriptorDistance\":" << mean_distance << ",";
  output << "\"transform\":[";
  for (size_t i = 0; i < best.transform.size(); ++i) {
    if (i > 0) {
      output << ",";
    }
    output << best.transform[i];
  }
  output << "]}";
  return output.str();
}

}  // namespace

std::string estimate_transform_json(const double* anchor_values,
                                    int32_t anchor_width,
                                    int32_t anchor_height,
                                    const double* current_values,
                                    int32_t current_width,
                                    int32_t current_height) {
  return EstimateTransformJsonInternal(anchor_values, anchor_width, anchor_height,
                                       current_values, current_width,
                                       current_height);
}

}  // namespace nexthria
