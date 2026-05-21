# WASIX-based EVM Client for Hive

This directory contains the Hive client definition for the WASIX-based EVM client.

## Integration Details

The client is packaged as a Docker container that runs the compiled WASIX (`wasm32-wasmer-wasi`) binary using **Wasmer**.

### Entrypoint Script (`wasix-evm.sh`)

The entrypoint script translates Hive's environment variables and files into the client's CLI arguments.
- **Genesis**: Hive provides `/genesis.json`, which we copy to `/data-dir/genesis/genesis.json`. The client's `AppBuilder` automatically looks for it in the configured data directory.
- **Ports**: 
  - HTTP RPC: 8545
  - Engine Auth RPC: 8551
  - P2P Discovery: 9001
  - P2P Gossip: 9002
- **Networking**: Automatically detects container IP and sets it via `--ext-ip`.

### Wasmer Flags

We use the specific flags required for the WASIX runtime as per the startup arguments:
`--enable-threads --net --http-client --enable-exceptions --enable-bulk-memory --enable-simd --enable-reference-types --enable-multi-value --llvm --enable-async-threads`

## How to Run Simulations

To run simulations against this client, use the `hive` command from the root of the hive repository.

### RPC Simulation

The RPC simulator tests the standard JSON-RPC interface.

```bash
./hive --sim ethereum/rpc --client wasix-evm
```

### Engine API Simulation

The Engine API simulator verifies the Consensus Layer interface.

```bash
./hive --sim ethereum/engine --client wasix-evm
```

### Combined Tests

```bash
./hive --sim ethereum/rpc,ethereum/engine --client wasix-evm
```

## Build Options

The Dockerfile builds the client from source using a multi-stage build. 
If you want to test local changes, ensure you are in the project root (where the `.git` directory is) and run:

```bash
docker build -t wasix-evm -f hive/clients/wasix-evm/Dockerfile .
```
