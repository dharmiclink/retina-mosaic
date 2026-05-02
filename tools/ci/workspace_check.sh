#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."
flutter analyze apps/mobile
flutter test apps/mobile
flutter test packages/nexthria_domain
