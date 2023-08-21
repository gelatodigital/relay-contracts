import { task } from "hardhat/config";
import { IEIP173Proxy, IGelatoRelay as GelatoRelay } from "../../typechain";

export const gelato = task(
  "gelato",
  "return gelato address stored on GelatoRelay.sol"
).setAction(async (_, { deployments, ethers }) => {
  try {
    const gelatoRelay = (await ethers.getContractAt(
      "GelatoRelay",
      (
        await deployments.get("GelatoRelay")
      ).address
    )) as GelatoRelay;
    console.log(await gelatoRelay.gelato());
  } catch (error) {
    console.error(error, "\n");
    process.exit(1);
  }
});

export const owner = task("owner", "Return owner address of the proxy contract")
  .addPositionalParam("contractName")
  .setAction(
    async (
      { contractName }: { contractName: string },
      { deployments, ethers }
    ) => {
      try {
        const ABI = ["function owner() view returns (address)"];
        const proxy = await ethers.getContractAt(
          ABI,
          (
            await deployments.get(contractName)
          ).address
        );
        console.log(await proxy.owner());
      } catch (error) {
        console.error((error as Error).message);
        process.exit(1);
      }
    }
  );

export const transferOwnership = task(
  "transferOwnership",
  "Transfer ownership of the proxy contract"
)
  .addPositionalParam("contractName")
  .addPositionalParam("newOwner")
  .setAction(
    async (
      { contractName, newOwner }: { contractName: string; newOwner: string },
      { deployments, ethers }
    ) => {
      try {
        const proxy = (await ethers.getContractAt(
          "IEIP173Proxy",
          (
            await deployments.get(contractName)
          ).address
        )) as IEIP173Proxy;

        const ownerAddress = await proxy.owner();
        const owner = await ethers.getSigner(ownerAddress);

        console.log(`Old owner: ${ownerAddress}`);

        const txResponse = await proxy
          .connect(owner)
          .transferOwnership(newOwner);

        console.log("\n waiting for mining\n");
        console.log(`Tx hash: ${txResponse.hash}`);

        await txResponse.wait();

        console.log(`\nNew owner: ${await proxy.owner()}`);
      } catch (error) {
        console.error((error as Error).message);
        process.exit(1);
      }
    }
  );

export const upgradeTo = task("upgradeTo", "Upgrade proxy contract")
  .addPositionalParam("contractName")
  .addPositionalParam("newImplementation")
  .setAction(
    async (
      {
        contractName,
        newImplementation,
      }: { contractName: string; newImplementation: string },
      { deployments, ethers }
    ) => {
      try {
        const proxy = (await ethers.getContractAt(
          "IEIP173Proxy",
          (
            await deployments.get(contractName)
          ).address
        )) as IEIP173Proxy;

        const ownerAddress = await proxy.owner();
        const owner = await ethers.getSigner(ownerAddress);

        const txResponse = await proxy
          .connect(owner)
          .upgradeTo(newImplementation);

        console.log("\n waiting for mining\n");
        console.log(`Tx hash: ${txResponse.hash}`);

        await txResponse.wait();

        console.log(`\nUpgraded to implementation: ${newImplementation}`);
      } catch (error) {
        console.error((error as Error).message);
        process.exit(1);
      }
    }
  );
