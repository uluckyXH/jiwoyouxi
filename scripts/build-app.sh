#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVECO_APP="${DEVECO_STUDIO_APP:-/Applications/DevEco-Studio.app}"
NODE_HOME="${NODE_HOME:-$DEVECO_APP/Contents/tools/node}"
HVIGORW="${HVIGORW:-$DEVECO_APP/Contents/tools/hvigor/bin/hvigorw}"

export DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-$DEVECO_APP/Contents/sdk}"
export JAVA_HOME="${JAVA_HOME:-$DEVECO_APP/Contents/jbr/Contents/Home}"

cd "$PROJECT_DIR"
"$HVIGORW" assembleApp --node-home "$NODE_HOME" --no-daemon "$@"
