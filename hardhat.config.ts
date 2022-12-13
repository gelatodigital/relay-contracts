import { HardhatUserConfig } from "hardhat/config";

// PLUGINS
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import "hardhat-deploy";

// ================================= TASKS =========================================
// ❗COMMENT IN to use || COMMENT OUT before git push to have CI work
import "./hardhat/tasks";

// Process Env Variables
import * as dotenv from "dotenv";
dotenv.config({ path: __dirname + "/.env" });

// const RELAY_DEPLOYER_PK = process.env.RELAY_DEPLOYER_PK;
const RELAY_ERC2771_DEPLOYER_PK = process.env.RELAY_ERC2771_DEPLOYER_PK;
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
    relayERC2771Deployer: {
      default: "0xa4342E17DC5f5Ad441258F11cc2871D84a26FBfe",
    },
  },

  networks: {
    hardhat: {
      forking: {
        url: `https://api.avax-test.network/ext/bc/C/rpc`,
        blockNumber: 15627952,
      },
    },
    alfajores: {
      accounts: RELAY_ERC2771_DEPLOYER_PK ? [RELAY_ERC2771_DEPLOYER_PK] : [],
      chainId: 44787,
      url: "https://alfajores-forno.celo-testnet.org",
    },
    arbitrum: {
      accounts: RELAY_ERC2771_DEPLOYER_PK ? [RELAY_ERC2771_DEPLOYER_PK] : [],
      chainId: 42161,
      url: `https://arb-mainnet.g.alchemy.com/v2/${ALCHEMY_ID}`,
    },
    avalanche: {
      accounts: RELAY_ERC2771_DEPLOYER_PK ? [RELAY_ERC2771_DEPLOYER_PK] : [],
      url: "https://api.avax.network/ext/bc/C/rpc",
      chainId: 43114,
    },
    bnb: {
      accounts: RELAY_ERC2771_DEPLOYER_PK ? [RELAY_ERC2771_DEPLOYER_PK] : [],
      chainId: 56,
      url: "https://bsc-dataseed1.ninicoin.io/",
    },
    celo: {
      accounts: RELAY_ERC2771_DEPLOYER_PK ? [RELAY_ERC2771_DEPLOYER_PK] : [],
      url: "https://forno.celo.org",
      chainId: 42220,
    },
    ethereum: {
      accounts: RELAY_ERC2771_DEPLOYER_PK ? [RELAY_ERC2771_DEPLOYER_PK] : [],
      chainId: 1,
      url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_ID}`,
    },
    gnosis: {
      accounts: RELAY_ERC2771_DEPLOYER_PK ? [RELAY_ERC2771_DEPLOYER_PK] : [],
      chainId: 100,
      url: `https://rpc.gnosischain.com/`,
    },
    fuji: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      chainId: 43113,
      accounts: RELAY_ERC2771_DEPLOYER_PK ? [RELAY_ERC2771_DEPLOYER_PK] : [],
    },
    goerli: {
      accounts: RELAY_ERC2771_DEPLOYER_PK ? [RELAY_ERC2771_DEPLOYER_PK] : [],
      chainId: 5,
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_ID}`,
    },
    arbitrumGoerli: {
      accounts: RELAY_ERC2771_DEPLOYER_PK ? [RELAY_ERC2771_DEPLOYER_PK] : [],
      chainId: 421613,
      url: `https://arb-goerli.g.alchemy.com/v2/${ALCHEMY_ID}`,
    },
    polygon: {
      accounts: RELAY_ERC2771_DEPLOYER_PK ? [RELAY_ERC2771_DEPLOYER_PK] : [],
      chainId: 137,
      url: `https://polygon-mainnet.g.alchemy.com/v2/${ALCHEMY_ID}`,
    },
    mumbai: {
      accounts: RELAY_ERC2771_DEPLOYER_PK ? [RELAY_ERC2771_DEPLOYER_PK] : [],
      chainId: 80001,
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_ID}`,
    },
    moonbeam: {
      accounts: RELAY_ERC2771_DEPLOYER_PK ? [RELAY_ERC2771_DEPLOYER_PK] : [],
      url: "https://moonbeam.api.onfinality.io/public",
      chainId: 1284,
    },
    moonriver: {
      accounts: RELAY_ERC2771_DEPLOYER_PK ? [RELAY_ERC2771_DEPLOYER_PK] : [],
      url: "https://moonriver-rpc.dwellir.com",
      chainId: 1285,
    },
    optimisticGoerli: {
      accounts: RELAY_ERC2771_DEPLOYER_PK ? [RELAY_ERC2771_DEPLOYER_PK] : [],
      url: `https://opt-goerli.g.alchemy.com/v2/${ALCHEMY_ID}`,
      chainId: 420,
    },
    optimism: {
      accounts: RELAY_ERC2771_DEPLOYER_PK ? [RELAY_ERC2771_DEPLOYER_PK] : [],
      url: `https://opt-mainnet.g.alchemy.com/v2/${ALCHEMY_ID}`,
      chainId: 10,
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
