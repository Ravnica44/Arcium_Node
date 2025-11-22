#!/usr/bin/env python3
"""
Script to generate a unique node offset for the Arcium node.
This script creates a random large number to use as the node offset,
which is required for node registration on the Arcium network.

Usage:
python3 generate_offset.py
"""

import random
import sys
import os
import re

def generate_node_offset(output_file='node-config.toml'):
    """
    Generate a unique node offset and update the node-config.toml file.
    
    Args:
        output_file (str): The path to the node-config.toml file
    """
    try:
        # Check if node-config.toml exists
        if not os.path.exists(output_file):
            print(f"Error: {output_file} not found!")
            sys.exit(1)
        
        # Read the current config file
        with open(output_file, 'r') as f:
            content = f.read()
        
        # Check if offset is already set to a valid number (not 0 or placeholder)
        offset_match = re.search(r'offset = (\d+)', content)
        if offset_match:
            existing_offset = int(offset_match.group(1))
            if existing_offset != 0:
                print(f"Node offset already configured: {existing_offset}")
                print("Skipping offset generation to preserve existing configuration.")
                return existing_offset
        
        # Generate a random large number (8-10 digits) for the node offset
        # This reduces the chance of conflicts with other nodes
        node_offset = random.randint(10000000, 9999999999)
        
        # Update the offset line
        updated_content = re.sub(r'offset = \d+', f'offset = {node_offset}', content)
        
        # Write the updated config back to file
        with open(output_file, 'w') as f:
            f.write(updated_content)
        
        print(f"[✓] Node offset generated and configured successfully!")
        print(f"Your node offset: {node_offset}")
        print("")
        print("To keep your offset private, you can:")
        print("1. Set it as an environment variable:")
        print(f"   export NODE_OFFSET={node_offset}")
        print("2. Add it to your .bashrc or .zshrc to persist across sessions:")
        print(f"   echo 'export NODE_OFFSET={node_offset}' >> ~/.bashrc")
        print("")
        print("The start script will automatically use the NODE_OFFSET environment variable")
        print("if it's set, otherwise it will use the value in node-config.toml.")
        print("")
        print("Next steps:")
        print("1. Fund your node accounts with Devnet SOL:")
        print(f"   solana airdrop 2 $(solana address --keypair node-keypair.json) -u devnet")
        print(f"   solana airdrop 2 $(solana address --keypair callback-kp.json) -u devnet")
        print("")
        print("2. Initialize your node accounts:")
        print(f"   arcium init-arx-accs \\")
        print(f"   --keypair-path node-keypair.json \\")
        print(f"   --callback-keypair-path callback-kp.json \\")
        print(f"   --peer-keypair-path identity.pem \\")
        print(f"   --node-offset {node_offset} \\")
        print(f"   --ip-address <your_public_ip> \\")
        print(f"   --rpc-url https://api.devnet.solana.com")
        
        return node_offset
        
    except Exception as e:
        print(f"Error generating node offset: {e}")
        sys.exit(1)

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
    # Check if node-config.toml exists
    if not os.path.exists('node-config.toml'):
        print("Error: node-config.toml not found!")
        print("Please run this script from the arcium-node directory.")
        sys.exit(1)
    
    # If NODE_OFFSET environment variable is set, use it and don't generate new offset
    if os.environ.get('NODE_OFFSET'):
        print(f"Using node offset from NODE_OFFSET environment variable: {os.environ.get('NODE_OFFSET')}")
        print("Skipping offset generation.")
        sys.exit(0)
    
    # Generate new offset only if current offset is 0
    generate_node_offset()