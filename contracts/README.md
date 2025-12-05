# Kasparex Smart Contracts

This directory contains the smart contracts for the Kasparex dApp marketplace and UaaS Hub.

## Contracts Overview

### Treasury.sol
The Treasury contract collects fees from dApps and manages revenue distribution. It supports:
- Fee collection from dApps
- Configurable revenue distribution percentages (Treasury, Developers, Builders)
- Manual revenue distribution function
- Emergency withdraw capability

**Key Features:**
- Uses OpenZeppelin's `Ownable` for access control
- Uses `ReentrancyGuard` for security
- Default distribution: 40% Treasury, 30% Developers, 30% Builders

### FeeCollector.sol
A simple interface contract that forwards fees to the Treasury contract. This provides a clean abstraction for dApps to send fees.

### DAppRegistry.sol
Registry contract that tracks all deployed dApps and their metadata. Supports:
- Registering new dApps
- Linking dApps to tokens (for future Token Builder)
- Managing dApp status (active/inactive)
- Querying dApps by token address

**Roles:**
- `DEFAULT_ADMIN_ROLE`: Full control
- `DEPLOYER_ROLE`: Can register new dApps

### SimplePayment.sol
The first dApp contract demonstrating the fee collection pattern. Allows users to:
- Send KAS payments to recipients
- Automatically deducts a configurable fee (default 1%)
- Forwards fees to Treasury via FeeCollector

## Development

### Prerequisites
- Node.js 18+
- pnpm (or npm/yarn)

### Compile Contracts
```bash
pnpm hardhat:compile
```

### Run Tests
```bash
pnpm hardhat:test
```

### Deploy Contracts

#### Local/Hardhat Network
```bash
pnpm hardhat:deploy
```

#### Kasplex L2 Testnet
```bash
pnpm hardhat:deploy:testnet
```

#### Kasplex L2 Mainnet
```bash
pnpm hardhat:deploy:mainnet
```

### Configuration

Create a `.env` file in the root directory:

```env
# Private key for deployment (NEVER commit this!)
PRIVATE_KEY=your_private_key_here

# Optional: Distribution addresses
DEVELOPER_ADDRESS=0x...
BUILDER_ADDRESS=0x...

# Optional: RPC URLs (defaults are used if not set)
KASPLEX_L2_MAINNET_RPC=https://evmrpc.kasplex.org
KASPLEX_L2_TESTNET_RPC=https://rpc.kasplextest.xyz
```

### Deployment Output

After deployment, contract addresses are saved to `deployments/{network}.json`. Update your frontend environment variables with these addresses:

```env
NEXT_PUBLIC_TREASURY_ADDRESS=0x...
NEXT_PUBLIC_FEE_COLLECTOR_ADDRESS=0x...
NEXT_PUBLIC_DAPP_REGISTRY_ADDRESS=0x...
NEXT_PUBLIC_SIMPLE_PAYMENT_ADDRESS=0x...
```

## Architecture

```
┌─────────────────┐
│   dApps (e.g.,  │
│ SimplePayment)  │
└────────┬────────┘
         │
         │ fees
         ▼
┌─────────────────┐
│  FeeCollector   │
└────────┬────────┘
         │
         │ forwards
         ▼
┌─────────────────┐
│    Treasury     │
│  (collects &    │
│  distributes)   │
└─────────────────┘

┌─────────────────┐
│  DAppRegistry   │
│  (tracks dApps) │
└─────────────────┘
```

## Revenue Model

### Fee Structure
- **Transaction Fees**: Small KAS fee per dApp action (e.g., 1% for SimplePayment)
- **Usage Fees**: Fees for deploying/attaching dApps to tokens (future)

### Distribution
- **Treasury**: 40% - Platform operations and growth
- **Developers**: 30% - Rewards for dApp developers
- **Builders**: 30% - Rewards for token builders and deployers

## Security

All contracts use:
- OpenZeppelin's battle-tested libraries
- ReentrancyGuard where needed
- Access control (Ownable/AccessControl)
- Input validation

## Future Enhancements

- Token Builder integration
- Automated revenue distribution
- Multi-signature treasury
- Governance token for distribution decisions


