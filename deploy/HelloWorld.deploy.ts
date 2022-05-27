import { deployments, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../src/utils";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  if (
    hre.network.name === "mainnet" ||
    hre.network.name === "goerli" ||
    hre.network.name === "matic" ||
    hre.network.name === "mumbai" ||
    hre.network.name === "kovan" ||
    hre.network.name === "gnosis" ||
    hre.network.name === "evmos"
  ) {
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

/*func.skip = async (hre: HardhatRuntimeEnvironment) => {
  const shouldSkip =
    hre.network.name === "mainnet" ||
    hre.network.name === "goerli" ||
    hre.network.name === "matic" ||
    hre.network.name === "mumbai" ||
    hre.network.name === "kovan" ||
    hre.network.name === "gnosis" ||
    hre.network.name === "evmos";
  return shouldSkip ? true : false;
};*/
func.dependencies = ["GelatoMetaBox"];
func.tags = ["HelloWorld"];
