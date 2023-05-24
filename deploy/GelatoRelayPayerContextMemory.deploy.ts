//TODO: Review this file
import { deployments, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../src/utils";
import { getAddresses } from "../src/addresses";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const { deployer, relayERC2771Deployer, devRelayERC2771Deployer } =
    await getNamedAccounts();

  let deployerAccount = deployer;

  const isHardhat = hre.network.name === "hardhat";
  const isDevEnv = hre.network.name.endsWith("Dev");

  if (!isHardhat) {
    console.log(
      `\nDeploying GelatoRelayPayerContextMemory to ${hre.network.name}. Hit ctrl + c to abort`
    );
    console.log(`\n IS DEV ENV: ${isDevEnv} \n`);

    deployerAccount = isDevEnv ? devRelayERC2771Deployer : relayERC2771Deployer;

    await sleep(5000);
  }

  const { GELATO } = getAddresses(hre.network.name);

  if (!GELATO) {
    console.error(`GELATO not defined on network: ${hre.network.name}`);
    process.exit(1);
  }

  await deploy("GelatoRelayPayerContextMemory", {
    from: deployerAccount,
    args: [GELATO],
    log: !isHardhat,
  });

  if (isHardhat) {
    const gelatoRelayPayerContextMemoryLocal = await (
      await deployments.get("GelatoRelayPayerContextMemory")
    ).address;
    console.log(
      `GelatoRelayPayerContextMemory Address: ${gelatoRelayPayerContextMemoryLocal}`
    );
    // await setCode(
    //   gelatoRelayERC2771,
    //   await hre.ethers.provider.getCode(gelatoRelayERC2771Local)
    // );
  }
};

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  return hre.network.name !== "hardhat";
};

func.tags = ["GelatoRelayPayerContextMemory"];

export default func;
