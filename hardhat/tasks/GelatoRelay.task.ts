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

export const owner = task(
  "owner",
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

export const transferOwnership = task(
  "transferOwnership",
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
