#!/usr/bin/env bash
# Debian replacement for the Arch-specific package and beautify phases.
set -euo pipefail
: "${USERNAME:?USERNAME missing}"
[[ "${USERNAME}" =~ ^[a-z_][a-z0-9_-]*$ ]] || { echo "Invalid USERNAME" >&2; exit 1; }
test -x /usr/bin/niri-anland || { echo "Base image must have the patched Debian ARM64 niri-anland package." >&2; exit 1; }
id "${USERNAME}" >/dev/null
home_dir="$(getent passwd "${USERNAME}" | cut -d: -f6)"
test -d "${home_dir}"
test "$(dpkg --print-architecture)" = arm64
installed_default() { command -v "$1" >/dev/null 2>&1; }
export DEBIAN_FRONTEND=noninteractive

apt-get update
# Debian package equivalents for original Arch desktop/utilities.
apt-get install -y --no-install-recommends \
 fish kitty fuzzel nemo nemo-fileroller cinnamon-translations \
 neovim fastfetch git curl wget unzip xz-utils zip p7zip-full \
 jq sudo dbus-user-session dbus-x11 xdg-utils xdg-user-dirs \
 fcitx5 fcitx5-rime fcitx5-config-qt \
 fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji \
 fontconfig gvfs gvfs-backends \
 pipewire wireplumber upower wl-clipboard \
 libgtk-4-1 libadwaita-1-0 libgtk4-layer-shell0 \
 ca-certificates

# Debian 13 has systemd 257; never copy Arch's systemd binaries or pacman locks.
systemd_major="$(systemctl --version | head -n1 | awk '{print $2}')"
if ! [[ "$systemd_major" =~ ^[0-9]+$ ]] || (( systemd_major > 257 )); then
  echo "Refusing incompatible systemd version: $systemd_major" >&2
  exit 1
fi

# Noctalia v5: Debian arm64 repository, as described in upstream official docs.
if [[ "${ENABLE_NOCTALIA}" == true ]]; then
  curl -fL --retry 3 https://pkg.noctalia.dev/deb/nickh-archive-keyring.deb -o /tmp/noctalia-keyring.deb
  dpkg -i /tmp/noctalia-keyring.deb
  curl -fL --retry 3 https://pkg.noctalia.dev/deb/noctalia-trixie.sources -o /etc/apt/sources.list.d/noctalia-trixie.sources
  apt-get update
  apt-get install -y --no-install-recommends noctalia
  installed_default noctalia
fi

if [[ "${ENABLE_GHOSTTY}" == true ]]; then
  installed_default ghostty || { echo "Ghostty builder produced no binary" >&2; exit 1; }
fi

# Original Arch preset files remain unchanged at their source path.
# Copy user configs to /etc/skel, then to the pre-created UID 1000 account.
mkdir -p /etc/skel/.config/fish/conf.d /etc/skel/.config/fish/functions \
  /etc/skel/.config/kitty/themes /etc/skel/.config/ghostty \
  /etc/skel/.config/fastfetch /etc/skel/.config/niri \
  /etc/skel/.config/fcitx5 /etc/skel/.config/gtk-3.0 \
  /etc/skel/.config/gtk-4.0 /etc/skel/.config/nvim
cp -a /tmp/arch-preset/terminal/fish/. /etc/skel/.config/fish/
cp -a /tmp/arch-preset/terminal/fastfetch/. /etc/skel/.config/fastfetch/
install -m644 /tmp/arch-preset/terminal/kitty.conf /etc/skel/.config/kitty/kitty.conf
install -m644 /tmp/arch-preset/terminal/ghostty-config /etc/skel/.config/ghostty/config
install -m755 /tmp/arch-preset/terminal/fastfetch/ff-shell-stack /usr/local/bin/ff-shell-stack
install -m755 /tmp/arch-preset/terminal/fastfetch/ff-sdks /usr/local/bin/ff-sdks
curl -fL --retry 3 https://raw.githubusercontent.com/catppuccin/kitty/main/themes/frappe.conf \
  -o /etc/skel/.config/kitty/themes/frappe.conf
curl -fL --retry 3 https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish \
  -o /etc/skel/.config/fish/functions/fisher.fish

# Reef is an Arch AUR-specific utility. Do not install an unverified Arch
# binary on Debian. Preserve the config but guard invocation until it is ported.
if ! installed_default reef; then
  sed -i 's/^[[:space:]]*reef on 2>\/dev\/null/    command -q reef; and reef on 2>\/dev\/null/' \
    /etc/skel/.config/fish/conf.d/reef.fish
  if [[ "${ENABLE_REEF}" == true ]]; then
    echo "ENABLE_REEF=true requested, but no verified Debian-native Reef build is provided." >&2
    exit 1
  fi
fi

if [[ "${ENABLE_MAPLE_FONT}" == true ]]; then
  install -d /usr/local/share/fonts/maple-mono
  curl -fL --retry 3 \
    https://github.com/subframe7536/maple-font/releases/download/v7.9/MapleMono-NF-CN.zip \
    -o /tmp/maple.zip
  unzip -q /tmp/maple.zip -d /usr/local/share/fonts/maple-mono
  fc-cache -f
