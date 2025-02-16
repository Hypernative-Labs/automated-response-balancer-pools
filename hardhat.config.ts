import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { readENV } from "./scripts/utils";


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
}
export default config;
