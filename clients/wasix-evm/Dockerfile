# Build stage: use Rust to compile the project to WASM/WASIX
FROM rust:1.92 AS builder

RUN apt-get update && apt-get install -y git clang libssl-dev pkg-config curl build-essential cmake
# Install Wasmer
RUN curl https://get.wasmer.io -sSfL | sh
ENV PATH="/root/.wasmer/bin:${PATH}"

# Install cargo-wasix
RUN cargo install cargo-wasix

WORKDIR /app
COPY . .

# Build the WASIX-based EVM using cargo-wasix
WORKDIR /app/wasix-based-evm

# Pre-download and setup the wasix toolchain
# Then link the host's cargo to the toolchain's bin directory to fix the "cargo missing" error
RUN cargo wasix build --release; \
    TOOLCHAIN_BIN=$(find /root/.local/share/cargo-wasix/toolchains -name bin -type d | head -n 1); \
    if [ -n "$TOOLCHAIN_BIN" ]; then ln -s $(which cargo) "$TOOLCHAIN_BIN/cargo"; fi; \
    cargo wasix build --release

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
