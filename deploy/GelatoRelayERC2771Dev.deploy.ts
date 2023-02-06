import { deployments, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../src/utils";
import { getAddresses } from "../src/addresses";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const { deployer, relayERC2771DevDeployer } = await getNamedAccounts();

  if (hre.network.name !== "hardhat") {
    if (deployer !== relayERC2771DevDeployer) {
      console.error(
        `Wrong deployer: ${deployer}\n expected: ${relayERC2771DevDeployer}`
      );
      process.exit(1);
    }
    console.log(
      `Deploying GelatoRelayERC2771Dev to ${hre.network.name}. Hit ctrl + c to abort`
    );
    await sleep(5000);
  }

  const { GELATO } = getAddresses(hre.network.name);

  await deploy("GelatoRelayERC2771Dev", {
    from: deployer,
    proxy: true,
    args: [GELATO],
    log: true,
  });
};

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  return hre.network.name !== "hardhat";
};
func.tags = ["GelatoRelayERC2771Dev"];

export default func;
