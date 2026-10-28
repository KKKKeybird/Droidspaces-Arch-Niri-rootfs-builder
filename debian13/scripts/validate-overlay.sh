#!/usr/bin/env bash
# Static build-time checks only; hardware and systemd boot require a real device.
set -euo pipefail
test "$(dpkg --print-architecture)" = arm64
grep -q '^VERSION_ID="\?13"\?$' /etc/os-release
systemd_major="$(systemctl --version | head -n1 | awk '{print $2}')"
[[ "${systemd_major}" =~ ^[0-9]+$ ]]
(( systemd_major <= 257 ))
test -x /usr/bin/niri-anland
test -x /usr/local/bin/droidspaces-terminal
test -x /usr/local/bin/reef
test -f /etc/skel/.config/niri/config.kdl
test -f /etc/skel/.config/fish/config.fish
test -f /etc/skel/.config/fastfetch/config.jsonc
test -f /etc/droidspaces-desktop.conf
grep -qx 'DESKTOP=niri' /etc/droidspaces-desktop.conf
grep -qx 'DISPLAY_BACKEND=anland-wayland' /etc/droidspaces-desktop.conf
command -v fish
command -v nemo
command -v fcitx5
command -v fuzzel
if [[ "${ENABLE_GHOSTTY:-true}" == true ]]; then command -v ghostty >/dev/null && test "$(dpkg-query -W -f='${Architecture}' ghostty)" = arm64; fi
if [[ "${ENABLE_NOCTALIA:-true}" == true ]]; then command -v noctalia; fi
/usr/bin/niri-anland validate --config /etc/skel/.config/niri/config.kdl
echo "Debian 13 ARM64 Niri overlay preflight passed (device runtime not tested)."
