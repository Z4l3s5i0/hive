# Use a base image with required libraries
FROM ubuntu:22.04

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    jq \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

# Copy the pre-built binary from the host
COPY wasix_eth /usr/local/bin/wasix_eth
RUN chmod +x /usr/local/bin/wasix_eth

# Generate a dummy version.txt (or handle it more properly if the binary supports --version)
RUN echo "wasix-eth-0.1.0" > /version.txt

# Inject the startup script.
ADD wasix-eth.sh /wasix-eth.sh
RUN echo "." > /mapper.jq
RUN chmod +x /wasix-eth.sh

# Inject the enode id retriever script.
RUN mkdir /hive-bin
ADD enode.sh /hive-bin/enode.sh
RUN chmod +x /hive-bin/enode.sh

# Add a default genesis file.
ADD genesis.json /genesis.json

# Export the usual networking ports
EXPOSE 8545 8551 9001 9002 3000 9050

ENTRYPOINT ["/wasix-eth.sh"]
