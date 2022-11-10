import { deployments, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../src/utils";
import { getAddresses } from "../src/addresses";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const { relayDeployer } = await getNamedAccounts();

  if (hre.network.name !== "hardhat") {
    console.log(
      `Deploying GelatoRelay to ${hre.network.name}. Hit ctrl + c to abort`
    );
    await sleep(5000);
  }

  const { GELATO } = getAddresses(hre.network.name);

  await deploy("GelatoRelay", {
    from: relayDeployer,
    proxy: true,
    args: [GELATO],
    log: true,
  });
};

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  return hre.network.name !== "hardhat";
};
func.tags = ["GelatoRelay"];

export default func;
