# Build stage: use Rust to compile the project to WASM/WASIX
FROM rust:1.92 AS builder

RUN apt-get update && apt-get install -y git libssl-dev pkg-config curl build-essential binutils cmake libstdc++-12-dev xz-utils

# Install LLVM/Clang from GitHub release
RUN curl -L https://github.com/llvm/llvm-project/releases/download/llvmorg-22.1.0/LLVM-22.1.0-Linux-X64.tar.xz -o llvm.tar.xz && \
    mkdir -p /opt/llvm && \
    tar -xJf llvm.tar.xz -C /opt/llvm --strip-components=1 && \
    rm llvm.tar.xz

ENV PATH="/opt/llvm/bin:${PATH}"
ENV CC=clang
ENV AR=llvm-ar
ENV LD=ld.lld

# Install Wasmer
RUN curl https://get.wasmer.io -sSfL | sh
ENV PATH="/root/.wasmer/bin:${PATH}"

# Install cargo-wasix
RUN cargo install cargo-wasix

WORKDIR /app
COPY . .

# Build the WASIX-based EVM using cargo-wasix
WORKDIR /app/wasix-based-evm

# Configure RUSTFLAGS separately for host and target to prevent conflicts.
# The host (builder) uses lld for standard builds.
ENV RUSTFLAGS_HOST="-C linker=clang -C link-arg=-fuse-ld=lld"
# The target (WASM) needs specific features for WASIX thread support and atomics.
# We also ensure the linker uses lld for WASM-side linking and provides the thread-related flags.
# Using the installed LLVM/Clang.
ENV CARGO_TARGET_WASM32_WASMER_WASI_RUSTFLAGS="-C target-feature=+atomics,+bulk-memory,+mutable-globals -C link-arg=--shared-memory -C link-arg=--max-memory=4294967296 -C link-arg=--import-memory -C link-arg=--export-dynamic -C linker-flavor=gcc -C linker=clang -C link-arg=-fuse-ld=lld"

# Pre-download and setup the wasix toolchain (ignore first error as it's for toolchain setup)
RUN RUSTFLAGS=$RUSTFLAGS_HOST cargo wasix build --release || true

# Robustly link the host's cargo to the toolchain's bin directory
# and set the CARGO environment variable to the host's cargo
RUN TOOLCHAIN_BIN=$(find /root/.local/share/cargo-wasix/toolchains -name bin -type d | head -n 1); \
    if [ -n "$TOOLCHAIN_BIN" ]; then \
        ln -sf $(which cargo) "$TOOLCHAIN_BIN/cargo"; \
        echo "Linked cargo to $TOOLCHAIN_BIN/cargo"; \
    fi

# Now run the actual build
# Using RUSTUP_TOOLCHAIN=stable avoids the custom 'wasix' toolchain's cargo check
# while still utilizing the wasm32-wasmer-wasi target that cargo-wasix enables.
RUN RUSTUP_TOOLCHAIN=stable RUSTFLAGS=$RUSTFLAGS_HOST cargo wasix build --release

# Final stage: minimal image with Wasmer to run the client
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y curl jq iproute2 && rm -rf /var/lib/apt/lists/*

# Install Wasmer in the final image
RUN curl https://get.wasmer.io -sSfL | sh
ENV PATH="/root/.wasmer/bin:${PATH}"

# Hive requirements
RUN mkdir -p /hive-bin /data-dir

COPY --from=builder /app/wasix-based-evm/target/wasm32-wasmer-wasi/release/wasix-based-evm.wasi.wasm /app/wasix-evm.wasm
COPY hive/clients/wasix-evm/wasix-evm.sh /app/wasix-evm.sh
COPY hive/clients/wasix-evm/enode.sh /hive-bin/enode.sh

RUN chmod +x /app/wasix-evm.sh /hive-bin/enode.sh

# Generate version.txt for Hive
RUN echo "wasix-evm-0.1.0" > /version.txt

EXPOSE 8545 8546 8551 9001 9002

ENTRYPOINT ["/app/wasix-evm.sh"]
