#!/bin/bash

# Script to start the Arcium node with port checking before launching Docker container

# Function to check if a port is available
check_port() {
    local port=$1
    if netstat -tuln | grep -q ":$port "; then
        return 1  # Port busy
    else
        return 0  # Port free
    fi
}

# Function to find an available port starting from a base port
find_available_port() {
    local base_port=$1
    local port=$base_port
    
    while ! check_port $port; do
        echo "[~] Port $port busy, trying $((port+1))..." >&2
        port=$((port+1))
        
        # Safety to avoid infinite loop
        if [ $port -gt $((base_port+1000)) ]; then
            echo "[!] Unable to find available port after 1000 attempts" >&2
            exit 1
        fi
    done
    
    echo $port
}

# Stop and remove existing container if it exists
# This should be done BEFORE checking port availability to free up any ports in use
if docker ps -a --format '{{.Names}}' | grep -q '^arx-node$'; then
    echo "[~] Stopping existing container..." >&2
    docker stop arx-node >/dev/null 2>&1
    echo "[~] Removing existing container..." >&2
    docker rm arx-node >/dev/null 2>&1
fi

# Default ports for Arcium node
DEFAULT_HTTP_PORT=8080

# Find available ports
echo "[~] Checking port availability..." >&2

# Find HTTP port
HTTP_PORT=$(find_available_port $DEFAULT_HTTP_PORT)

# Show selected ports
echo "[✓] Using ports:" >&2
echo "  HTTP Port: $HTTP_PORT" >&2

# Display configuration files for debugging
echo "[~] Configuration files:" >&2
ls -la node-keypair.json callback-kp.json identity.pem node-config.toml >&2

# Show configuration content for debugging
echo "[~] Node configuration content:" >&2
cat node-config.toml >&2

# Pull the latest Arcium node image
echo "[~] Pulling Arcium node Docker image..." >&2
docker pull arcium/arx-node

# Create logs directory
mkdir -p arx-node-logs

# Start the container with the correct environment variables and volume mappings
echo "[~] Starting Arcium node container..." >&2
docker run -d \
  --name arx-node \
  -p $HTTP_PORT:8080 \
  -e NODE_IDENTITY_FILE=/usr/arx-node/node-keys/node_identity.pem \
  -e NODE_KEYPAIR_FILE=/usr/arx-node/node-keys/node_keypair.json \
  -e OPERATOR_KEYPAIR_FILE=/usr/arx-node/node-keys/operator_keypair.json \
  -e CALLBACK_AUTHORITY_KEYPAIR_FILE=/usr/arx-node/node-keys/callback_authority_keypair.json \
  -e NODE_CONFIG_PATH=/usr/arx-node/arx/node_config.toml \
  -v $(pwd)/node-config.toml:/usr/arx-node/arx/node_config.toml \
  -v $(pwd)/node-keypair.json:/usr/arx-node/node-keys/node_keypair.json:ro \
  -v $(pwd)/node-keypair.json:/usr/arx-node/node-keys/operator_keypair.json:ro \
  -v $(pwd)/callback-kp.json:/usr/arx-node/node-keys/callback_authority_keypair.json:ro \
  -v $(pwd)/identity.pem:/usr/arx-node/node-keys/node_identity.pem:ro \
  -v $(pwd)/arx-node-logs:/usr/arx-node/logs \
  arcium/arx-node

echo "[✓] Arcium node started successfully!" >&2
echo "View logs with: docker logs -f arx-node" >&2