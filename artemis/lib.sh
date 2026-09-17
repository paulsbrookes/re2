#!/usr/bin/env bash
# Shared helpers for the Artemis harness adapter. Sourced, not executed.

# sync_workspace: mirror the checkout into a persistent workspace so builds
# pay incremental cost. Excludes build output and .git; exports WORKSPACE.
sync_workspace() {
  local checkout
  checkout="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  WORKSPACE="${HARD_OSS_WORKSPACE_ROOT:-/var/tmp/hard-oss-workspaces}/re2"
  mkdir -p "${WORKSPACE}"
  rsync -rlpgoD --checksum --delete \
    --exclude='/build/' \
    --exclude='/.git/' \
    --exclude='/artemis_results.json' \
    "${checkout}/" "${WORKSPACE}/"
  export WORKSPACE
  echo "[lib] workspace ${WORKSPACE}" >&2
}
