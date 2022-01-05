import { deployments, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../src/utils";
import { getAddresses } from "../src/addresses";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  if (hre.network.name === "mainnet" || hre.network.name === "goerli") {
    console.log(
      `Deploying GelatoRelayer to ${hre.network.name}. Hit ctrl + c to abort`
    );
    await sleep(10000);
  }

  const { deploy } = deployments;
  const { deployer, gelatoMultiSig } = await getNamedAccounts();
  const addresses = getAddresses(hre.network.name);
  const treasuryAddress = (await deployments.get("Treasury")).address;
  const version = "0.1";

  await deploy("GelatoRelayer", {
    from: deployer,
    proxy: {
      owner: gelatoMultiSig,
      proxyContract: "EIP173Proxy",
      execute: {
        init: {
          methodName: "initialize",
          args: [],
        },
      },
    },
    args: [
      addresses.Gelato,
      addresses.OracleAggregator,
      treasuryAddress,
      version,
    ],
    log: hre.network.name != "hardhat" ? true : false,
  });
};

export default func;

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  const shouldSkip =
    hre.network.name === "mainnet" || hre.network.name === "goerli";
  return shouldSkip ? true : false;
};
func.tags = ["GelatoRelayer"];
func.dependencies = ["Treasury"];
