# Build stage: use Rust to compile the project to WASM/WASIX
FROM rust:1.94 as builder

RUN apt-get update && apt-get install -y  gcc \
                                           g++ \
                                           make \
                                           pkg-config \
                                           libssl-dev \
                                           curl \
                                           git \
                                           cmake \
                                           binutils \
                                           xz-utils \
                                           libstdc++-12-dev

# Install LLVM/Clang from GitHub release
RUN curl -L https://github.com/llvm/llvm-project/releases/download/llvmorg-22.1.0/LLVM-22.1.0-Linux-X64.tar.xz -o llvm.tar.xz && \
    mkdir -p /opt/llvm && \
    tar -xJf llvm.tar.xz -C /opt/llvm --strip-components=1 && \
    rm llvm.tar.xz

# Install wasi-sdk from GitHub release
RUN curl -L https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-25/wasi-sdk-25.0-x86_64-linux.tar.gz -o wasi-sdk.tar.gz && \
    mkdir -p /opt/wasi-sdk && \
    tar -xzf wasi-sdk.tar.gz -C /opt/wasi-sdk --strip-components=1 && \
    rm wasi-sdk.tar.gz

ENV PATH="/opt/llvm/bin:/opt/wasi-sdk/bin:${PATH}"
ENV WASI_SDK_PATH="/opt/wasi-sdk"
ENV CC=clang
ENV AR=llvm-ar
ENV LD=ld.lld
ENV NM=llvm-nm
ENV RANLIB=llvm-ranlib

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
# Added -pthread to fix TLS/errno issues and -C link-arg=-Wl,--import-undefined.    "-C", "target-feature=+bulk-memory",
                                                                                #    "-C", "panic=abort",
                                                                                #    "-C", "atomics"
ENV CARGO_TARGET_WASM32_WASMER_WASI_RUSTFLAGS="-C target-feature=+atomics,+bulk-memory,+mutable-globals -C panic=abort -C link-arg=--shared-memory -C link-arg=--max-memory=4294967296 -C link-arg=--import-memory -C link-arg=--export-dynamic -C link-arg=-pthread -C link-arg=-Wl,--import-undefined -C link-arg=-fuse-ld=lld"

# Now run the actual build using cargo wasix
# Explicitly use the stable toolchain's cargo while calling 'cargo wasix'
RUN RUSTFLAGS=$RUSTFLAGS_HOST cargo +stable wasix build --release

# Final stage: minimal image with Wasmer to run the client
FROM debian:trixie-slim

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
