#!/bin/bash
# Hive script to extract the enode of the running client.
# Note: For our current WASIX client, we may need a way to query the PeerId from RPC or logs.
# For now, we attempt to read it from the data-dir if the client writes it there, 
# or we could implement an RPC call to get it.

# Assuming the client logs or stores PeerId in data-dir
PEER_ID_FILE="/data-dir/peer_id"
IP=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

if [ -f "$PEER_ID_FILE" ]; then
    PEER_ID=$(cat "$PEER_ID_FILE")
    echo "enode://$PEER_ID@$IP:9002"
else
    # Fallback or dummy if not yet available - Hive simulations often wait for this.
    # In a real scenario, we should query the client's RPC (e.g., net_peerId or admin_nodeInfo)
    echo "enode://0000000000000000000000000000000000000000000000000000000000000000@$IP:9002"
fi
