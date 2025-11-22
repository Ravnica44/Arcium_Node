#!/usr/bin/env python3
"""
Script to show the current node offset being used.
This script checks for the NODE_OFFSET environment variable first,
then falls back to reading from node-config.toml.

Usage:
python3 show_offset.py
"""

import os
import sys
import re

def get_node_offset_from_env_or_config(config_file='node-config.toml'):
    """
    Get node offset from environment variable NODE_OFFSET or from config file.
    
    Args:
        config_file (str): The path to the node-config.toml file
        
    Returns:
        int: The node offset
    """
    # First check environment variable
    env_offset = os.environ.get('NODE_OFFSET')
    if env_offset and env_offset.isdigit():
        return int(env_offset)
    
    # If no environment variable, read from config file
    if os.path.exists(config_file):
        with open(config_file, 'r') as f:
            content = f.read()
            offset_match = re.search(r'offset = (\d+)', content)
            if offset_match:
                return int(offset_match.group(1))
    
    return 0

if __name__ == "__main__":
    offset = get_node_offset_from_env_or_config()
    
    if os.environ.get('NODE_OFFSET'):
        print(f"Current node offset (from NODE_OFFSET environment variable): {offset}")
    elif offset != 0:
        print(f"Current node offset (from node-config.toml): {offset}")
    else:
        print("No node offset configured.")
        print("Run ./start-arcium-node.sh to generate one automatically,")
        print("or set the NODE_OFFSET environment variable.")