import { deployments, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../src/utils";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  if (hre.network.name === "mainnet" || hre.network.name === "goerli") {
    console.log(
      `Deploying Treasury to ${hre.network.name}. Hit ctrl + c to abort`
    );
    await sleep(10000);
  }

  const { deploy } = deployments;
  const { deployer, gelatoMultiSig } = await getNamedAccounts();
  await deploy("Treasury", {
    from: deployer,
    proxy: {
      owner: gelatoMultiSig,
      proxyContract: "EIP173ProxyWithReceive",
    },
    args: [gelatoMultiSig],
    log: hre.network.name != "hardhat" ? true : false,
  });
};

export default func;

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  const shouldSkip =
    hre.network.name === "mainnet" || hre.network.name === "goerli";
  return shouldSkip ? true : false;
};
func.tags = ["Treasury"];
