#!/usr/bin/env bash
set -euo pipefail

flutter_root="${TMPDIR:-/tmp}/flutter"

if [ ! -x "$flutter_root/bin/flutter" ]; then
  git clone --depth 1 --branch 3.44.0 \
    https://github.com/flutter/flutter.git "$flutter_root"
fi

"$flutter_root/bin/flutter" build web --release \
  "--dart-define=CLEAN_NOW_API_URL=https://${VERCEL_PROJECT_PRODUCTION_URL}/api" \
  "--dart-define=CLEAN_NOW_PUBLIC_URL=https://${VERCEL_PROJECT_PRODUCTION_URL}"
