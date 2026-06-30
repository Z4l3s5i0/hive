#!/bin/bash

# Script to retrieve the enode
# 
# This is copied into the validator container by Hive
# and used to provide a client-specific enode id retriever
#

# Immediately abort the script on any error encountered
set -e

# Retry loop to wait for the node to start
for i in {1..30}; do
    TARGET_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' "127.0.0.1:8545" || true)
    
    if [ -n "$TARGET_RESPONSE" ]; then
        TARGET_ENODE=$(echo "${TARGET_RESPONSE}" | jq -r '.result.enode' 2>/dev/null || true)
        if [ -n "$TARGET_ENODE" ] && [ "$TARGET_ENODE" != "null" ]; then
            echo "$TARGET_ENODE"
            exit 0
        fi
    fi
    sleep 1
done

echo "Failed to retrieve enode" >&2
exit 1