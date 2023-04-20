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

export const ownerGelatoRelay = task(
  "ownerGelatoRelay",
  "return owner address stored on GelatoRelay.sol"
).setAction(async (_, { deployments, ethers }) => {
  try {
    const ABI = ["function owner() view returns (address)"];
    const gelatoRelay = await ethers.getContractAt(
      ABI,
      (
        await deployments.get("GelatoRelay")
      ).address
    );
    console.log(await gelatoRelay.owner());
  } catch (error) {
    console.error(error, "\n");
    process.exit(1);
  }
});

export const ownerGelatoRelay1Balance = task(
  "ownerGelatoRelay1Balance",
  "return owner address stored on GelatoRelay1Balance.sol"
).setAction(async (_, { deployments, ethers }) => {
  try {
    const ABI = ["function owner() view returns (address)"];
    const gelatoRelay1Balance = await ethers.getContractAt(
      ABI,
      (
        await deployments.get("GelatoRelay1Balance")
      ).address
    );
    console.log(await gelatoRelay1Balance.owner());
  } catch (error) {
    console.error(error, "\n");
    process.exit(1);
  }
});

export const transferOwnershipGelatoRelay = task(
  "transferOwnershipGelatoRelay",
  "GelatoRelay.transferOwnership"
)
  .addPositionalParam("owner")
  .setAction(async ({ owner }: { owner: string }, { deployments, ethers }) => {
    try {
      const gelatoRelay = (await ethers.getContractAt(
        "IEIP173Proxy",
        (
          await deployments.get("GelatoRelay")
        ).address
      )) as IEIP173Proxy;

      console.log(`Old owner: ${await gelatoRelay.owner()}`);

      const txResponse = await gelatoRelay.transferOwnership(owner);
      console.log("\n waiting for mining\n");
      console.log(`Tx hash: ${txResponse.hash}`);
      await txResponse.wait();

      console.log(`New owner: ${await gelatoRelay.owner()}`);
    } catch (error) {
      console.error((error as Error).message);
      process.exit(1);
    }
  });

export const transferOwnershipGelatoRelay1Balance = task(
  "transferOwnershipGelatoRelay1Balance",
  "GelatoRelay1Balance.transferOwnership"
)
  .addPositionalParam("owner")
  .setAction(async ({ owner }: { owner: string }, { deployments, ethers }) => {
    try {
      const gelatoRelay1Balance = (await ethers.getContractAt(
        "IEIP173Proxy",
        (
          await deployments.get("GelatoRelay1Balance")
        ).address
      )) as IEIP173Proxy;

      console.log(`Old owner: ${await gelatoRelay1Balance.owner()}`);

      const txResponse = await gelatoRelay1Balance.transferOwnership(owner);
      console.log("\n waiting for mining\n");
      console.log(`Tx hash: ${txResponse.hash}`);
      await txResponse.wait();

      console.log(`New owner: ${await gelatoRelay1Balance.owner()}`);
    } catch (error) {
      console.error((error as Error).message);
      process.exit(1);
    }
  });