fi

# Rime Ice may be updated independently by users; this is data, not Arch packages.
if [[ "${ENABLE_RIME}" == true ]]; then
  git clone --depth=1 https://github.com/iDvel/rime-ice /tmp/rime-ice
  mkdir -p /etc/skel/.local/share/fcitx5/rime
  cp -a /tmp/rime-ice/. /etc/skel/.local/share/fcitx5/rime/
  cat > /etc/skel/.config/fcitx5/profile <<'EOF'
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=rime

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=rime
Layout=

[GroupOrder]
0=Default
EOF
fi

printf '[Settings]\ngtk-application-prefer-dark-theme=true\n' > /etc/skel/.config/gtk-3.0/settings.ini
cp /etc/skel/.config/gtk-3.0/settings.ini /etc/skel/.config/gtk-4.0/settings.ini
cat > /etc/skel/.config/nvim/init.lua <<'EOF'
vim.opt.encoding = "utf-8"
vim.opt.number = true
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
EOF
install -d /usr/share/nemo/actions
cat > /usr/local/bin/droidspaces-terminal <<'EOF'
#!/usr/bin/env bash
if command -v ghostty >/dev/null 2>&1; then exec ghostty "$@"; fi
exec kitty "$@"
EOF
chmod +x /usr/local/bin/droidspaces-terminal
cat > /usr/share/nemo/actions/droidspaces-terminal.nemo_action <<'EOF'
[Nemo Action]
Name=Open in Terminal
Name[zh_CN]=在终端中打开
Exec=droidspaces-terminal
Icon=terminal
Selection=any
Extensions=any;
Dependencies=nemo;
EOF
mkdir -p /etc/xdg
printf '[Default Applications]\ninode/directory=nemo.desktop\n' > /etc/xdg/mimeapps.list

# Keep the original Niri preset, but replace Arch-only launch commands.
install -m644 /tmp/arch-preset/default-config.kdl /etc/skel/.config/niri/config.kdl
sed -i 's/spawn-at-startup "waybar"/spawn-at-startup "noctalia"/g' /etc/skel/.config/niri/config.kdl
sed -i 's/spawn "alacritty"/spawn "droidspaces-terminal"/g' /etc/skel/.config/niri/config.kdl
if [[ "${ENABLE_NOCTALIA}" == true ]] && ! grep -q 'spawn-at-startup "noctalia"' /etc/skel/.config/niri/config.kdl; then
  printf '\nspawn-at-startup "noctalia"\n' >> /etc/skel/.config/niri/config.kdl
fi
if [[ "${ENABLE_RIME}" == true ]] && ! grep -q 'spawn-at-startup "fcitx5"' /etc/skel/.config/niri/config.kdl; then
  printf '\nspawn-at-startup "fcitx5" "-d"\n' >> /etc/skel/.config/niri/config.kdl
fi

# Never discard original base's display backend variables; append only absent keys.
append_env() {
  local key="${1%%=*}"
  grep -q "^${key}=" /etc/environment || printf '%s\n' "$1" >> /etc/environment
}
append_env XDG_CURRENT_DESKTOP=niri
append_env XDG_SESSION_TYPE=wayland
append_env ANLAND=1
append_env ANLAND_SOCKET=/run/display.sock
if [[ "${ENABLE_RIME}" == true ]]; then
  append_env XMODIFIERS=@im=fcitx
  append_env GTK_IM_MODULE=fcitx
  append_env QT_IM_MODULE=fcitx
fi

# Make skel and active user's settings identical.
install -d -m700 -o "${USERNAME}" -g "${USERNAME}" "${home_dir}/.config" "${home_dir}/.local/share"
cp -a /etc/skel/.config/. "${home_dir}/.config/"
if [[ -d /etc/skel/.local ]]; then cp -a /etc/skel/.local/. "${home_dir}/.local/"; fi
chown -R "${USERNAME}:${USERNAME}" "${home_dir}/.config" "${home_dir}/.local"

# Fisher/Tide and source profile are installed as the actual user, not root.
runuser -u "${USERNAME}" -- env HOME="${home_dir}" fish -c 'fisher install ilancosman/tide@v6'
runuser -u "${USERNAME}" -- env HOME="${home_dir}" fish "${home_dir}/.config/fish/tide-apply.fish"
chsh -s /usr/bin/fish "${USERNAME}"

# Use the base builder's systemd desktop-session.service. It launches niri-anland
# with its established Anland vars; do not create a second competing niri.service.
if [[ "${NIRI_AUTOSTART}" != true ]]; then
  rm -f /etc/systemd/system/multi-user.target.wants/desktop-session.service
fi
printf '%s\n' "base=Goldzxcbug/Droidspaces-rootfs-Desktop-builder" \
  "distribution=Debian_13" "arch=arm64" "compositor=niri-anland" \
  "noctalia=${ENABLE_NOCTALIA}" "ghostty=${ENABLE_GHOSTTY}" \
  "rime=${ENABLE_RIME}" "reef=unported" > /etc/droidspaces-debian-niri-provenance
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/rime-ice /tmp/maple.zip /tmp/noctalia-keyring.deb
