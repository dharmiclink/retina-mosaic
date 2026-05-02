#include "nexthria_cv_core.h"

namespace nexthria {

std::string mosaic_update_json() {
  return "{"
         "\"transform\":[1.0,0.0,18.0,0.0,1.0,-10.0,0.0,0.0,1.0],"
         "\"coveragePercent\":67.0,"
         "\"unresolvedHolesMask\":\"mask://phase0/holes\","
         "\"confidenceSummary\":{"
         "\"meanConfidence\":0.84,"
         "\"minConfidence\":0.52,"
         "\"maxConfidence\":0.98"
         "}"
         "}";
}

}  // namespace nexthria
