#!/usr/bin/env bash
# Artemis compile command: ensure deps, sync the workspace, configure and build.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${HERE}/lib.sh"

bash "${HERE}/deps.sh"
PREFIX="${HARD_OSS_DEPS_ROOT:-/var/tmp/hard-oss-deps}/re2/prefix"

sync_workspace
cd "${WORKSPACE}"

echo "[compile] configure" >&2
cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_FLAGS='-O3 -DNDEBUG' \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DRE2_BUILD_TESTING=ON >&2
echo "[compile] build" >&2
cmake --build build -j8 >&2
echo "[compile] ok" >&2
