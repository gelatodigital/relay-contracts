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
    // Deploys GelatoRelay.sol
    relayDeployer: {
      default: "0xd1Ac051Dc0E1366502eF3Fe4D754fbeC6986a177",
    },
    // Deploys GelatoRelay1Balance.sol
    relay1BalanceDeployer: {
      default: "0x562c4e878b5Cd1f64007358695e8187CB4517c64",
    },
    // Deploys GelatoRelayERC2771.sol and GelatoRelay1BalanceERC2771.sol
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
    gelatoRelayConcurrentERC2771: {
      hardhat: "0x8598806401A63Ddf52473F1B3C55bC9E33e2d73b",
    },
    gelatoRelay1BalanceERC2771: {
      hardhat: "0xd8253782c45a12053594b9deB72d8e8aB2Fca54c",
    },
    gelatoRelay1BalanceConcurrentERC2771: {
      hardhat: "0xc65d82ECE367EF06bf2AB791B3f3CF037Dc0e816",
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
    astarzkevm: {
      accounts,
      chainId: 3776,
      url: `https://rpc.astar-zkevm.gelato.digital`,
    },
    avalanche: {
      accounts,
      url: "https://api.avax.network/ext/bc/C/rpc",
      chainId: 43114,
    },
    base: {
      accounts,
      chainId: 8453,
      url: `https://mainnet.base.org`,
    },
    blast: {
      accounts,
      chainId: 81457,
      url: "",
      gasPrice: 100000000,
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
    linea: {
      accounts,
      chainId: 59144,
      url: `https://rpc.linea.build`,
    },
    lisk: {
      url: `https://rpc.api.lisk.com`,
      chainId: 1135,
      accounts,
    },
    metis: {
      accounts,
      chainId: 1088,
      url: "https://metis-mainnet.public.blastapi.io",
    },
    mode: {
      accounts,
      url: "https://mainnet.mode.network",
      chainId: 34443,
      gasPrice: 80000000,
    },
    optimism: {
      accounts,
      url: `https://opt-mainnet.g.alchemy.com/v2/${ALCHEMY_ID}`,
      chainId: 10,
    },
    playblock: {
      accounts,
      url: `https://rpc.playblock.io`,
      chainId: 1829,
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
    rari: {
      accounts,
      chainId: 1380012617,
      url: "https://mainnet.rpc.rarichain.org/http",
    },
    real: {
      accounts,
      chainId: 111188,
      url: "https://rpc.realforreal.gelato.digital",
    },
    reya: {
      accounts,
      chainId: 1729,
      url: "https://rpc.reya.network",
    },
    rootstock: {
      url: `https://public-node.rsk.co`,
      accounts,
      chainId: 30,
    },
    shibarium: {
      accounts,
      chainId: 109,
      url: "https://www.shibrpc.com",
      gasPrice: 2500000007,
    },
    zksync: {
      accounts,
      chainId: 324,
      url: "https://mainnet.era.zksync.io",
      zksync: true,
      verifyURL:
        "https://zksync2-mainnet-explorer.zksync.io/contract_verification",
    },
    zora: {
      accounts,
      chainId: 7777777,
      url: "https://rpc.zora.co",
      gasPrice: 1500000000,
    },

    // Staging
    alephzeroTestnet: {
      accounts,
      chainId: 2039,
      url: `https://rpc.alephzero-testnet.gelato.digital`,
    },
    amoy: {
      accounts,
      chainId: 80002,
      url: `https://rpc-amoy.polygon.technology`,
      gasPrice: 40000000000,
    },
    anomalyAndromeda: {
      accounts,
      chainId: 241120,
      url: `https://rpc.anomaly-andromeda.anomalygames.io`,
    },
    arbitrumGoerli: {
      accounts,
      chainId: 421613,
      url: `https://arb-goerli.g.alchemy.com/v2/${ALCHEMY_ID}`,
    },
    arbitrumSepolia: {
      accounts,
      url: `https://arb-sepolia.g.alchemy.com/v2/${ALCHEMY_ID}`,
      chainId: 421614,
    },
    astarzkyoto: {
      accounts,
      url: `https://rpc.zkyoto.gelato.digital`,
      chainId: 6038361,
    },
    baseGoerli: {
      accounts,
      chainId: 84531,
      url: "https://goerli.base.org",
      gasPrice: 150000005,
    },
    baseSepolia: {
      accounts,
      chainId: 84532,
      url: `https://sepolia.base.org`,
      gasPrice: 150000005,
    },
    blastSepolia: {
      accounts,
      chainId: 168587773,
      url: `https://sepolia.blast.io`,
    },
    chiado: {
      accounts,
      chainId: 10200,
      url: "https://rpc.chiadochain.net",
      gasPrice: 1500000000,
    },
    connextSepolia: {
      accounts,
      chainId: 6398,
      url: `https://rpc.connext-sepolia.gelato.digital`,
    },
    gelatoorbittestnet: {
      accounts,
      chainId: 88153591557,
      url: "https://rpc.gelato-orbit-anytrust-testnet.gelato.digital",
    },
    geloptestnet: {
      accounts,
      chainId: 42069,
      url: "https://rpc.op-testnet.gelato.digital",
    },
    gelopcelestiatestnet: {
      accounts,
      chainId: 123420111,
      url: "https://rpc.op-celestia-testnet.gelato.digital",
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
    liskSepolia: {
      accounts,
      chainId: 4202,
      url: `https://rpc.lisk-sepolia-testnet.gelato.digital`,
    },
    meldkanazawa: {
      accounts,
      chainId: 222000222,
      url: `https://subnets.avax.network/meld/testnet/rpc`,
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
      gasPrice: 3000000057,
    },
    optimismSepolia: {
      accounts,
      url: `https://opt-sepolia.g.alchemy.com/v2/${ALCHEMY_ID}`,
      chainId: 11155420,
      gasPrice: 3000000057,
    },
    playnanceTestnet: {
      accounts,
      url: `https://rpc.orbit-anytrust-testnet.gelato.digital`,
      chainId: 80998896642,
    },
    polygonBlackberry: {
      accounts,
      chainId: 94204209,
      url: `https://rpc.polygon-blackberry.gelato.digital`,
    },
    polygonZkGoerli: {
      accounts,
      chainId: 1442,
      url: "https://rpc.public.zkevm-test.net",
    },
    reyaCronos: {
      accounts,
      chainId: 89346161,
      url: "https://rpc.reya-cronos.gelato.digital",
    },
    sepolia: {
      accounts,
      chainId: 11155111,
      url: "https://eth-sepolia.public.blastapi.io",
    },
    unreal: {
      accounts,
      chainId: 18231,
      url: "https://rpc.unreal.gelato.digital",
    },
    unrealOrbit: {
      accounts,
      chainId: 18233,
      url: "https://rpc.unreal-orbit.gelato.digital",
    },
    verifyTestnet: {
      accounts,
      chainId: 1833,
      url: `https://rpc.verify-testnet.gelato.digital`,
    },
    zkatana: {
      accounts,
      chainId: 1261120,
      url: "https://rpc.zkatana.gelato.digital",
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

    amoyDev: {
      accounts: devAccounts,
      chainId: 80002,
      url: `https://rpc-amoy.polygon.technology`,
    },
    baseGoerliDev: {
      accounts: devAccounts,
      chainId: 84531,
      url: "https://goerli.base.org",
      gasPrice: 150000005,
    },
    gelatoorbittestnetDev: {
      accounts: devAccounts,
      chainId: 88153591557,
      url: `https://rpc.arb-blueberry.gelato.digital`,
    },
    lineaGoerliDev: {
      accounts: devAccounts,
      chainId: 59140,
      url: `https://rpc.goerli.linea.build`,
    },
    meldkanazawaDev: {
      accounts: devAccounts,
      chainId: 222000222,
      url: `https://subnets.avax.network/meld/testnet/rpc`,
    },
    mumbaiDev: {
      accounts: devAccounts,
      chainId: 80001,
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_ID}`,
      gasPrice: 1500000000,
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
          // Some networks don't support opcode PUSH0, we need to override evmVersion
          // See https://stackoverflow.com/questions/76328677/remix-returned-error-jsonrpc2-0-errorinvalid-opcode-push0-id24
          evmVersion: "paris",
        },
      },
    ],
  },

  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },

  zksolc: {
    version: "1.3.13",
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
