import {
  impersonateAccount,
  setBalance,
} from "@nomicfoundation/hardhat-network-helpers";
import { keccak256, toUtf8Bytes } from "ethers/lib/utils";
import hre, { deployments, ethers, getNamedAccounts } from "hardhat";
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { getAddresses } from "../src/addresses";
import { sleep } from "../src/utils";
import { EIP173Proxy, IEIP173Proxy } from "../typechain";

const isHardhat = hre.network.name === "hardhat";
const isDevEnv = hre.network.name.endsWith("Dev");
const isDynamicNetwork = hre.network.isDynamic;
// eslint-disable-next-line @typescript-eslint/naming-convention
const noDeterministicDeployment = hre.network.noDeterministicDeployment;

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const {
    deployer: hardhatAccount,
    relayDeployer,
    gelatoRelay,
  } = await getNamedAccounts();

  let deployer: string;

  if (isHardhat) {
    deployer = hardhatAccount;
  } else {
    console.log(
      `\nDeploying GelatoRelay to ${hre.network.name}. Hit ctrl + c to abort`
    );
    console.log(`\n IS DEV ENV: ${isDevEnv} \n`);

    deployer = relayDeployer;

    await sleep(5000);
  }

  const { GELATO } = getAddresses(hre.network.name, isDynamicNetwork);

  if (!GELATO) {
    console.error(`GELATO not defined on network: ${hre.network.name}`);
    process.exit(1);
  }

  const deployment = await deploy("GelatoRelay", {
    from: deployer,
    proxy: {
      proxyContract: "EIP173Proxy",
      proxyArgs: [ethers.constants.AddressZero, deployer, "0x"],
    },
    deterministicDeployment: noDeterministicDeployment
      ? false
      : isDevEnv
      ? keccak256(toUtf8Bytes("GelatoRelay-dev"))
      : keccak256(toUtf8Bytes("GelatoRelay-prod")), // The value is used as salt in create2
    args: [GELATO],
    log: !isHardhat,
  });

  if (deployment.newlyDeployed) {
    const signer = await hre.ethers.getSigner(deployer);

    const proxy = (await hre.ethers.getContractAt(
      "EIP173Proxy",
      deployment.address,
      signer
    )) as EIP173Proxy;

    const implementation = (await deployments.get("GelatoRelay_Implementation"))
      .address;
    await proxy.upgradeTo(implementation);
  }

  // For local testing we want to upgrade the forked
  // instance of gelatoRelay to our locally deployed implementation
  if (isHardhat) {
    const gelatoRelayProxy = (await hre.ethers.getContractAt(
      "IEIP173Proxy",
      gelatoRelay
    )) as IEIP173Proxy;

    const gelatoRelayOwnerAddr = await gelatoRelayProxy.owner();

    await impersonateAccount(gelatoRelayOwnerAddr);
    await setBalance(gelatoRelayOwnerAddr, hre.ethers.utils.parseEther("1"));

    const gelatoRelayOwner = await hre.ethers.getSigner(gelatoRelayOwnerAddr);

    await gelatoRelayProxy
      .connect(gelatoRelayOwner)
      .upgradeTo(
        (
          await deployments.get("GelatoRelay_Implementation")
        ).address,
        { gasLimit: 1_000_000 }
      );
  }
};

func.skip = async () => {
  if (isDynamicNetwork) {
    return false;
  } else {
    return !isHardhat;
  }
};

func.dependencies = ["GelatoRelay1Balance"];
func.tags = ["GelatoRelay"];

export default func;
