#!/usr/bin/env python3
"""
Script to create a Solana wallet file from a private key.
This script is meant to be used by new users who want to import their private key
to run the Arcium node with their own wallet.

Usage:
python3 create_wallet_from_private_key.py <private_key>
"""

import json
import base58
import sys
import os

def create_wallet_from_private_key(private_key_str, output_file='user-wallet.json'):
    """
    Create a Solana wallet file from a private key string.
    
    Args:
        private_key_str (str): The private key in base58 format
        output_file (str): The output file name for the wallet
    """
    try:
        # Decode the private key from base58
        private_key_bytes = base58.b58decode(private_key_str)
        
        # Convert to list of integers
        private_key_list = list(private_key_bytes)
        
        # For Solana, the keypair file contains both private and public key bytes
        # We need to pad the private key to 64 bytes
        while len(private_key_list) < 64:
            private_key_list.append(0)
        
        # Write to file
        with open(output_file, 'w') as f:
            json.dump(private_key_list, f)
        
        print(f"Wallet file '{output_file}' created successfully!")
        
        # Generate additional keypair files as mentioned in the README
        generate_additional_keypairs(private_key_list)
        
        # Try to get the public key (this would require solana libraries)
        # For now, we'll just inform the user they need to check it
        print("Please verify your public key using: solana address --keypair " + output_file)
        
    except Exception as e:
        print(f"Error creating wallet: {e}")
        sys.exit(1)


def generate_additional_keypairs(private_key_list):
    """
    Generate additional keypair files as mentioned in the README.
    """
    try:
        # Create node-keypair.json (same as user wallet for now)
        with open('node-keypair.json', 'w') as f:
            json.dump(private_key_list, f)
        print("Created node-keypair.json")
        
        # Create callback-kp.json (same as user wallet for now)
        with open('callback-kp.json', 'w') as f:
            json.dump(private_key_list, f)
        print("Created callback-kp.json")
        
        # Create burner-wallet.json (same as user wallet for now)
        with open('burner-wallet.json', 'w') as f:
            json.dump(private_key_list, f)
        print("Created burner-wallet.json")
        
        # Generate identity.pem if it doesn't exist
        if not os.path.exists('identity.pem'):
            # This would require openssl command, so we'll just inform the user
            print("Please run './start-arcium-node.sh' to generate identity.pem")
        
    except Exception as e:
        print(f"Error generating additional keypairs: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 create_wallet_from_private_key.py <private_key>")
        sys.exit(1)
    
    private_key = sys.argv[1]
    create_wallet_from_private_key(private_key)