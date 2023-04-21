import { HardhatUserConfig } from "hardhat/config";

// PLUGINS
import "@nomiclabs/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@typechain/hardhat";
import "hardhat-deploy";

// ================================= TASKS =========================================
// ❗COMMENT IN to use || COMMENT OUT before git push to have CI work
import "./hardhat/tasks";

// Process Env Variables
import * as dotenv from "dotenv";
dotenv.config({ path: __dirname + "/.env" });

const ALCHEMY_ID = process.env.ALCHEMY_ID;

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

const RELAY_DEPLOYER_PK = process.env.RELAY_DEPLOYER_PK;
const RELAY_1BALANCE_DEPLOYER_PK = process.env.RELAY_1BALANCE_DEPLOYER_PK;
const RELAY_ERC2771_DEPLOYER_PK = process.env.RELAY_ERC2771_DEPLOYER_PK;

const DEV_RELAY_DEPLOYER_PK = process.env.DEV_RELAY_DEPLOYER_PK;
const DEV_RELAY_1BALANCE_DEPLOYER_PK =
  process.env.DEV_RELAY_1BALANCE_DEPLOYER_PK;
const DEV_RELAY_ERC2771_DEPLOYER_PK = process.env.DEV_RELAY_ERC2771_DEPLOYER_PK;

// CAUTION: for deployments put ALL keys in .env
let accounts: string[] = [];
if (
  RELAY_DEPLOYER_PK &&
  RELAY_1BALANCE_DEPLOYER_PK &&
  RELAY_ERC2771_DEPLOYER_PK
) {
  accounts = [
    RELAY_DEPLOYER_PK,
    RELAY_1BALANCE_DEPLOYER_PK,
    RELAY_ERC2771_DEPLOYER_PK,
  ];
}

// CAUTION: for deployments put ALL keys in .env
let devAccounts: string[] = [];
if (
  DEV_RELAY_DEPLOYER_PK &&
  DEV_RELAY_1BALANCE_DEPLOYER_PK &&
  DEV_RELAY_ERC2771_DEPLOYER_PK
) {
  devAccounts = [
    DEV_RELAY_DEPLOYER_PK,
    DEV_RELAY_1BALANCE_DEPLOYER_PK,
    DEV_RELAY_ERC2771_DEPLOYER_PK,
  ];
}

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",

  // hardhat-deploy
  namedAccounts: {
    deployer: {
      default: 0,
    },
    // Relay Deployers
    relayDeployer: {
      default: "0xd1Ac051Dc0E1366502eF3Fe4D754fbeC6986a177",
    },
    relay1BalanceDeployer: {
      default: "0x562c4e878b5Cd1f64007358695e8187CB4517c64",
    },
    relayERC2771Deployer: {
      default: "0xa4342E17DC5f5Ad441258F11cc2871D84a26FBfe",
    },

    // Dev Relay Deployers
    devRelayDeployer: {
      default: "0x1100555739378dEe764377bbc091ceae1a3574F1",
    },
    devRelay1BalanceDeployer: {
      default: "0x2d20e2882f4052eecDa682F6211477E4eBfe4B06",
    },
    devRelayERC2771Deployer: {
      default: "0x6Cc27Ae5440d8016A36350fbaDA0Ed209Ad89822",
    },

    // Smart Contracts for local testing
    gelatoRelay: {
      hardhat: "0xaBcC9b596420A9E9172FD5938620E265a0f9Df92",
    },
    gelatoRelayERC2771: {
      hardhat: "0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d",
    },
    gelatoDiamond: {
      hardhat: "0x3caca7b48d0573d793d3b0279b5f0029180e83b6",
    },
  },

  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.g.alchemy.com/v2/${ALCHEMY_ID}`,
        blockNumber: 16742309,
      },
    },

    // Prod
    arbitrum: {
      accounts,
      chainId: 42161,
      url: `https://arb-mainnet.g.alchemy.com/v2/${ALCHEMY_ID}`,
    },
    avalanche: {
      accounts,
      url: "https://api.avax.network/ext/bc/C/rpc",
      chainId: 43114,
    },
    bnb: {
      accounts,
      chainId: 56,
      url: "https://bsc-dataseed1.ninicoin.io/",
    },
    ethereum: {
      accounts,
      chainId: 1,
      url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_ID}`,
    },
    gnosis: {
      accounts,
      chainId: 100,
      url: `https://rpc.gnosischain.com/`,
    },
    moonbeam: {
      accounts,
      chainId: 1284,
      url: "https://moonbeam.api.onfinality.io/public",
    },
    moonriver: {
      accounts,
      chainId: 1285,
      url: "https://moonriver.public.blastapi.io",
    },
    optimism: {
      accounts,
      url: `https://opt-mainnet.g.alchemy.com/v2/${ALCHEMY_ID}`,
      chainId: 10,
    },
    polygon: {
      accounts,
      chainId: 137,
      url: `https://polygon-mainnet.g.alchemy.com/v2/${ALCHEMY_ID}`,
    },
    polygonZk: {
      accounts,
      chainId: 1101,
      url: "https://zkevm-rpc.com",
    },

    // Staging
    arbitrumGoerli: {
      accounts,
      chainId: 421613,
      url: `https://arb-goerli.g.alchemy.com/v2/${ALCHEMY_ID}`,
    },
    baseGoerli: {
      accounts,
      chainId: 84531,
      url: "https://goerli.base.org",
    },
    chiado: {
      accounts,
      chainId: 10200,
      url: "https://rpc.chiadochain.net",
      gasPrice: 1500000000,
    },
    goerli: {
      accounts,
      chainId: 5,
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_ID}`,
    },
    mumbai: {
      accounts,
      chainId: 80001,
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_ID}`,
    },
    optimismGoerli: {
      accounts,
      url: `https://opt-goerli.g.alchemy.com/v2/${ALCHEMY_ID}`,
      chainId: 420,
    },
    polygonZkGoerli: {
      accounts,
      chainId: 1442,
      url: "https://rpc.public.zkevm-test.net",
    },

    // Dev
    baseGoerliDev: {
      accounts: devAccounts,
      chainId: 84531,
      url: "https://goerli.base.org",
    },
    mumbaiDev: {
      accounts: devAccounts,
      chainId: 80001,
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_ID}`,
    },
    polygonZkGoerliDev: {
      accounts: devAccounts,
      chainId: 1442,
      url: "https://rpc.public.zkevm-test.net",
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
        version: "0.8.19",
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
