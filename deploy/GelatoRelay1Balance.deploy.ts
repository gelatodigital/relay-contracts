import { deployments, getNamedAccounts } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../src/utils";
import { getAddresses } from "../src/addresses";
import { IEIP173Proxy } from "../typechain";
import {
  impersonateAccount,
  setBalance,
} from "@nomicfoundation/hardhat-network-helpers";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments;
  const {
    deployer: hardhatAccount,
    relay1BalanceDeployer,
    devRelay1BalanceDeployer,
    gelatoRelay1Balance,
  } = await getNamedAccounts();

  const isHardhat = hre.network.name === "hardhat";
  const isDevEnv = hre.network.name.endsWith("Dev");

  let deployer: string;

  if (isHardhat) {
    deployer = hardhatAccount;
  } else {
    console.log(
      `\nDeploying GelatoRelay1Balance to ${hre.network.name}. Hit ctrl + c to abort`
    );
    console.log(`\n IS DEV ENV: ${isDevEnv} \n`);

    deployer = isDevEnv ? devRelay1BalanceDeployer : relay1BalanceDeployer;

    await sleep(5000);
  }

  const { GELATO } = getAddresses(hre.network.name);

  if (!GELATO) {
    console.error(`GELATO not defined on network: ${hre.network.name}`);
    process.exit(1);
  }

  await deploy("GelatoRelay1Balance", {
    from: deployer,
    proxy: {
      proxyContract: "EIP173Proxy",
    },
    args: [GELATO],
    log: !isHardhat,
  });

  // For local testing we want to upgrade the forked
  // instance of gelatoRelay to our locally deployed implementation
  if (isHardhat) {
    const gelatoRelay1BalanceProxy = (await hre.ethers.getContractAt(
      "IEIP173Proxy",
      gelatoRelay1Balance
    )) as IEIP173Proxy;

    const gelatoRelay1BalanceOwnerAddr = await gelatoRelay1BalanceProxy.owner();

    await impersonateAccount(gelatoRelay1BalanceOwnerAddr);
    await setBalance(
      gelatoRelay1BalanceOwnerAddr,
      hre.ethers.utils.parseEther("1")
    );

    const gelatoRelay1BalanceOwner = await hre.ethers.getSigner(
      gelatoRelay1BalanceOwnerAddr
    );

    await gelatoRelay1BalanceProxy
      .connect(gelatoRelay1BalanceOwner)
      .upgradeTo(
        (
          await deployments.get("GelatoRelay1Balance_Implementation")
        ).address,
        { gasLimit: 1_000_000 }
      );
  }
};

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  return hre.network.name !== "hardhat";
};
func.tags = ["GelatoRelay1Balance"];

export default func;
