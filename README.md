# Automated Response Morpho

## 1. To install the required libraries

Run in the terminal

```bash
npm install
```

## 2. Populate the deployment variables in the .env

2.1 Rename `.env.example` to `env`

2.2. Provide the missing values to the keys, example

```bash
SK=<your private key here>

# Get the etherscan API Keys & provide them here
ARBISCAN_API_KEY=
BASE_API_KEY=
ETHERSCAN_API_KEY=
OPTIMISTIC=
POLYGON_API_KEY=
BSC_API_KEY=

BH_KEEPER=<keeper address goes here>
BH_SAFE=<>
```

## 3. To compile contracts

Run in the terminal

```bash
npx hardhat compile
```

## 4. To estimate the contract deployment costs

1. Direct Helper (without Gnosis Safe):

```bash
npx hardhat run ./scripts/estimate.ts --network <replace with the network name>
```

## 5. To deploy the contract

```bash
npx hardhat run ./scripts/deploy.ts --network <replace with the network name>
```

## Available network names

|Mainnets|
|:-:|
|arbitrum|
|avalanche|
|base|
|ethereum|
|optimism|
|polygon|
|scroll|

|Testnets|
|:-:|
|sepolia|

## 5. Contract verification

The script automatially verifies the contract. However, if something goes wrong, run in the terminal:

```bash
npx hardhat verify --network <network-name> <deployd-contract-address> <space separated parameters>
```