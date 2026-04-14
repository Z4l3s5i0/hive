#!/bin/bash
set -e

# Base Wasmer flags based on user's input
WASMER_FLAGS="--enable-threads --net --http-client --enable-exceptions --enable-bulk-memory --enable-simd --enable-reference-types --enable-multi-value --llvm --enable-async-threads"

# Map Hive log level to client verbosity
# Hive: 0-5, Client: 0-2 (0: none, 1: info, 2: debug)
VERBOSITY=1
if [ "$HIVE_LOGLEVEL" -ge 4 ]; then
    VERBOSITY=2
elif [ "$HIVE_LOGLEVEL" -le 1 ]; then
    VERBOSITY=0
fi

# Prepare data-dir
mkdir -p /data-dir/genesis
cp /genesis.json /data-dir/genesis/genesis.json

# Client flags
CLIENT_FLAGS="--verbose $VERBOSITY --data-dir /data-dir --eth-rpc-port 8545 --auth-rpc-port 8551 --discovery-port 9001 --p2p-port 9002"

# Handle bootnodes
if [ "$HIVE_BOOTNODE" != "" ]; then
    CLIENT_FLAGS="$CLIENT_FLAGS --bootnodes $HIVE_BOOTNODE"
fi

# Determine external IP
IP=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
CLIENT_FLAGS="$CLIENT_FLAGS --ext-ip $IP"

echo "Running WASIX EVM client with Wasmer..."
echo "wasmer run $WASMER_FLAGS --volume /data-dir:/data-dir /app/wasix-evm.wasm -- $CLIENT_FLAGS"

wasmer run $WASMER_FLAGS --volume /data-dir:/data-dir /app/wasix-evm.wasm -- $CLIENT_FLAGS
