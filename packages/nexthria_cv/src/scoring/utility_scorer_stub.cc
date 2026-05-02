#include "nexthria_cv_core.h"

namespace nexthria {

std::string utility_score_json() {
  return "{"
         "\"sharpness\":0.93,"
         "\"glareRatio\":0.07,"
         "\"vascularContrast\":0.79,"
         "\"illumination\":0.85,"
         "\"posteriorPoleFraming\":0.82,"
         "\"stableFocus\":0.87,"
         "\"diagnosticQuality\":0.89,"
         "\"mosaicUtility\":0.86,"
         "\"diagnosticPass\":true,"
         "\"retainForMosaic\":true,"
         "\"rejectionReasons\":[],"
         "\"weightedTotal\":0.86,"
         "\"keepFrame\":true"
         "}";
}

}  // namespace nexthria
