#!/usr/bin/env bash
# Resolve latest verified compatible Trixie ARM64 Ghostty package.
# No Zig or compiler on GitHub Actions or target Android container.
set -Eeuo pipefail
if [[ "${ENABLE_GHOSTTY:-true}" != true ]]; then
  : > /tmp/ghostty.deb
  printf 'disabled=true\n' > /tmp/ghostty-source.txt
  echo "[ghostty] disabled by workflow input"
  exit 0
fi
api="https://api.github.com/repos/mkasberg/ghostty-ubuntu/releases?per_page=30"
echo "[ghostty] Looking for newest published Trixie arm64 release"
releases="$(curl -fsSL --retry 4 --retry-all-errors --connect-timeout 20 --max-time 120 "$api")"
asset="$(jq -er '
 [ .[]
   | select(.draft != true and .prerelease != true)
   | . as $release
   | .assets[]?
   | select(.name | test("^ghostty_[^/]+_arm64_trixie[.]deb$"))
   | {tag:$release.tag_name, published:$release.published_at,
      name:.name, url:.browser_download_url, digest:.digest}
 ] | sort_by(.published) | last
' <<< "$releases")" || { echo "::error::No compatible Ghostty Trixie ARM64 asset was found"; exit 1; }
url="$(jq -er '.url' <<< "$asset")"
name="$(jq -er '.name' <<< "$asset")"
tag="$(jq -er '.tag' <<< "$asset")"
digest="$(jq -er '.digest' <<< "$asset")"
[[ "$name" =~ ^ghostty_[^/]+_arm64_trixie[.]deb$ ]] || exit 1
[[ "$url" == https://github.com/mkasberg/ghostty-ubuntu/releases/download/* ]] || exit 1
[[ "$digest" =~ ^sha256:[a-f0-9]{64}$ ]] || { echo "::error::Missing GitHub asset SHA256 digest"; exit 1; }
echo "[ghostty] Selected compatible release: $tag"
echo "[ghostty] Asset: $name"
curl -fL --retry 4 --retry-all-errors --connect-timeout 20 --max-time 360 "$url" -o /tmp/ghostty.deb
printf '%s  /tmp/ghostty.deb\n' "${digest#sha256:}" | sha256sum --check --status
echo "[ghostty] SHA256 verified: ${digest#sha256:}"
[[ "$(dpkg-deb -f /tmp/ghostty.deb Package)" == ghostty ]] || exit 1
[[ "$(dpkg-deb -f /tmp/ghostty.deb Architecture)" == arm64 ]] || exit 1
printf 'provider=mkasberg/ghostty-ubuntu\nrelease_tag=%s\nasset=%s\nsha256=%s\n' \
 "$tag" "$name" "${digest#sha256:}" > /tmp/ghostty-source.txt
echo "[ghostty] Trixie ARM64 .deb validated successfully"
