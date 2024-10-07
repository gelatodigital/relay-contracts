import { TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD } from "hardhat/builtin-tasks/task-names";
import { extendEnvironment, HardhatUserConfig, subtask } from "hardhat/config";
import path from "path";

// PLUGINS
import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-verify";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import "hardhat-deploy";

// ================================= TASKS =========================================
// ❗COMMENT IN to use || COMMENT OUT before git push to have CI work
import "./hardhat/tasks";

// Process Env Variables
import * as dotenv from "dotenv";
import { ethers } from "ethers";
import { verifyRequiredEnvVar } from "./src/utils";
dotenv.config({ path: __dirname + "/.env" });

const ALCHEMY_ID = process.env.ALCHEMY_ID;

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

const RELAY_DEPLOYER_PK = process.env.RELAY_DEPLOYER_PK;

if (!RELAY_DEPLOYER_PK) {
  throw new Error("RELAY_DEPLOYER_PK is missing");
}
const accounts: string[] = [RELAY_DEPLOYER_PK];

extendEnvironment((hre) => {
  if (hre.network.name === "dynamic") {
    hre.network.isDynamic = true;
    const networkName = process.env.HARDHAT_DYNAMIC_NETWORK_NAME as
      | string
      | undefined;
    const networkUrl = process.env.HARDHAT_DYNAMIC_NETWORK_URL as
      | string
      | undefined;
    const gelatoContractAddress = process.env
      .HARDHAT_DYNAMIC_NETWORK_CONTRACTS_GELATO as string | undefined;
    const noDeterministicDeployment = process.env
      .HARDHAT_DYNAMIC_NETWORK_NO_DETERMINISTIC_DEPLOYMENT as
      | string
      | undefined;

    verifyRequiredEnvVar("HARDHAT_DYNAMIC_NETWORK_NAME", networkName);
    verifyRequiredEnvVar("HARDHAT_DYNAMIC_NETWORK_URL", networkUrl);
    verifyRequiredEnvVar(
      "HARDHAT_DYNAMIC_NETWORK_CONTRACTS_GELATO",
      gelatoContractAddress
    );

    hre.network.name = networkName;
    hre.network.config.url = networkUrl;
    hre.network.contracts = {
      GELATO: ethers.utils.getAddress(gelatoContractAddress),
    };
    hre.network.noDeterministicDeployment =
      noDeterministicDeployment === "true";
  } else {
    hre.network.isDynamic = false;
    hre.network.noDeterministicDeployment = hre.network.config.zksync ?? false;
  }
});

subtask(
  TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD,
  async (
    args: {
      solcVersion: string;
    },
    hre,
    runSuper
  ) => {
    // Full list of solc versions: https://github.com/ethereum/solc-bin/blob/gh-pages/bin/list.json
    // Search by the version number in the list, there will be `nightly` versions as well along with the main in the list.json
    // Find the one that is NOT a nightly build, and copy the `path` field in the build object
    // The solidity compiler will be found at `https://github.com/ethereum/solc-bin/blob/gh-pages/bin/${path-field-in-the-build}`
    if (args.solcVersion === "0.8.20") {
      const compilerPath = path.join(
        __dirname,
        "src/solc",
        "soljson-v0.8.20+commit.a1b79de6.js"
      );

      return {
        compilerPath,
        isSolcJs: true,
        version: args.solcVersion,
        longVersion: "0.8.20+commit.a1b79de6",
      };
    }

    // Only overrides the compiler for version 0.8.20,
    // the runSuper function allows us to call the default subtask.
    return runSuper();
  }
);

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",

  // hardhat-deploy
  namedAccounts: {
    deployer: {
      default: 0,
    },
    relayDeployer: {
      default: "0x7aD7b5F4F0E5Df7D6Aa5444516429AF77babc3A0",
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
    dynamic: {
      accounts,
      url: "",
    },

    // Prod
    alephzero: {
      accounts,
      chainId: 41455,
      url: `https://rpc.alephzero.raas.gelato.cloud`,
    },
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
    ethernity: {
      url: `https://mainnet.ethernitychain.io`,
      accounts,
      chainId: 183,
    },
    everclear: {
      url: `https://rpc.everclear.raas.gelato.cloud`,
      accounts,
      chainId: 25327,
    },
    filecoin: {
      url: `https://filecoin.chainup.net/rpc/v1`,
      accounts,
      chainId: 314,
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
    prism: {
      url: `https://mainnet-rpc.lumia.org`,
      accounts,
      chainId: 994873017,
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
    berachainbartio: {
      accounts,
      chainId: 80084,
      url: `https://bartio.rpc.berachain.com/`,
    },
    blastSepolia: {
      accounts,
      chainId: 168587773,
      url: `https://sepolia.blast.io`,
    },
    bonito: {
      accounts,
      chainId: 69658185,
      url: `https://rpc.bonito-testnet.t.raas.gelato.cloud`,
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
    ethernityTestnet: {
      accounts,
      chainId: 233,
      url: `https://testnet.ethernitychain.io`,
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
    openCampusCodex: {
      accounts,
      url: `https://rpc.open-campus-codex.gelato.digital`,
      chainId: 656476,
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
      chainId: 89346162,
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
      accounts,
      chainId: 80002,
      url: `https://rpc-amoy.polygon.technology`,
    },
    baseGoerliDev: {
      accounts,
      chainId: 84531,
      url: "https://goerli.base.org",
      gasPrice: 150000005,
    },
    gelatoorbittestnetDev: {
      accounts,
      chainId: 88153591557,
      url: `https://rpc.arb-blueberry.gelato.digital`,
    },
    lineaGoerliDev: {
      accounts,
      chainId: 59140,
      url: `https://rpc.goerli.linea.build`,
    },
    meldkanazawaDev: {
      accounts,
      chainId: 222000222,
      url: `https://subnets.avax.network/meld/testnet/rpc`,
    },
    mumbaiDev: {
      accounts,
      chainId: 80001,
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_ID}`,
      gasPrice: 1500000000,
    },
    polygonZkGoerliDev: {
      accounts,
      chainId: 1442,
      url: "https://rpc.public.zkevm-test.net",
    },
    zksyncGoerliDev: {
      accounts,
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
