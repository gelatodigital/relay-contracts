import { HardhatUserConfig } from "hardhat/config";

// PLUGINS
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import "hardhat-deploy";

// Process Env Variables
import * as dotenv from "dotenv";
dotenv.config({ path: __dirname + "/.env" });

const RELAY_DEPLOYER_PK = process.env.RELAY_DEPLOYER_PK;
const ALCHEMY_ID = process.env.ALCHEMY_ID;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",

  // hardhat-deploy
  namedAccounts: {
    deployer: {
      default: 0,
    },
    relayDeployer: {
      default: "0xd1Ac051Dc0E1366502eF3Fe4D754fbeC6986a177",
    },
  },

  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_ID}`,
        blockNumber: 13476568,
      },
    },
    alfajores: {
      accounts: RELAY_DEPLOYER_PK ? [RELAY_DEPLOYER_PK] : [],
      chainId: 44787,
      url: "https://alfajores-forno.celo-testnet.org",
    },
    avalanche: {
      url: "https://api.avax.network/ext/bc/C/rpc",
      chainId: 43114,
      accounts: RELAY_DEPLOYER_PK ? [RELAY_DEPLOYER_PK] : [],
    },
    bsc: {
      accounts: RELAY_DEPLOYER_PK ? [RELAY_DEPLOYER_PK] : [],
      chainId: 56,
      url: "https://bsc-dataseed1.ninicoin.io/",
    },
    evmos: {
      accounts: RELAY_DEPLOYER_PK ? [RELAY_DEPLOYER_PK] : [],
      chainId: 9001,
      url: "https://eth.bd.evmos.org:8545",
    },
    rinkeby: {
      accounts: RELAY_DEPLOYER_PK ? [RELAY_DEPLOYER_PK] : [],
      chainId: 4,
      url: `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_ID}`,
    },
    gnosis: {
      accounts: RELAY_DEPLOYER_PK ? [RELAY_DEPLOYER_PK] : [],
      chainId: 100,
      url: `https://rpc.gnosischain.com/`,
    },
    goerli: {
      accounts: RELAY_DEPLOYER_PK ? [RELAY_DEPLOYER_PK] : [],
      chainId: 5,
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_ID}`,
    },
    kovan: {
      accounts: RELAY_DEPLOYER_PK ? [RELAY_DEPLOYER_PK] : [],
      chainId: 42,
      url: `https://eth-kovan.alchemyapi.io/v2/${ALCHEMY_ID}`,
    },
    mainnet: {
      accounts: RELAY_DEPLOYER_PK ? [RELAY_DEPLOYER_PK] : [],
      chainId: 1,
      url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_ID}`,
    },
    matic: {
      accounts: RELAY_DEPLOYER_PK ? [RELAY_DEPLOYER_PK] : [],
      chainId: 137,
      url: `https://polygon-mainnet.g.alchemy.com/v2/${ALCHEMY_ID}`,
    },
    mumbai: {
      accounts: RELAY_DEPLOYER_PK ? [RELAY_DEPLOYER_PK] : [],
      chainId: 80001,
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_ID}`,
    },
    moonbeam: {
      url: "https://moonbeam.api.onfinality.io/public",
      chainId: 1284,
      accounts: RELAY_DEPLOYER_PK ? [RELAY_DEPLOYER_PK] : [],
    },
    moonriver: {
      url: "https://moonriver-rpc.dwellir.com",
      chainId: 1285,
      accounts: RELAY_DEPLOYER_PK ? [RELAY_DEPLOYER_PK] : [],
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
        version: "0.8.16",
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
