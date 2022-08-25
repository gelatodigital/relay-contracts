import hre = require("hardhat");
import { impersonateAccount } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
//import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signers";
import { GelatoRelay, MockRelayerContext, MockERC20 } from "../typechain";
import { INIT_TOKEN_BALANCE as FEE } from "./constants";
import { ethers } from "hardhat";
import { getAddresses } from "../src/addresses";
import { Signer } from "ethers";

const TASK_ID = ethers.utils.keccak256("0xdeadbeef");
const { GELATO } = getAddresses(hre.network.name);
const FEE_COLLECTOR = GELATO;

describe("Test GelatoRelay Smart Contract", function () {
  let gelatoSigner: Signer;

  let gelatoRelay: GelatoRelay;
  let mockRelayerContext: MockRelayerContext;
  let mockERC20: MockERC20;

  let target: string;
  let feeToken: string;

  beforeEach("tests", async function () {
    if (hre.network.name !== "hardhat") {
      console.error("Test Suite is meant to be run on hardhat only");
      process.exit(1);
    }

    await hre.deployments.fixture();

    await impersonateAccount(GELATO);
    gelatoSigner = await ethers.getSigner(GELATO);

    //  [user] = await hre.ethers.getSigners();

    gelatoRelay = await hre.ethers.getContract("GelatoRelay");
    mockRelayerContext = await hre.ethers.getContract("MockRelayerContext");
    mockERC20 = await hre.ethers.getContract("MockERC20");

    target = mockRelayerContext.address;
    feeToken = mockERC20.address;
  });

  it("#0: MockRelayerContext has GelatoRelay set as relayer", async () => {
    expect(await mockRelayerContext.relayer()).to.be.eq(gelatoRelay.address);
  });

  it("#1: emitContext", async () => {
    const data = mockRelayerContext.interface.encodeFunctionData("emitContext");

    // Mimic RelayerUtils _encodeRelayerContext used on-chain by GelatoRelay
    const encodedContextData = new ethers.utils.AbiCoder().encode(
      ["address", "address", "uint256"],
      [FEE_COLLECTOR, feeToken, FEE]
    );
    const encodedData = ethers.utils.solidityPack(
      ["bytes", "bytes"],
      [data, encodedContextData]
    );

    await expect(
      gelatoRelay
        .connect(gelatoSigner)
        .callWithSyncFee(target, data, feeToken, FEE, TASK_ID)
    )
      .to.emit(mockRelayerContext, "LogMsgData")
      .withArgs(encodedData)
      .and.to.emit(mockRelayerContext, "LogFnArgs")
      .withArgs(data)
      .and.to.emit(mockRelayerContext, "LogContext")
      .withArgs(FEE_COLLECTOR, feeToken, FEE)
      .and.to.emit(mockRelayerContext, "LogUncheckedContext");
  });

  it("#2: onlyRelayerTransferUncapped", async () => {
    const data = mockRelayerContext.interface.encodeFunctionData(
      "onlyRelayerTransferUncapped"
    );

    await mockERC20.transfer(target, FEE);

    await gelatoRelay
      .connect(gelatoSigner)
      .callWithSyncFee(target, data, feeToken, FEE, TASK_ID);

    expect(await mockERC20.balanceOf(FEE_COLLECTOR)).to.be.eq(FEE);
  });

  it("#3: onlyRelayerTransferCapped: works if at maxFee", async () => {
    const maxFee = FEE;

    const data = mockRelayerContext.interface.encodeFunctionData(
      "onlyRelayerTransferCapped",
      [maxFee]
    );

    await mockERC20.transfer(target, FEE);

    await gelatoRelay
      .connect(gelatoSigner)
      .callWithSyncFee(target, data, feeToken, FEE, TASK_ID);

    expect(await mockERC20.balanceOf(FEE_COLLECTOR)).to.be.eq(FEE);
  });

  it("#4: onlyRelayerTransferCapped: works if below maxFee", async () => {
    const maxFee = FEE.add(1);

    const data = mockRelayerContext.interface.encodeFunctionData(
      "onlyRelayerTransferCapped",
      [maxFee]
    );

    await mockERC20.transfer(target, FEE);

    await gelatoRelay
      .connect(gelatoSigner)
      .callWithSyncFee(target, data, feeToken, FEE, TASK_ID);

    expect(await mockERC20.balanceOf(FEE_COLLECTOR)).to.be.eq(FEE);
  });

  it("#5: onlyRelayerTransferCapped: reverts if above maxFee", async () => {
    const maxFee = FEE.sub(1);

    const data = mockRelayerContext.interface.encodeFunctionData(
      "onlyRelayerTransferCapped",
      [maxFee]
    );

    await mockERC20.transfer(target, FEE);

    await expect(
      gelatoRelay
        .connect(gelatoSigner)
        .callWithSyncFee(target, data, feeToken, FEE, TASK_ID)
    ).to.be.revertedWith(
      "GelatoRelay.callWithSyncFee:RelayerContext._uncheckedTransferToFeeCollectorCapped: maxFee"
    );
  });
});
