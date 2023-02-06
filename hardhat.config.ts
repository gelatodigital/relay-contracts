import { HardhatUserConfig } from "hardhat/config";

// PLUGINS
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import "hardhat-deploy";

// Process Env Variables
import * as dotenv from "dotenv";
dotenv.config({ path: __dirname + "/.env" });

const RELAY_DEV_DEPLOYER_PK = process.env.RELAY_DEV_DEPLOYER_PK;
// const RELAY_ERC2771_DEV_DEPLOYER = process.env.RELAY_ERC2771_DEV_DEPLOYER_PK;

const ALCHEMY_ID = process.env.ALCHEMY_ID;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",

  // hardhat-deploy
  namedAccounts: {
    deployer: {
      default: 0,
    },
    relayDevDeployer: {
      default: "0x36D362d58FF493d8803A9728F9aA7308df861281",
    },
    relayERC2771DevDeployer: {
      default: "0x457e3e8a93B105287Df789BaaC7CfFC1296e972B",
    },
  },

  networks: {
    hardhat: {
      forking: {
        url: `https://eth-goerli.g.alchemy.com/v2/${ALCHEMY_ID}`,
        blockNumber: 8445583,
      },
    },
    alfajores: {
      accounts: RELAY_DEV_DEPLOYER_PK ? [RELAY_DEV_DEPLOYER_PK] : [],
      chainId: 44787,
      url: "https://alfajores-forno.celo-testnet.org",
    },
    fuji: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      chainId: 43113,
      accounts: RELAY_DEV_DEPLOYER_PK ? [RELAY_DEV_DEPLOYER_PK] : [],
    },
    goerli: {
      accounts: RELAY_DEV_DEPLOYER_PK ? [RELAY_DEV_DEPLOYER_PK] : [],
      chainId: 5,
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_ID}`,
    },
    arbitrumGoerli: {
      accounts: RELAY_DEV_DEPLOYER_PK ? [RELAY_DEV_DEPLOYER_PK] : [],
      chainId: 421613,
      url: `https://arb-goerli.g.alchemy.com/v2/${ALCHEMY_ID}`,
    },
    mumbai: {
      accounts: RELAY_DEV_DEPLOYER_PK ? [RELAY_DEV_DEPLOYER_PK] : [],
      chainId: 80001,
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_ID}`,
    },
    optimisticGoerli: {
      url: `https://opt-goerli.g.alchemy.com/v2/${ALCHEMY_ID}`,
      chainId: 420,
      accounts: RELAY_DEV_DEPLOYER_PK ? [RELAY_DEV_DEPLOYER_PK] : [],
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
        version: "0.8.17",
        settings: {
          optimizer: { enabled: true, runs: 999999 },
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
