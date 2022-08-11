import { deployments, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../src/utils";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  if (hre.network.name !== "hardhat") {
    console.log(
      `Deploying HelloWorld to ${hre.network.name}. Hit ctrl + c to abort`
    );
    await sleep(10000);
  }

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const gelatoMetaBox = await hre.deployments.get("GelatoMetaBox");

  console.log(`GelatoMetaBox address: ${gelatoMetaBox.address}`);

  await deploy("HelloWorld", {
    from: deployer,
    args: [gelatoMetaBox.address],
    log: hre.network.name != "hardhat" ? true : false,
  });
};

export default func;

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  return hre.network.name !== "hardhat";
};

func.dependencies = ["GelatoMetaBox"];
func.tags = ["HelloWorld"];
