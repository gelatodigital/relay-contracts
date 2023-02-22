import { deployments, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../src/utils";
import { getAddresses } from "../src/addresses";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const { relayERC2771Deployer, devRelayERC2771Deployer } =
    await getNamedAccounts();

  const isDevEnv = hre.network.name.endsWith("Dev");

  if (hre.network.name !== "hardhat") {
    console.log(
      `\n Deploying GelatoRelayERC2771 to ${hre.network.name}. Hit ctrl + c to abort`
    );
    console.log(`\n IS DEV ENV: ${isDevEnv ? "✅" : "❌"} \n`);
    await sleep(5000);
  }

  const { GELATO } = getAddresses(hre.network.name);

  if (!GELATO) {
    console.error(`GELATO not defined on network: ${hre.network.name}`);
    process.exit(1);
  }

  await deploy("GelatoRelayERC2771", {
    from: isDevEnv ? devRelayERC2771Deployer : relayERC2771Deployer,
    args: [GELATO],
    log: true,
  });
};

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  return hre.network.name !== "hardhat";
};
func.tags = ["GelatoRelayERC2771"];

export default func;
