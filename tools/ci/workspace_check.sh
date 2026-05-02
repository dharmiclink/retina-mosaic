#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."
(
  cd apps/mobile
  flutter analyze
  flutter test
)
(
  cd packages/nexthria_domain
  flutter test
)
