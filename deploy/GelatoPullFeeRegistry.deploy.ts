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
    hre.network.name === "evmos" ||
    hre.network.name === "moonriver" ||
    hre.network.name === "moonbeam" ||
    hre.network.name === "avalanche" ||
    hre.network.name === "bsc"
  ) {
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
  const shouldSkip =
    hre.network.name === "mainnet" ||
    hre.network.name === "goerli" ||
    hre.network.name === "matic" ||
    hre.network.name === "mumbai" ||
    hre.network.name === "kovan" ||
    hre.network.name === "gnosis" ||
    hre.network.name === "evmos" ||
    hre.network.name === "moonriver" ||
    hre.network.name === "moonbeam" ||
    hre.network.name === "avalanche" ||
    hre.network.name === "bsc";
  return shouldSkip ? true : false;
};

func.dependencies = ["GelatoMetaBoxPullFee", "GelatoRelayForwarderPullFee"];
func.tags = ["GelatoPullFeeRegistry"];
