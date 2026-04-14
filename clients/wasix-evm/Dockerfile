# Build stage: use Rust to compile the project to WASM/WASIX
FROM rust:1.92 AS builder

RUN apt-get update && apt-get install -y git clang libssl-dev pkg-config curl build-essential binutils cmake libstdc++-12-dev lld
# Install Wasmer
RUN curl https://get.wasmer.io -sSfL | sh
ENV PATH="/root/.wasmer/bin:${PATH}"

# Install cargo-wasix
RUN cargo install cargo-wasix

WORKDIR /app
COPY . .

# Build the WASIX-based EVM using cargo-wasix
WORKDIR /app/wasix-based-evm

# Set CC, AR, and RUSTFLAGS for host-side compilation to avoid linker errors
ENV CC=gcc
ENV AR=ar
# Force use of lld as it's more reliable in this environment
ENV RUSTFLAGS="-C linker=clang -C link-arg=-fuse-ld=lld"

# Pre-download and setup the wasix toolchain (ignore first error as it's for toolchain setup)
RUN cargo wasix build --release || true

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
RUN RUSTUP_TOOLCHAIN=stable cargo wasix build --release

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
