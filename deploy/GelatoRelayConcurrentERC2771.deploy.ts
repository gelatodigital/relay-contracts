import hre, { deployments, ethers, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../src/utils";
import { getAddresses } from "../src/addresses";
import { setCode } from "@nomicfoundation/hardhat-network-helpers";

const isHardhat = hre.network.name === "hardhat";
const isDevEnv = hre.network.name.endsWith("Dev");
const isDynamicNetwork = hre.network.isDynamic;

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const {
    deployer: hardhatAccount,
    relayDeployer,
    gelatoRelayConcurrentERC2771,
  } = await getNamedAccounts();

  let deployer: string;

  if (isHardhat) {
    deployer = hardhatAccount;
  } else {
    console.log(
      `\nDeploying GelatoRelayConcurrentERC2771 to ${hre.network.name}. Hit ctrl + c to abort`
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

  await deploy("GelatoRelayConcurrentERC2771", {
    from: deployer,
    deterministicDeployment: isDevEnv
      ? ethers.utils.formatBytes32String("dev")
      : ethers.utils.formatBytes32String("prod"), // The value is used as salt in create2
    args: [GELATO],
    log: !isHardhat,
  });

  // Overwrites already deployed relay contract for local testing
  if (isHardhat) {
    const gelatoRelayConcurrentERC2771Local = await (
      await deployments.get("GelatoRelayConcurrentERC2771")
    ).address;

    await setCode(
      gelatoRelayConcurrentERC2771,
      await hre.ethers.provider.getCode(gelatoRelayConcurrentERC2771Local)
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

func.tags = ["GelatoRelayConcurrentERC2771"];

export default func;
