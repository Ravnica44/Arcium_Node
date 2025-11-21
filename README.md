# Arcium Node Setup

This repository contains a complete setup for running an Arcium ARX node on the Solana Devnet testnet. The node is configured to participate in MPC (Multi-Party Computation) computations within a cluster.

## Prerequisites

Before setting up your node, ensure you have the following installed:
- Docker & Docker Compose
- Solana CLI
- OpenSSL
- Git
- Python 3 (for wallet creation script)

## Initial Setup

### Setting Script Permissions

The scripts in this repository need to be executable to function properly. To set the correct permissions, run:

```bash
chmod +x start-arcium-node.sh view-logs.sh create_wallet_from_private_key.py generate_wallet.py
```

### Getting Your IP Address

To get your public IP address, you can use one of these commands:

```bash
# Get your public IP
curl ifconfig.me

# Alternative command
curl ipinfo.io/ip

# Get your local IP
hostname -I
```

## Node Configuration

The node is already configured with all necessary keypairs and configuration files:

- `node-keypair.json` - Node authority keypair
- `callback-kp.json` - Callback authority keypair  
- `identity.pem` - Node identity keypair (PKCS#8 format)
- `node-config.toml` - Node configuration file

## Setup Process

### 1. Create Your Wallet

You can either generate a new wallet or import an existing private key:

**Option 1: Generate a new wallet (recommended for new users)**
```bash
python3 generate_wallet.py
```

**Option 2: Import an existing private key**
```bash
python3 create_wallet_from_private_key.py <your_private_key>
```

Both options will create a `user-wallet.json` file that you can use to fund your node accounts.

### 2. Fund Your Accounts

You need to fund the node and callback accounts with Devnet SOL:

```bash
# Get your node public key
solana address --keypair node-keypair.json

# Get your callback public key  
solana address --keypair callback-kp.json

# Fund each account (replace with your actual public keys)
solana airdrop 2 <node_pubkey> -u devnet
solana airdrop 2 <callback_pubkey> -u devnet
```

If airdrops don't work, use the Solana web faucet at https://faucet.solana.com/

### 3. Initialize Node Accounts

Initialize your node accounts on the blockchain:

```bash
solana config set --url https://api.devnet.solana.com

arcium init-arx-accs \
--keypair-path node-keypair.json \
--callback-keypair-path callback-kp.json \
--peer-keypair-path identity.pem \
--node-offset <your_node_offset> \
--ip-address <your_public_ip> \
--rpc-url https://api.devnet.solana.com
```

### 4. Join a Cluster

You can either join an existing cluster or create your own:

**Join existing cluster:**
```bash
arcium join-cluster true \
--keypair-path node-keypair.json \
--node-offset <your_node_offset> \
--cluster-offset <cluster_offset> \
--rpc-url https://api.devnet.solana.com
```

**Create your own cluster:**
```bash
arcium init-cluster \
--keypair-path node-keypair.json \
--offset <cluster_offset> \
--max-nodes <max_nodes> \
--rpc-url https://api.devnet.solana.com
```

### 5. Start the Node

Use the provided script to start the node with automatic port checking:

```bash
./start-arcium-node.sh
```

Or use Docker Compose directly:

```bash
docker-compose up -d
```

## Monitoring

Check if your node is active:

```bash
arcium arx-active <node_offset> --rpc-url https://api.devnet.solana.com
```

View node information:

```bash
arcium arx-info <node_offset> --rpc-url https://api.devnet.solana.com
```

Check logs:

```bash
# Docker logs
docker logs -f arx-node

# Or file logs
tail -f arx-node-logs/arx_log_*.log

# Quick logs check command
./view-logs.sh
```

## Troubleshooting

If the node doesn't start:
1. Check that all required ports are available
2. Verify all configuration files are present
3. Ensure your wallet is funded with sufficient SOL
4. Check the logs for specific error messages

## Security

- Keep all keypair files secure and private
- Don't share your private keys with anyone
- The node keys are like master keys to your node
- Store backups of your keypairs in secure locations