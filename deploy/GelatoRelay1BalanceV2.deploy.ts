import { deployments, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../src/utils";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const {
    deployer: hardhatAccount,
    relay1BalanceDeployer,
    devRelay1BalanceDeployer,
  } = await getNamedAccounts();

  const isHardhat = hre.network.name === "hardhat";
  const isDevEnv = hre.network.name.endsWith("Dev");
  const isZkSync = hre.network.name.startsWith("zksync");

  let deployer: string;

  if (isHardhat) {
    deployer = hardhatAccount;
  } else {
    console.log(
      `\nDeploying GelatoRelay1BalanceV2 to ${hre.network.name}. Hit ctrl + c to abort`
    );
    console.log(`\n IS DEV ENV: ${isDevEnv} \n`);

    deployer = isDevEnv ? devRelay1BalanceDeployer : relay1BalanceDeployer;

    await sleep(5000);
  }

  await deploy("GelatoRelay1BalanceV2", {
    from: deployer,
    deterministicDeployment: isZkSync ? false : isDevEnv ? "0xdead" : true,
    log: !isHardhat,
  });
};

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  return hre.network.name !== "hardhat";
};

func.tags = ["GelatoRelay1BalanceV2"];

export default func;
