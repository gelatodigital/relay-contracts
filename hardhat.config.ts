import { HardhatUserConfig } from "hardhat/config";

// PLUGINS
import "@nomiclabs/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@typechain/hardhat";
import "hardhat-deploy";
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-verify";

// ================================= TASKS =========================================
// ❗COMMENT IN to use || COMMENT OUT before git push to have CI work
import "./hardhat/tasks";

// Process Env Variables
import * as dotenv from "dotenv";
dotenv.config({ path: __dirname + "/.env" });

const ALCHEMY_ID = process.env.ALCHEMY_ID;

const BICOCCA_RPC_KEY = process.env.BICOCCA_RPC_KEY;

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

const RELAY_DEPLOYER_PK = process.env.RELAY_DEPLOYER_PK;
const RELAY_1BALANCE_DEPLOYER_PK = process.env.RELAY_1BALANCE_DEPLOYER_PK;
const RELAY_ERC2771_DEPLOYER_PK = process.env.RELAY_ERC2771_DEPLOYER_PK;
const RELAY_CONCURRENT_ERC2771_DEPLOYER_PK =
  process.env.RELAY_CONCURRENT_ERC2771_DEPLOYER_PK;

const DEV_RELAY_DEPLOYER_PK = process.env.DEV_RELAY_DEPLOYER_PK;
const DEV_RELAY_1BALANCE_DEPLOYER_PK =
  process.env.DEV_RELAY_1BALANCE_DEPLOYER_PK;
const DEV_RELAY_ERC2771_DEPLOYER_PK = process.env.DEV_RELAY_ERC2771_DEPLOYER_PK;
const DEV_RELAY_CONCURRENT_ERC2771_DEPLOYER_PK =
  process.env.DEV_RELAY_CONCURRENT_ERC2771_DEPLOYER_PK;

// CAUTION: for deployments put ALL keys in .env
let accounts: string[] = [];
if (
  RELAY_DEPLOYER_PK &&
  RELAY_1BALANCE_DEPLOYER_PK &&
  RELAY_ERC2771_DEPLOYER_PK &&
  RELAY_CONCURRENT_ERC2771_DEPLOYER_PK
) {
  accounts = [
    RELAY_DEPLOYER_PK,
    RELAY_1BALANCE_DEPLOYER_PK,
    RELAY_ERC2771_DEPLOYER_PK,
    RELAY_CONCURRENT_ERC2771_DEPLOYER_PK,
  ];
}

// CAUTION: for deployments put ALL keys in .env
let devAccounts: string[] = [];
if (
  DEV_RELAY_DEPLOYER_PK &&
  DEV_RELAY_1BALANCE_DEPLOYER_PK &&
  DEV_RELAY_ERC2771_DEPLOYER_PK &&
  DEV_RELAY_CONCURRENT_ERC2771_DEPLOYER_PK
) {
  devAccounts = [
    DEV_RELAY_DEPLOYER_PK,
    DEV_RELAY_1BALANCE_DEPLOYER_PK,
    DEV_RELAY_ERC2771_DEPLOYER_PK,
    DEV_RELAY_CONCURRENT_ERC2771_DEPLOYER_PK,
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
      default: "0x346389e519536A049588b8ADcde807B69A175939",
    },
    relayConcurrentERC2771Deployer: {
      default: "0x4e503a754507D04d6c4ac323b0bB77636C1EC80C",
    },

    // Dev Relay Deployers
    devRelayDeployer: {
      default: "0x1100555739378dEe764377bbc091ceae1a3574F1",
    },
    devRelay1BalanceDeployer: {
      default: "0x2d20e2882f4052eecDa682F6211477E4eBfe4B06",
    },
    devRelayERC2771Deployer: {
      default: "0xbfdFA5b712F5F36981E09945A5d6aF180dbF4b94",
    },
    devRelayConcurrentERC2771Deployer: {
      default: "0xD45e83690D56906b784D0e7f2cd79aD1bBEe31dc",
    },

    // Smart Contracts for local testing
    gelatoRelay: {
      hardhat: "0xaBcC9b596420A9E9172FD5938620E265a0f9Df92",
    },
    gelatoRelay1Balance: {
      hardhat: "0x75bA5Af8EFFDCFca32E1e288806d54277D1fde99",
    },
    gelatoRelayERC2771: {
      hardhat: "0xb539068872230f20456CF38EC52EF2f91AF4AE49",
    },
    gelatoRelay1BalanceERC2771: {
      hardhat: "0xd8253782c45a12053594b9deB72d8e8aB2Fca54c",
    },
    gelatoDiamond: {
      hardhat: "0x3caca7b48d0573d793d3b0279b5f0029180e83b6",
    },
  },

  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.g.alchemy.com/v2/${ALCHEMY_ID}`,
        blockNumber: 17146095,
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
    zksync: {
      accounts,
      chainId: 324,
      url: "https://mainnet.era.zksync.io",
      zksync: true,
      verifyURL:
        "https://zksync2-mainnet-explorer.zksync.io/contract_verification",
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
    bicocca: {
      accounts,
      chainId: 29313331,
      url: `https://gelato.bicoccachain.net?apikey=${BICOCCA_RPC_KEY}`,
      gasPrice: 0,
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
    lineaGoerli: {
      accounts,
      chainId: 59140,
      url: `https://rpc.goerli.linea.build`,
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
    zksyncGoerli: {
      accounts,
      chainId: 280,
      url: "https://testnet.era.zksync.dev",
      zksync: true,
      verifyURL:
        "https://zksync2-testnet-explorer.zksync.dev/contract_verification",
    },

    // Dev
    baseGoerliDev: {
      accounts: devAccounts,
      chainId: 84531,
      url: "https://goerli.base.org",
    },
    bicoccaDev: {
      accounts: devAccounts,
      chainId: 29313331,
      url: `https://gelato.bicoccachain.net?apikey=${BICOCCA_RPC_KEY}`,
      gasPrice: 0,
    },
    lineaGoerliDev: {
      accounts: devAccounts,
      chainId: 59140,
      url: `https://rpc.goerli.linea.build`,
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
    zksyncGoerliDev: {
      accounts: devAccounts,
      chainId: 280,
      url: "https://testnet.era.zksync.dev",
      zksync: true,
      verifyURL:
        "https://zksync2-testnet-explorer.zksync.dev/contract_verification",
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
        version: "0.8.20",
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

  zksolc: {
    version: "1.3.8",
    compilerSource: "binary",
    settings: {
      isSystem: false,
      forceEvmla: false,
      optimizer: {
        enabled: true,
        mode: "3",
      },
    },
  },
};

export default config;
