import { deployments, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../src/utils";
import { getAddresses } from "../src/addresses";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  if (hre.network.name !== "hardhat") {
    console.log(
      `Deploying GelatoMetaBox to ${hre.network.name}. Hit ctrl + c to abort`
    );
    await sleep(2000);
  }

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const addresses = getAddresses(hre.network.name);

  await deploy("GelatoMetaBox", {
    from: deployer,
    proxy: {
      owner: deployer,
      proxyContract: "EIP173Proxy",
      execute: {
        methodName: "init",
        args: [deployer],
      },
    },
    args: [addresses.Gelato],
    log: hre.network.name != "hardhat",
  });
};

export default func;

// func.skip = async (hre: HardhatRuntimeEnvironment) => {
//   return hre.network.name !== "hardhat";
// };
func.tags = ["GelatoMetaBox"];
