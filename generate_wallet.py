#!/usr/bin/env python3
"""
Script to generate a new Solana wallet for use with the Arcium node.
This script creates a completely new wallet with a random keypair.

Usage:
python3 generate_wallet.py
"""

import json
import os
import sys
import nacl.signing
import base58

def generate_new_wallet(output_file='user-wallet.json'):
    """
    Generate a new Solana wallet with a random keypair.
    
    Args:
        output_file (str): The output file name for the wallet
    """
    try:
        # Generate a new signing keypair
        signing_key = nacl.signing.SigningKey.generate()
        
        # Extract private and public key bytes
        private_key_bytes = signing_key.encode()
        public_key_bytes = signing_key.verify_key.encode()
        
        # Combine private and public key for Solana keypair format
        keypair_bytes = private_key_bytes + public_key_bytes
        
        # Convert to list of integers (Solana keypair format)
        keypair_list = list(keypair_bytes)
        
        # Write to file
        with open(output_file, 'w') as f:
            json.dump(keypair_list, f)
        
        # Get the public key in base58 format
        public_key_b58 = base58.b58encode(public_key_bytes).decode('utf-8')
        
        print(f"New wallet file '{output_file}' created successfully!")
        print(f"Public key: {public_key_b58}")
        print(f"Please fund this wallet with Devnet SOL before running your node.")
        print(f"You can use the Solana faucet: https://faucet.solana.com/")
        
    except Exception as e:
        print(f"Error generating wallet: {e}")
        sys.exit(1)

if __name__ == "__main__":
    # Check if wallet file already exists
    if os.path.exists('user-wallet.json'):
        response = input("Wallet file 'user-wallet.json' already exists. Overwrite? (y/N): ")
        if response.lower() != 'y':
            print("Wallet generation cancelled.")
            sys.exit(0)
    
    generate_new_wallet()