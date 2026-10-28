# Debian 13 ARM64 · Niri / Noctalia port

This is the **Debian 13 migration branch** of [collegeming/Droidspaces-Arch-Niri-rootfs-builder](https://github.com/collegeming/Droidspaces-Arch-Niri-rootfs-builder). Arch remains unchanged on `main`.

The workflow starts from a pinned [Goldzxcbug Droidspaces Debian 13 builder](https://github.com/Goldzxcbug/Droidspaces-rootfs-Desktop-builder) (commit `24189f46b4608d312f654d9f53a48e25a214001c`) and installs its patched **niri-anland** Debian ARM64 packages. The fork's original Niri KDL, terminal Fish/Fisher/Tide, fastfetch, Kitty, Ghostty configuration, Maple Mono font and Chinese input presets are then migrated without copying Arch binaries.

## Build

Actions → **Build Debian 13 ARM64 Niri + Noctalia RootFS** → Run workflow. Runs on native `ubuntu-24.04-arm`; builds optional Ghostty from the official source tarball with Zig 0.15.2; exports a `.tar.xz` artifact and SHA256SUMS. It does not need to compile on your phone.

## Features

- Debian 13 / systemd 257 (no Arch systemd replacement or pacman)
- niri-anland / Anland Wayland, Noctalia (APT), Fuzzel
- Ghostty 1.3.1 compiled on Actions (default), Kitty fallback, Nemo
- Fish + Fisher + Tide, original presets and Catppuccin Frappe
- Fcitx5 + Rime Ice, CJK fonts and Maple Mono NF CN
- Fastfetch, Neovim, GVfs, PipeWire, WirePlumber
- Original launcher and shortcuts are migrated from `scripts/niri/default-config.kdl`

**Outstanding differences:** `reef` and `reef-tools` were installed from AUR by the Arch builder; no vetted Debian ARM64 build has been identified. The Fish Reef hook is preserved but guarded, so the shell remains usable. No AUR, pacman, `makepkg`, `IgnorePkg`, or Arch's systemd binary override is used. If the Noctalia v5 CLI or patched Niri config syntax differs from Arch's preset, the device may require edits. The build is experimental until CI passes and a 4.19 device is tested.

## Droidspaces import

Import the artifact archive as an ARM64 rootfs into a **new container**. Keep the existing Artix container. Set up matching Anland APK/daemon for your device; bind `/data/local/tmp/display_daemon.sock` to `/run/display.sock`, enable the required GPU hardware access, and follow the upstream Anland security and SELinux guidance. In the container, `systemctl status desktop-session.service` and `/usr/bin/niri-anland` are the relevant entry points; do not use the Arch `niri.service`.

**Important:** The upstream Debian builder uses an initial password `1234`. Change it immediately after import. A successful CI build checks file/package presence, **not** systemd boot, driver, graphics, audio, or 4.19 runtime compatibility.

## Provenance

- [Arch Niri source/presets](https://github.com/collegeming/Droidspaces-Arch-Niri-rootfs-builder)
- [Debian base and niri-anland installer](https://github.com/Goldzxcbug/Droidspaces-rootfs-Desktop-builder)
- [Noctalia APT installation](https://docs.noctalia.dev/noctalia/getting-started/installation/)
- [Ghostty build docs](https://ghostty.org/docs/install/build)
