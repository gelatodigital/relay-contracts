import { deployments, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../src/utils";
import { getAddresses } from "../src/addresses";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deploy, catchUnknownSigner } = deployments;
  const { deployer, relayDeployer } = await getNamedAccounts();

  if (hre.network.name !== "hardhat") {
    if (deployer !== relayDeployer) {
      console.error(`Wrong deployer: ${deployer}\n expected: ${relayDeployer}`);
      process.exit(1);
    }
    console.log(
      `Deploying GelatoRelay to ${hre.network.name}. Hit ctrl + c to abort`
    );
    await sleep(5000);
  }

  const { GELATO } = getAddresses(hre.network.name);

  await catchUnknownSigner(
    deploy("GelatoRelay", {
      from: deployer,
      proxy: {
        owner: "0x92F5CBe95fe02240E837047b97ACcd65Edadb1AE",
      },
      args: [GELATO],
      log: true,
    })
  );
};

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  return hre.network.name !== "hardhat";
};
func.tags = ["GelatoRelay"];

export default func;
