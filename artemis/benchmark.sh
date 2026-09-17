#!/usr/bin/env bash
# Artemis benchmark command: run the fixed single-threaded regexp_benchmark
# subset at 32 KiB and write artemis_results.json to the checkout root.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKOUT="$(cd "${HERE}/.." && pwd)"
# shellcheck source=lib.sh
source "${HERE}/lib.sh"

# Rebuild (incremental, no-op when unchanged) so binaries match the synced source.
bash "${HERE}/compile.sh"

rm -f "${CHECKOUT}/artemis_results.json"
sync_workspace
rm -f "${WORKSPACE}/artemis_results.json" "${WORKSPACE}/bench.json"
cd "${WORKSPACE}"
[ -x build/regexp_benchmark ] || { echo "[bench] no build; run artemis/compile.sh first" >&2; exit 1; }

FILTER='^Search_(Easy0|Medium|Hard|Parens|Success|Fanout)_CachedDFA/32768/threads:1$|^Search_AltMatch_DFA/32768/threads:1$|^Search_Success_CachedNFA/32768/threads:1$'
echo "[bench] regexp_benchmark ${FILTER}" >&2
./build/regexp_benchmark \
  --benchmark_filter="${FILTER}" \
  --benchmark_min_time=5000x \
  --benchmark_format=json \
  --benchmark_out="${WORKSPACE}/bench.json" >&2

TMP="${CHECKOUT}/.artemis_results.json.tmp"
python3 - "${WORKSPACE}/bench.json" "${TMP}" <<'PY'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
with open(src) as f:
    data = json.load(f)
items = ["Search_Easy0_CachedDFA", "Search_Medium_CachedDFA", "Search_Hard_CachedDFA",
         "Search_Parens_CachedDFA", "Search_Success_CachedDFA", "Search_Fanout_CachedDFA",
         "Search_AltMatch_DFA", "Search_Success_CachedNFA"]
by_name = {}
for b in data.get("benchmarks", []):
    if b.get("run_type", "iteration") != "iteration":
        continue
    if b.get("error_occurred"):
        sys.exit("[bench] error in %s: %s" % (b.get("name"), b.get("error_message")))
    if b.get("time_unit") != "ns":
        sys.exit("[bench] unexpected time unit for %s: %s" % (b.get("name"), b.get("time_unit")))
    by_name[b["name"]] = float(b["real_time"])
values = {}
for it in items:
    name = it + "/32768/threads:1"
    if name not in by_name:
        sys.exit("[bench] missing benchmark item: " + name)
    values[it] = by_name[name]
out = {"search_hard_cached_dfa_ns": values["Search_Hard_CachedDFA"],
       "sum_ns": sum(values.values())}
for it in items:
    out[it.lower() + "_ns"] = values[it]
with open(dst, "w") as f:
    json.dump(out, f, indent=1)
    f.write("\n")
print("[bench] search_hard_cached_dfa_ns=%.1f sum_ns=%.1f" % (out["search_hard_cached_dfa_ns"], out["sum_ns"]), file=sys.stderr)
PY
mv -f "${TMP}" "${CHECKOUT}/artemis_results.json"
echo "[bench] wrote ${CHECKOUT}/artemis_results.json" >&2
