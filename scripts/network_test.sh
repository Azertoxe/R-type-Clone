#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
PORT="${1:-12345}"
DURATION_SEC="${2:-20}"
LOG_DIR="${ROOT_DIR}/build/network-test-logs"
mkdir -p "${LOG_DIR}"

SERVER_LOG="${LOG_DIR}/server.log"
CLIENT1_LOG="${LOG_DIR}/client1.log"
CLIENT2_LOG="${LOG_DIR}/client2.log"

SERVER_BIN="${BUILD_DIR}/r-type_server"
CLIENT_BIN="${BUILD_DIR}/r-type_client"

if [[ ! -x "${SERVER_BIN}" || ! -x "${CLIENT_BIN}" ]]; then
  echo "[network_test] Build binaries not found in ${BUILD_DIR}."
  echo "[network_test] Build first: python3 build.py"
  exit 1
fi

export LD_LIBRARY_PATH="${BUILD_DIR}:${BUILD_DIR}/lib:${LD_LIBRARY_PATH:-}"

cleanup() {
  set +e
  if [[ -n "${CLIENT1_PID:-}" ]]; then kill "${CLIENT1_PID}" 2>/dev/null || true; fi
  if [[ -n "${CLIENT2_PID:-}" ]]; then kill "${CLIENT2_PID}" 2>/dev/null || true; fi
  if [[ -n "${SERVER_PID:-}" ]]; then kill "${SERVER_PID}" 2>/dev/null || true; fi
}
trap cleanup EXIT INT TERM

search_logs() {
  local pattern="$1"
  local file="$2"
  if command -v rg >/dev/null 2>&1; then
    rg -n "${pattern}" "${file}" || true
  else
    grep -En "${pattern}" "${file}" || true
  fi
}

run_client() {
  local log_file="$1"
  if command -v xvfb-run >/dev/null 2>&1; then
    xvfb-run -a "${CLIENT_BIN}" 127.0.0.1 "${PORT}" >"${log_file}" 2>&1 &
  else
    "${CLIENT_BIN}" 127.0.0.1 "${PORT}" >"${log_file}" 2>&1 &
  fi
  echo $!
}

"${SERVER_BIN}" "${PORT}" >"${SERVER_LOG}" 2>&1 &
SERVER_PID=$!

echo "[network_test] Server started (pid=${SERVER_PID}, port=${PORT})"
sleep 2

CLIENT1_PID="$(run_client "${CLIENT1_LOG}")"
echo "[network_test] Client #1 started (pid=${CLIENT1_PID})"
sleep 2

CLIENT2_PID="$(run_client "${CLIENT2_LOG}")"
echo "[network_test] Client #2 started (pid=${CLIENT2_PID})"

echo "[network_test] Running for ${DURATION_SEC}s..."
sleep "${DURATION_SEC}"

echo

echo "[network_test] ---- Network summary (server) ----"
search_logs "PLAYER_JOIN|PLAYER_READY|GAME_START|ClientConnected|ClientDisconnected|Client Connected|Client Disconnected|Lobby join|Lobby ready|NetworkError|ReliableMessageTimeout" "${SERVER_LOG}"

echo

echo "[network_test] ---- Client #1 summary ----"
search_logs "PLAYER_ASSIGN|GAME_START|NetworkError|Assigned Player ID|GAME_WON|Lobby|Connected:" "${CLIENT1_LOG}"

echo

echo "[network_test] ---- Client #2 summary ----"
search_logs "PLAYER_ASSIGN|GAME_START|NetworkError|Assigned Player ID|GAME_WON|Lobby|Connected:" "${CLIENT2_LOG}"

echo

echo "[network_test] Logs written in ${LOG_DIR}"
