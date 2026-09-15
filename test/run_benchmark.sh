#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COUNT="${1:-10000}"

cd "$ROOT_DIR"

if [[ ! -x ./bin/raftCoreRun || ! -x ./bin/benchmarkMain ]]; then
  echo "Missing binaries. Build the project first with: cmake --build build -j"
  exit 1
fi

pkill -f "$ROOT_DIR/bin/raftCoreRun" 2>/dev/null || true
rm -f raftstatePersist*.txt snapshotPersist*.txt

./bin/raftCoreRun -n 3 -f test.conf > server.log 2>&1 &
SERVER_PID=$!

cleanup() {
  pkill -f "$ROOT_DIR/bin/raftCoreRun" 2>/dev/null || true
  kill "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

for _ in {1..20}; do
  if [[ -f test.conf ]] &&
     mapfile -t ports < <(awk -F= '/^node[0-9]+port=/{print $2}' test.conf) &&
     [[ "${#ports[@]}" -eq 3 ]] &&
     ((${#ports[@]} == 3)); then
    ready=true
    for port in "${ports[@]}"; do
      if ! ss -ltn | grep -q ":${port} "; then
        ready=false
        break
      fi
    done
    if [[ "$ready" == true ]]; then
      break
    fi
  fi
  sleep 1
done

if [[ "${ready:-false}" != true ]]; then
  echo "Raft servers did not become ready. Check server.log"
  exit 1
fi

./bin/benchmarkMain test.conf "$COUNT"
