#!/bin/bash

# Script to easily view Arcium node logs

echo "Arcium Node Log Viewer"
echo "======================"

# Parse command line arguments
SHOW_HISTORY=false
FOLLOW_LOGS=true

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--history)
            SHOW_HISTORY=true
            shift
            ;;
        --no-follow)
            FOLLOW_LOGS=false
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--history] [--no-follow]"
            echo "  --history: Show log history instead of following logs"
            echo "  --no-follow: Show logs but don't follow (tail -n instead of tail -f)"
            exit 1
            ;;
    esac
done

# Always check for log files first (works for both Docker and direct execution)
if [ -d "arx-node-logs" ] && [ -n "$(ls -A arx-node-logs 2>/dev/null)" ]; then
    if [ "$SHOW_HISTORY" = true ]; then
        echo "Showing log history from arx-node-logs directory..."
        echo ""
        # Show last 100 lines of all log files
        for log_file in arx-node-logs/arx_log_*.log; do
            if [ -f "$log_file" ]; then
                echo "==== Last 100 lines of $log_file ===="
                tail -n 100 "$log_file"
                echo ""
            fi
        done
    else
        echo "Showing file-based logs from arx-node-logs directory..."
        echo ""
        # Find the most recent log file
        latest_log=$(ls -t arx-node-logs/arx_log_*.log 2>/dev/null | head -n1)
        if [ -n "$latest_log" ]; then
            if [ "$FOLLOW_LOGS" = true ]; then
                tail -f "$latest_log"
            else
                tail -n 50 "$latest_log"
            fi
        else
            # If no specific log files found, follow all log files
            if [ "$FOLLOW_LOGS" = true ]; then
                tail -f arx-node-logs/arx_log_*.log 2>/dev/null || echo "No log files found in arx-node-logs directory"
            else
                tail -n 50 arx-node-logs/arx_log_*.log 2>/dev/null || echo "No log files found in arx-node-logs directory"
            fi
        fi
    fi
else
    # Check if running in Docker
    if docker ps --format '{{.Names}}' | grep -q '^arx-node$'; then
        echo "Docker container detected but no log files found."
        if [ "$SHOW_HISTORY" = true ]; then
            echo "Showing Docker logs history..."
            echo ""
            docker logs arx-node
        else
            echo "Attempting to show Docker logs (may be empty)..."
            echo ""
            if [ "$FOLLOW_LOGS" = true ]; then
                docker logs -f arx-node
            else
                docker logs arx-node | tail -n 50
            fi
        fi
    else
        echo "No log files found and no Docker container running."
        if [ "$SHOW_HISTORY" = false ]; then
            echo "Creating log directory and starting fresh log viewer..."
            echo ""
            mkdir -p arx-node-logs
            touch arx-node-logs/arx_log_$(date +%Y%m%d).log
            if [ "$FOLLOW_LOGS" = true ]; then
                tail -f arx-node-logs/arx_log_*.log
            else
                tail -n 50 arx-node-logs/arx_log_*.log
            fi
        fi
    fi
fi