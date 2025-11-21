#!/bin/bash

# Script to easily view Arcium node logs

echo "Arcium Node Log Viewer"
echo "======================"

# Check if running in Docker
if docker ps --format '{{.Names}}' | grep -q '^arx-node$'; then
    echo "Docker container detected. Showing Docker logs..."
    echo ""
    docker logs -f arx-node
else
    # Check for log files
    if [ -d "arx-node-logs" ] && [ "$(ls -A arx-node-logs)" ]; then
        echo "Showing file-based logs..."
        echo ""
        tail -f arx-node-logs/arx_log_*.log
    else
        echo "No log files found. Starting fresh log viewer..."
        echo ""
        mkdir -p arx-node-logs
        touch arx-node-logs/arx_log_$(date +%Y%m%d).log
        tail -f arx-node-logs/arx_log_*.log
    fi
fi