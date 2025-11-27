#!/bin/bash

# Script to start the Arcium node with port checking before launching Docker container

# Check for required dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi
    
    if ! command -v openssl &> /dev/null; then
        missing_deps+=("openssl")
    fi
    
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "[!] Missing required dependencies: ${missing_deps[*]}" >&2
        echo "[!] Please install the missing dependencies and try again" >&2
        exit 1
    fi
    
    echo "[✓] All required dependencies are installed" >&2
}

# Display usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Start the Arcium node with automatic port checking and configuration."
    echo ""
    echo "This script will:"
    echo "  - Stop any existing node container"
    echo "  - Check for available ports"
    echo "  - Generate identity.pem if missing"
    echo "  - Generate node offset if not set"
    echo "  - Start the Arcium node in Docker"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "The script automatically handles:"
    echo "  - Port availability checking"
    echo "  - Node identity keypair generation"
    echo "  - Node offset generation"
    echo "  - Docker container management"
    echo "  - Log directory setup"
    echo ""
    echo "Environment variables:"
    echo "  NODE_OFFSET    Node offset (if set, overrides config file)"
    echo ""
    echo "Required files (auto-generated if missing):"
    echo "  - node-keypair.json     Node authority keypair"
    echo "  - callback-kp.json      Callback authority keypair"
    echo "  - identity.pem          Node identity keypair (Ed25519, PKCS#8 format)"
    echo "  - node-config.toml      Node configuration (generated from template)"
    echo ""
    echo "After starting, monitor logs with: ./view-logs.sh"
}

# Check dependencies before proceeding
check_dependencies

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
    shift
done

# Function to check if a port is available
check_port() {
    local port=$1
    if command -v netstat &> /dev/null; then
        if netstat -tuln | grep -q ":$port "; then
            return 1  # Port busy
        else
            return 0  # Port free
        fi
    else
        # Fallback to ss if netstat is not available
        if command -v ss &> /dev/null; then
            if ss -tuln | grep -q ":$port "; then
                return 1  # Port busy
            else
                return 0  # Port free
            fi
        else
            # If neither netstat nor ss is available, try lsof as fallback
            if command -v lsof &> /dev/null; then
                if lsof -i :$port | grep -q LISTEN; then
                    return 1  # Port busy
                else
                    return 0  # Port free
                fi
            else
                # If no port checking tool is available, assume port is free
                return 0
            fi
        fi
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

# Function to generate identity.pem if it doesn't exist
generate_identity_pem() {
    if [ ! -f "identity.pem" ]; then
        echo "[~] Generating node identity keypair..." >&2
        if command -v openssl &> /dev/null; then
            openssl genpkey -algorithm ed25519 -out identity.pem
            if [ $? -eq 0 ]; then
                echo "[✓] Node identity keypair generated successfully" >&2
            else
                echo "[!] Failed to generate node identity keypair" >&2
                exit 1
            fi
        else
            echo "[!] OpenSSL not found. Please install OpenSSL to generate identity.pem" >&2
            exit 1
        fi
    fi
}

# Stop and remove existing container if it exists
# This should be done BEFORE checking port availability to free up any ports in use
if docker ps -a --format '{{.Names}}' | grep -q '^arx-node$'; then
    echo "[~] Stopping existing container..." >&2
    docker stop arx-node >/dev/null 2>&1
    echo "[~] Removing existing container..." >&2
    docker rm arx-node >/dev/null 2>&1
fi

# Generate node config from template
generate_node_config() {
    echo "[~] Generating node configuration from template..." >&2
    
    # Check if template exists
    if [ ! -f "node-config.template" ]; then
        echo "[!] node-config.template not found!" >&2
        echo "[!] Creating default template..." >&2
        cat > node-config.template << 'EOF'
[node]
offset = 0  # Will be replaced by NODE_OFFSET environment variable if set
hardware_claim = 0  # Currently not required to specify, just use 0
starting_epoch = 0
ending_epoch = 9223372036854775807

[network]
address = "0.0.0.0" # Bind to all interfaces for reliability behind NAT/firewalls

[solana]
endpoint_rpc = "https://api.devnet.solana.com"  # Default Solana Devnet RPC endpoint
endpoint_wss = "wss://api.devnet.solana.com"   # Default Solana Devnet WebSocket endpoint
cluster = "Devnet"
commitment.commitment = "confirmed"  # or "processed" or "finalized"
EOF
    fi
    
    # Copy template to config file
    cp node-config.template node-config.toml
    
    # If NODE_OFFSET environment variable is set, update config file
    if [ ! -z "$NODE_OFFSET" ]; then
        echo "[~] Using NODE_OFFSET from environment variable: $NODE_OFFSET" >&2
        sed -i "s/^offset = .*/offset = $NODE_OFFSET/" node-config.toml
        echo "[✓] Updated node-config.toml with NODE_OFFSET value" >&2
    else
        # Check if offset is 0 in config and generate a new one if needed
        OFFSET_IN_CONFIG=$(grep "^offset = " node-config.toml | cut -d '=' -f 2 | tr -d ' ')
        if [ "$OFFSET_IN_CONFIG" = "0" ] || [ -z "$OFFSET_IN_CONFIG" ]; then
            echo "[~] Node offset not set, generating new offset..." >&2
            if [ -f "generate_offset.py" ]; then
                python3 generate_offset.py
            else
                echo "[!] generate_offset.py not found, skipping offset generation" >&2
            fi
        else
            echo "[~] Using node offset from config file: $OFFSET_IN_CONFIG" >&2
        fi
    fi
}

# Generate node config from template
generate_node_config

# Generate identity.pem if needed
generate_identity_pem

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
echo "View logs with: ./view-logs.sh" >&2