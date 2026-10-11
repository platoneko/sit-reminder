#!/bin/zsh
set -euo pipefail
# Quit must succeed while the start dialog is up (Dock / tell app to quit).
pid=$(pgrep -f "${HOME}/Applications/久坐提醒.app/Contents/MacOS/applet" | head -1 || true)
if [[ -z "${pid}" ]]; then
  echo "FAIL: 久坐提醒 is not running"
  exit 1
fi

osascript -e 'tell application id "local.sit-reminder" to quit' >/dev/null 2>&1 &
osa=$!
for _ in {1..20}; do
  if ! ps -p "${pid}" >/dev/null 2>&1; then
    kill "${osa}" 2>/dev/null || true
    wait "${osa}" 2>/dev/null || true
    echo "PASS: process ${pid} exited after quit"
    exit 0
  fi
  sleep 0.25
done
kill "${osa}" 2>/dev/null || true
wait "${osa}" 2>/dev/null || true
echo "FAIL: process ${pid} still running after quit"
exit 1
