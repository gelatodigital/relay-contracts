import { HardhatUserConfig } from "hardhat/config";

// PLUGINS
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import "hardhat-deploy";

// Process Env Variables
import * as dotenv from "dotenv";
import { ethers, utils } from "ethers";
dotenv.config({ path: __dirname + "/.env" });

const PK = process.env.PK;
const DEV_PK = process.env.DEV_PK;
const PK_MAINNET = process.env.PK_MAINNET;
const ALCHEMY_ID = process.env.ALCHEMY_ID;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",

  // hardhat-deploy
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },

  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_ID}`,
        blockNumber: 13476568, // ether price $4,168.96
      },
      accounts: {
        accountsBalance: ethers.utils.parseEther("10000").toString(),
      },
    },
    alfajores: {
      accounts: PK_MAINNET ? [PK_MAINNET] : [],
      chainId: 44787,
      url: "https://alfajores-forno.celo-testnet.org",
    },
    bsc: {
      accounts: PK_MAINNET ? [PK_MAINNET] : [],
      chainId: 56,
      url: "https://bsc-dataseed1.ninicoin.io/",
    },
    evmos: {
      accounts: PK_MAINNET ? [PK_MAINNET] : [],
      chainId: 9001,
      url: "https://eth.bd.evmos.org:8545",
    },
    rinkeby: {
      accounts: PK ? [PK] : [],
      chainId: 4,
      url: `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_ID}`,
      gasPrice: parseInt(utils.parseUnits("3", "gwei").toString()),
    },
    gnosis: {
      accounts: PK_MAINNET ? [PK_MAINNET] : [],
      chainId: 100,
      url: `https://rpc.gnosischain.com/`,
      gasPrice: parseInt(utils.parseUnits("13", "gwei").toString()),
    },
    goerli: {
      accounts: PK ? [PK] : [],
      chainId: 5,
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_ID}`,
      gasPrice: parseInt(utils.parseUnits("6", "gwei").toString()),
    },
    kovan: {
      accounts: PK ? [PK] : [],
      chainId: 42,
      url: `https://eth-kovan.alchemyapi.io/v2/${ALCHEMY_ID}`,
      gasPrice: parseInt(utils.parseUnits("6", "gwei").toString()),
    },
    mainnet: {
      accounts: PK_MAINNET ? [PK_MAINNET] : [],
      chainId: 1,
      url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_ID}`,
    },
    matic: {
      accounts: PK_MAINNET ? [PK_MAINNET] : [],
      chainId: 137,
      url: `https://polygon-mainnet.g.alchemy.com/v2/${ALCHEMY_ID}`,
    },
    mumbai: {
      accounts: DEV_PK ? [DEV_PK] : [],
      chainId: 80001,
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_ID}`,
    },
  },
  verify: {
    etherscan: {
      apiKey: ETHERSCAN_API_KEY ? ETHERSCAN_API_KEY : "",
    },
  },

  solidity: {
    compilers: [
      {
        version: "0.8.15",
        settings: {
          optimizer: { enabled: true, runs: 200000 },
          modelChecker: {
            targets: [
              "balance",
              "outOfBounds",
              "popEmptyArray",
              "constantCondition",
              "divByZero",
              "assert",
              "underflow",
              "overflow",
            ],
            showUnproved: true,
            engine: "none",
            // contracts: {
            //   "contracts/GelatoRelayer.sol": ["GelatoRelayer"],
            // },
            // invariants: ["contract", "reentrancy"],
          },
        },
      },
    ],
  },

  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
};

export default config;
