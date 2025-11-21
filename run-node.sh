#!/bin/bash

# Script to run the Arcium node directly without Docker

echo "Starting Arcium node..."

# Set the working directory
cd /root/arcium-node

# Check if required files exist
if [ ! -f "node-keypair.json" ] || [ ! -f "callback-kp.json" ] || [ ! -f "identity.pem" ] || [ ! -f "node-config.toml" ]; then
    echo "Error: Required configuration files are missing"
    exit 1
fi

echo "Configuration files found:"
ls -la node-keypair.json callback-kp.json identity.pem node-config.toml

# Try to run the node directly (this might need to be adjusted based on the actual binary)
echo "Attempting to start node with configuration..."
echo "Note: This requires the arcium node binary to be installed locally"

# Display the configuration for debugging
echo "Node configuration:"
cat node-config.toml

echo "Node setup is complete. To start the node, you would typically run:"
echo "  arcium-node --config node-config.toml"
echo ""
echo "However, the exact command depends on how the Arcium node binary is installed."
echo "Please check the Arcium documentation for the correct startup command."