#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HDC="${HDC:-/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc}"
HAP="$PROJECT_DIR/entry/build/default/outputs/default/entry-default-signed.hap"

if [[ ! -f "$HAP" ]]; then
  "$PROJECT_DIR/scripts/build-app.sh" --stacktrace
fi

"$HDC" install -r "$HAP"
