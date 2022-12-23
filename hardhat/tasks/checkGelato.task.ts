import { task } from "hardhat/config";
import { IGelatoRelay as GelatoRelay } from "../../typechain";

export const checkGelato = task(
  "checkGelato",
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

export const checkOwner = task(
  "checkOwner",
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
