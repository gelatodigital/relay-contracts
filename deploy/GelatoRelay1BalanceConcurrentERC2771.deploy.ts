import { deployments, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../src/utils";
import { getAddresses } from "../src/addresses";
import { setCode } from "@nomicfoundation/hardhat-network-helpers";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const {
    deployer: hardhatAccount,
    relayConcurrentERC2771Deployer,
    devRelayConcurrentERC2771Deployer,
    gelatoRelay1BalanceConcurrentERC2771,
  } = await getNamedAccounts();

  const isHardhat = hre.network.name === "hardhat";
  const isDevEnv = hre.network.name.endsWith("Dev");

  let deployer: string;

  if (isHardhat) {
    deployer = hardhatAccount;
  } else {
    console.log(
      `\nDeploying GelatoRelay1BalanceConcurrentERC2771 to ${hre.network.name}. Hit ctrl + c to abort`
    );
    console.log(`\n IS DEV ENV: ${isDevEnv} \n`);

    deployer = isDevEnv
      ? devRelayConcurrentERC2771Deployer
      : relayConcurrentERC2771Deployer;

    await sleep(5000);
  }

  const { GELATO } = getAddresses(hre.network.name);

  if (!GELATO) {
    console.error(`GELATO not defined on network: ${hre.network.name}`);
    process.exit(1);
  }

  await deploy("GelatoRelay1BalanceConcurrentERC2771", {
    from: deployer,
    args: [GELATO],
    log: !isHardhat,
  });

  // Overwrites already deployed relay contract for local testing
  if (isHardhat) {
    const gelatoRelay1BalanceConcurrentERC2771Local = await (
      await deployments.get("GelatoRelay1BalanceConcurrentERC2771")
    ).address;

    await setCode(
      gelatoRelay1BalanceConcurrentERC2771,
      await hre.ethers.provider.getCode(
        gelatoRelay1BalanceConcurrentERC2771Local
      )
    );
  }
};

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  return hre.network.name !== "hardhat";
};

func.dependencies = ["GelatoRelayConcurrentERC2771"];
func.tags = ["GelatoRelay1BalanceConcurrentERC2771"];

export default func;
