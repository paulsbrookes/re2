#!/usr/bin/env bash
# Artemis test command: the fifteen fast deterministic tests identified during
# screening, run via ctest in the persistent workspace.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${HERE}/lib.sh"

# Rebuild (incremental, no-op when unchanged) so binaries match the synced source.
bash "${HERE}/compile.sh"

sync_workspace
cd "${WORKSPACE}"
[ -f build/CTestTestfile.cmake ] || { echo "[test] no build; run artemis/compile.sh first" >&2; exit 1; }

TESTS='^(search_test|re2_test|dfa_test|compile_test|possible_match_test|set_test|simplify_test|parse_test|charclass_test|required_prefix_test|re2_arg_test|regexp_test|filtered_re2_test|mimics_pcre_test|string_generator_test)$'
echo "[test] ctest ${TESTS}" >&2
ctest --test-dir build -j8 --output-on-failure -R "${TESTS}" >&2
echo "[test] ok" >&2
