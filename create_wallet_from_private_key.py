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
        
        # Try to get the public key (this would require solana libraries)
        # For now, we'll just inform the user they need to check it
        print("Please verify your public key using: solana address --keypair " + output_file)
        
    except Exception as e:
        print(f"Error creating wallet: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 create_wallet_from_private_key.py <private_key>")
        sys.exit(1)
    
    private_key = sys.argv[1]
    create_wallet_from_private_key(private_key)