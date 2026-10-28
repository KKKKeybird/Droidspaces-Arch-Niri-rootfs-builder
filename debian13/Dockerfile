# Debian 13 aarch64 overlay on the proven Droidspaces Debian/Niri base.
# Base is created in GitHub Actions from a pinned upstream commit.
ARG BASE_IMAGE=droidspaces-debian13-niri:base
FROM debian:trixie AS ghostty-builder
ARG ENABLE_GHOSTTY=true
COPY debian13/scripts/download-ghostty.sh /usr/local/bin/download-ghostty
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl jq && \
    ENABLE_GHOSTTY="${ENABLE_GHOSTTY}" bash /usr/local/bin/download-ghostty

# Compile the Arch AUR Reef package from its real upstream source on ARM64.
# Reef uses Rust 2024 + let chains. Compile under newer Rust, keep Debian runtime.
FROM rust:1.90-trixie AS reef-builder
COPY debian13/scripts/progress.sh /usr/local/bin/ds-progress
ARG REEF_COMMIT=028f731b84e0beb0a59c73fb84ac3e415c36c7d7
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git pkg-config && \
    rustc --version && \
    git clone https://github.com/ZStud/reef /tmp/reef && \
    cd /tmp/reef && git checkout "${REEF_COMMIT}" && \
    bash /usr/local/bin/ds-progress run "Reef Cargo release compile" 20 \
      timeout -k 20s 1200s cargo build --locked --release && \
    test -x /tmp/reef/target/release/reef

FROM ${BASE_IMAGE} AS customizer
ARG USERNAME=colle
ARG ENABLE_GHOSTTY=true
ARG ENABLE_RIME=true
ARG ENABLE_NOCTALIA=true
ARG ENABLE_MAPLE_FONT=true
ARG ENABLE_REEF=true
ARG NIRI_AUTOSTART=true
ENV DEBIAN_FRONTEND=noninteractive
COPY --from=ghostty-builder /tmp/ghostty.deb /tmp/ghostty.deb
COPY --from=ghostty-builder /tmp/ghostty-source.txt /usr/share/doc/droidspaces-debian-niri/GHOSTTY-SOURCE.txt
COPY --from=reef-builder /tmp/reef/target/release/reef /usr/local/bin/reef
COPY --from=reef-builder /tmp/reef/fish/ /tmp/reef-fish/
COPY scripts/niri/default-config.kdl /tmp/arch-preset/default-config.kdl
COPY scripts/terminal/ /tmp/arch-preset/terminal/
COPY debian13/scripts/install-overlay.sh /usr/local/sbin/install-debian13-niri-overlay
COPY debian13/scripts/validate-overlay.sh /usr/local/sbin/validate-debian13-niri-overlay
RUN chmod +x /usr/local/sbin/*debian13-niri-overlay && \
    /usr/local/sbin/install-debian13-niri-overlay && \
    /usr/local/sbin/validate-debian13-niri-overlay && \
    rm -rf /tmp/arch-preset /var/lib/apt/lists/* /tmp/ghostty*
FROM scratch AS export
COPY --from=customizer / /
