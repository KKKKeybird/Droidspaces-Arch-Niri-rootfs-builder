#!/usr/bin/env bash
set -euo pipefail
test "$(dpkg --print-architecture)" = arm64
test "$(grep -E '^VERSION_ID=' /etc/os-release | tr -d '"')" = VERSION_ID=13
test "$(systemctl --version | head -1 | awk '{print $2}')" = 257
test -x /usr/bin/niri-anland
test -x /usr/local/bin/droidspaces-terminal
test -f /etc/skel/.config/niri/config.kdl
test -f /etc/skel/.config/fish/config.fish
test -f /etc/skel/.config/fastfetch/config.jsonc
test -f /etc/droidspaces-desktop.conf
grep -q '^DESKTOP=niri$' /etc/droidspaces-desktop.conf
grep -q '^DISPLAY_BACKEND=anland-wayland$' /etc/droidspaces-desktop.conf
if [[ "${ENABLE_GHOSTTY:-true}" == true ]]; then test -x /usr/local/bin/ghostty; fi
if [[ "${ENABLE_NOCTALIA:-true}" == true ]]; then command -v noctalia; fi
echo "Debian 13 ARM64 Niri overlay preflight passed (device-side runtime still untested)."
