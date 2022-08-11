import { deployments, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../src/utils";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  if (hre.network.name !== "hardhat") {
    console.log(
      `Deploying GelatoPullFeeRegistry to ${hre.network.name}. Hit ctrl + c to abort`
    );
    await sleep(10000);
  }

  const { deploy, get } = deployments;
  const { deployer } = await getNamedAccounts();

  const gelatoRelayForwarderPullFeeAddress = (
    await get("GelatoRelayForwarderPullFee")
  ).address;
  const gelatoMetaBoxPullFeeAddress = (await get("GelatoMetaBoxPullFee"))
    .address;

  await deploy("GelatoPullFeeRegistry", {
    from: deployer,
    args: [gelatoRelayForwarderPullFeeAddress, gelatoMetaBoxPullFeeAddress],
    log: hre.network.name != "hardhat" ? true : false,
  });
};

export default func;

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  return hre.network.name !== "hardhat";
};

func.dependencies = ["GelatoMetaBoxPullFee", "GelatoRelayForwarderPullFee"];
func.tags = ["GelatoPullFeeRegistry"];
