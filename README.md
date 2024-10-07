# Gelato Relay

Solidity Contracts + Tests.

## Deploying a new network locally

Create .env file and include the following

```
RELAY_DEPLOYER_PK=
HARDHAT_DYNAMIC_NETWORK_NAME=
HARDHAT_DYNAMIC_NETWORK_URL=
HARDHAT_DYNAMIC_NETWORK_CONTRACTS_GELATO=
HARDHAT_DYNAMIC_NETWORK_NO_DETERMINISTIC_DEPLOYMENT=
```

### Via CLI

```
npx hardhat deploy --network dynamic
```

### Via Docker

```
bash src/scripts/deploy-docker.sh
```

Include the following environment variables to verify the contracts:
```
HARDHAT_DYNAMIC_NETWORK_ETHERSCAN_VERIFY_URL=
HARDHAT_DYNAMIC_NETWORK_ETHERSCAN_API_KEY=
```
