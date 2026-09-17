#!/usr/bin/env bash
# Build the pinned external dependencies re2 needs (abseil-cpp, googletest,
# google benchmark) into a cache prefix outside the checkout. Idempotent: a
# no-op when the prefix already carries abseil's CMake package config.
set -euo pipefail

DEPS_ROOT="${HARD_OSS_DEPS_ROOT:-/var/tmp/hard-oss-deps}/re2"
PREFIX="${DEPS_ROOT}/prefix"
SRC="${DEPS_ROOT}/src"

ABSL_TAG="20250814.1"
GTEST_TAG="v1.17.0"
BENCHMARK_TAG="v1.9.4"
JOBS="${HARD_OSS_JOBS:-8}"

if [ -d "${PREFIX}/lib/cmake/absl" ]; then
  echo "[deps] prefix present: ${PREFIX}" >&2
  exit 0
fi

echo "[deps] building pinned dependencies into ${PREFIX}" >&2
mkdir -p "${SRC}" "${PREFIX}"

fetch() { # name url tag
  local dir="${SRC}/$1"
  if [ ! -d "${dir}/.git" ]; then
    rm -rf "${dir}"
    git clone -q --depth 1 --branch "$3" "$2" "${dir}"
  fi
  echo "[deps] $1 $(git -C "${dir}" describe --tags --always)" >&2
}

build() { # name extra cmake flags...
  local name="$1"; shift
  local dir="${SRC}/${name}"
  rm -rf "${dir}/build"
  cmake -S "${dir}" -B "${dir}/build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    "$@" >&2
  cmake --build "${dir}/build" -j"${JOBS}" >&2
  cmake --install "${dir}/build" >&2
}

fetch abseil-cpp https://github.com/abseil/abseil-cpp.git "${ABSL_TAG}"
fetch googletest  https://github.com/google/googletest.git "${GTEST_TAG}"
fetch benchmark   https://github.com/google/benchmark.git  "${BENCHMARK_TAG}"

build abseil-cpp -DCMAKE_CXX_STANDARD=17 -DABSL_PROPAGATE_CXX_STD=ON \
  -DABSL_ENABLE_INSTALL=ON -DABSL_BUILD_TESTING=OFF
build googletest
build benchmark -DBENCHMARK_ENABLE_TESTING=OFF -DBENCHMARK_ENABLE_GTEST_TESTS=OFF

[ -d "${PREFIX}/lib/cmake/absl" ] || { echo "[deps] abseil install missing" >&2; exit 1; }
echo "[deps] done" >&2
