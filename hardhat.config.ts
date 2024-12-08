import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { readENV } from "./scripts/utils";

const ARBISCAN_API_KEY = readENV('ARBISCAN_API_KEY');
const BASE_API_KEY = readENV("BASE_API_KEY");
const ETHERSCAN_API_KEY = readENV('ETHERSCAN_API_KEY');
const OPTIMISTIC = readENV('OPTIMISTIC');
const POLYGON_API_KEY = readENV('POLYGON_API_KEY');
const BSC_API_KEY = readENV("BSC_API_KEY");

const SK: string = readENV("SK");
const accounts = [SK];

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 2000
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 40000
  },
  networks: {
    arbitrum: {
      url: "https://arbitrum.llamarpc.com",
      accounts,
      chainId: 42161
    },
    avalanche: {
      url: `https://avalanche-c-chain-rpc.publicnode.com`,
      accounts,
      chainId: 43114
    },
    base: {
      url:"https://1rpc.io/base",
      accounts,
      chainId: 8453
    },
    bsc: {
      url: "https://bsc.blockrazor.xyz",
      accounts,
      chainId: 56,
      gasPrice: 1000000000,
    },
    ethereum: {
      url: "https://ethereum-rpc.publicnode.com",
      accounts,
      chainId: 1
    },
    optimism: {
      url: `https://optimism-rpc.publicnode.com`,
      accounts,
      chainId: 10
    },
    polygon: {
      url: "https://1rpc.io/matic",
      accounts,
      chainId: 137,
      gasPrice: 50000000000,
    },
    scroll: {
      url: 'https://scroll.drpc.org',
      accounts,
      chainId: 534352
    },
    sepolia: {
      url: "https://ethereum-sepolia.blockpi.network/v1/rpc/public",
      accounts,
      chainId: 11155111
    },
  },
  etherscan: {
    apiKey: {
      arbitrum: ARBISCAN_API_KEY,
      berachainBartio: 'YourApiKeyToken',
      avalanche: 'snowtrace',
      base: BASE_API_KEY,
      bsc: BSC_API_KEY,
      bscTestnet: BSC_API_KEY,
      ethereum: ETHERSCAN_API_KEY,
      optimism: OPTIMISTIC,
      optimismSepolia: OPTIMISTIC,
      snowtrace: "snowtrace", // apiKey is not required, just set a placeholder
      sepolia: ETHERSCAN_API_KEY,
      polygon: POLYGON_API_KEY,
      amoy: POLYGON_API_KEY
    },
    customChains: [
      {
        network: 'arbitrum',
        chainId: 42161,
        urls: {
          apiURL: "https://api.arbiscan.io/api",
          browserURL: "https://arbiscan.io/"
        }
      },
      { // https://snowtrace.io/documentation/recipes/hardhat-verification
        network: 'avalanche',
        chainId: 43114,
        urls: {
          apiURL: "https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan/api",
          browserURL: "https://snowtrace.io"
        }
      },
      {
        network: "base",
        chainId: 8453,
        urls: {
          apiURL: "https://api.basescan.org/api",
          browserURL: "https://basescan.org/"
        }
      },
      {
        network: "bsc",
        chainId: 56,
        urls: {
          apiURL: "https://api.bscscan.com/api",
          browserURL: "https://bscscan.com/"
        }
      },
      {
        network: "ethereum",
        chainId: 1,
        urls: {
          apiURL: "https://api.etherscan.io/api",
          browserURL: "https://etherscan.io/"
        }
      },
      {
        network: 'optimism',
        chainId: 10,
        urls: {
          apiURL: 'https://api-optimistic.etherscan.io/api',
          browserURL: 'https://optimistic.etherscan.io/'
        }
      },
      {
        network: "sepolia",
        chainId: 11155111,
        urls: {
          apiURL: "https://api-sepolia.etherscan.io/api",
          browserURL: "https://sepolia.etherscan.io"
        }
      },
      {
        network: "polygon",
        chainId: 137,
        urls: {
          apiURL: "https://api.polygonscan.com/api",
          browserURL: "https://polygonscan.com/"
        }
      },
    ]
  },
}
export default config;
