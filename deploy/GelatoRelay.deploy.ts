import { deployments, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../src/utils";
import { getAddresses } from "../src/addresses";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  if (hre.network.name === "mumbai") {
    console.log(
      `Deploying GelatoRelay to ${hre.network.name}. Hit ctrl + c to abort`
    );
    await sleep(10000);
  }

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const addresses = getAddresses(hre.network.name);

  console.log(`Deployer address: ${deployer}`);

  await deploy("GelatoRelay", {
    from: deployer,
    proxy: {
      owner: deployer,
      proxyContract: "EIP173ProxyWithReceive",
      execute: {
        init: {
          methodName: "init",
          args: [deployer],
        },
      },
    },
    args: [addresses.Gelato],
    log: hre.network.name != "hardhat" ? true : false,
  });
};

export default func;
