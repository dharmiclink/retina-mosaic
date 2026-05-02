#include "nexthria_cv_core.h"

namespace nexthria {

std::string export_json() {
  return "{"
         "\"primaryDiagnosticJpegPath\":\"exports/phase0/primary_diagnostic.jpeg\","
         "\"mosaicJpegPath\":\"exports/phase0/mosaic.jpeg\","
         "\"goldFramesArchivePath\":\"exports/phase0/gold_frames.zip\","
         "\"metadataJsonPath\":\"exports/phase0/metadata.json\","
         "\"eyeLaterality\":\"unknown\","
         "\"bestDiagnosticFrameId\":\"frame-18\","
         "\"bestDiagnosticScore\":0.89,"
         "\"diagnosticCapturePassed\":true,"
         "\"selectionMode\":\"auto\","
         "\"autoSuggestedFrameId\":\"frame-18\","
         "\"finalSelectedFrameId\":\"frame-18\","
         "\"captureProfileVersion\":\"nexeye-capture-v1\""
         "}";
}

}  // namespace nexthria
