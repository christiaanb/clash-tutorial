FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

USER root

# Build tools GHC/Stack need to compile packages with C dependencies
# (clash-prelude and friends pull these in transitively).
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        libgmp-dev \
        libnuma-dev \
        zlib1g-dev \
        libtinfo-dev \
        libncurses-dev \
        pkg-config \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# NVC 1.20.1 — pinned per design/00-decisions.md (D5) and .github/workflows/ci.yml.
# The Ubuntu 24.04 .deb from upstream matches this image's release.
RUN curl -fsSL -o /tmp/nvc.deb \
        https://github.com/nickg/nvc/releases/download/r1.20.1/nvc_1.20.1-1_amd64_ubuntu-24.04.deb \
    && apt-get update \
    && (dpkg -i /tmp/nvc.deb || apt-get install -y -f) \
    && rm -f /tmp/nvc.deb && rm -rf /var/lib/apt/lists/*

# mdBook — matches the `latest` pin used by the `book` job in ci.yml.
RUN url=$(curl -fsSL https://api.github.com/repos/rust-lang/mdBook/releases/latest \
        | grep -o 'https://[^"]*x86_64-unknown-linux-gnu\.tar\.gz') \
    && curl -fsSL -o /tmp/mdbook.tar.gz "$url" \
    && tar -xzf /tmp/mdbook.tar.gz -C /usr/local/bin mdbook \
    && rm -f /tmp/mdbook.tar.gz

USER vscode

# GHCup + Stack. GHC itself is deliberately left for `stack setup` to fetch,
# since it downloads the exact version each project's resolver pins (D7) —
# installing one via GHCup as well would just be a second, unused copy.
ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_MINIMAL=1 \
    BOOTSTRAP_HASKELL_ADJUST_BASHRC=1
RUN curl -fsSL https://get-ghcup.haskell.org | sh \
    && ~/.ghcup/bin/ghcup install stack

ENV PATH="/home/vscode/.ghcup/bin:/home/vscode/.local/bin:${PATH}"
