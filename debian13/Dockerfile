# Debian 13 aarch64 overlay on the proven Droidspaces Debian/Niri base.
# Base is created in GitHub Actions from a pinned upstream commit.
ARG BASE_IMAGE=droidspaces-debian13-niri:base
FROM debian:trixie AS ghostty-builder
ARG ENABLE_GHOSTTY=true
ARG GHOSTTY_VERSION=1.3.1
ARG ZIG_VERSION=0.15.2
RUN if [ "$ENABLE_GHOSTTY" = "true" ]; then \
      apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl xz-utils tar pkg-config libgtk-4-dev \
        libgtk4-layer-shell-dev libadwaita-1-dev gettext libxml2-utils && \
      curl -fL --retry 3 "https://ziglang.org/download/${ZIG_VERSION}/zig-aarch64-linux-${ZIG_VERSION}.tar.xz" -o /tmp/zig.tar.xz && \
      mkdir -p /opt/zig && tar -xf /tmp/zig.tar.xz -C /opt/zig --strip-components=1 && \
      curl -fL --retry 3 "https://release.files.ghostty.org/${GHOSTTY_VERSION}/ghostty-${GHOSTTY_VERSION}.tar.gz" -o /tmp/ghostty.tar.gz && \
      mkdir -p /tmp/ghostty-src && tar -xf /tmp/ghostty.tar.gz -C /tmp/ghostty-src --strip-components=1 && \
      cd /tmp/ghostty-src && /opt/zig/zig build -p /usr/local -Doptimize=ReleaseFast -Dcpu=baseline && \
      test -x /usr/local/bin/ghostty; \
    fi

# Compile the Arch AUR Reef package from its real upstream source on ARM64.
# Debian 13 Rust toolchain supports the project's Rust 2024 edition.
FROM debian:trixie AS reef-builder
ARG REEF_COMMIT=028f731b84e0beb0a59c73fb84ac3e415c36c7d7
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git cargo rustc pkg-config && \
    git clone https://github.com/ZStud/reef /tmp/reef && \
    cd /tmp/reef && git checkout "${REEF_COMMIT}" && \
    cargo build --locked --release && \
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
COPY --from=ghostty-builder /usr/local/ /usr/local/
COPY --from=reef-builder /tmp/reef/target/release/reef /usr/local/bin/reef
COPY --from=reef-builder /tmp/reef/fish/ /tmp/reef-fish/
COPY scripts/niri/default-config.kdl /tmp/arch-preset/default-config.kdl
COPY scripts/terminal/ /tmp/arch-preset/terminal/
COPY debian13/scripts/install-overlay.sh /usr/local/sbin/install-debian13-niri-overlay
COPY debian13/scripts/validate-overlay.sh /usr/local/sbin/validate-debian13-niri-overlay
RUN chmod +x /usr/local/sbin/*debian13-niri-overlay && \
    /usr/local/sbin/install-debian13-niri-overlay && \
    /usr/local/sbin/validate-debian13-niri-overlay && \
    rm -rf /tmp/arch-preset /var/lib/apt/lists/* /tmp/zig* /tmp/ghostty*
FROM scratch AS export
COPY --from=customizer / /
