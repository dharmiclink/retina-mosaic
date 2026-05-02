# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(nexthria_cv_library VERSION 0.1.0 LANGUAGES CXX)

add_library(nexthria_cv SHARED
  "core/nexthria_cv.cc"
  "export/export_stub.cc"
  "guidance/operator_guidance_stub.cc"
  "mosaicking/mosaic_stub.cc"
  "mosaicking/mosaic_accumulator.cc"
  "scoring/utility_scorer_stub.cc"
  "tracking/gold_frame_tracker_stub.cc"
  "tracking/transform_estimator.cc"
)

target_include_directories(nexthria_cv PRIVATE "include")

set_target_properties(nexthria_cv PROPERTIES
  PUBLIC_HEADER "include/nexthria_cv.h"
  OUTPUT_NAME "nexthria_cv"
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED YES
)

target_compile_definitions(nexthria_cv PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(nexthria_cv PRIVATE "-Wl,-z,max-page-size=16384")
endif()
