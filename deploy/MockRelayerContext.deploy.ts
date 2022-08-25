import { deployments, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  if (hre.network.name !== "hardhat") {
    console.error(`Only deploy MockRelayerContext on hardhat`);
    process.exit(1);
  }

  await deploy("MockRelayerContext", {
    from: deployer,
    args: [(await deployments.get("GelatoRelay")).address],
  });
};

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  return hre.network.name !== "hardhat";
};

func.tags = ["MockRelayerContext"];
func.dependencies = ["GelatoRelay"];

export default func;
