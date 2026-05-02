#include "nexthria_cv_core.h"

namespace nexthria {

std::string guidance_vector_json() {
  return "{"
         "\"direction\":\"left\","
         "\"magnitude\":5.0,"
         "\"instruction\":\"Tilt device 5° left\","
         "\"confidence\":0.91"
         "}";
}

}  // namespace nexthria
