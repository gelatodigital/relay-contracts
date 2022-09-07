import hre = require("hardhat");
import { impersonateAccount } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { GelatoRelay, MockGelatoRelayContext, MockERC20 } from "../typechain";
import { INIT_TOKEN_BALANCE as FEE } from "./constants";
import { ethers } from "hardhat";
import { getAddresses } from "../src/addresses";
import { Signer } from "ethers";

const TASK_ID = ethers.utils.keccak256("0xdeadbeef");
const { GELATO } = getAddresses(hre.network.name);
const FEE_COLLECTOR = GELATO;

describe("Test GelatoRelayContext on GelatoRelay", function () {
  let gelatoSigner: Signer;

  let gelatoRelay: GelatoRelay;
  let mockGelatoRelayContext: MockGelatoRelayContext;
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

    gelatoRelay = await hre.ethers.getContract("GelatoRelay");
    mockGelatoRelayContext = await hre.ethers.getContract(
      "MockGelatoRelayContext"
    );
    mockERC20 = await hre.ethers.getContract("MockERC20");

    target = mockGelatoRelayContext.address;
    feeToken = mockERC20.address;
  });

  it("#1: emitContext", async () => {
    const data =
      mockGelatoRelayContext.interface.encodeFunctionData("emitContext");

    // Mimic GelatoRelayUtils _encodeGelatoRelayContext used on-chain by GelatoRelay
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
      .to.emit(mockGelatoRelayContext, "LogMsgData")
      .withArgs(encodedData)
      .and.to.emit(mockGelatoRelayContext, "LogFnArgs")
      .withArgs(data)
      .and.to.emit(mockGelatoRelayContext, "LogContext")
      .withArgs(FEE_COLLECTOR, feeToken, FEE);
  });

  it("#2: testTransferRelayFee", async () => {
    const data = mockGelatoRelayContext.interface.encodeFunctionData(
      "testTransferRelayFee"
    );

    await mockERC20.transfer(target, FEE);

    await gelatoRelay
      .connect(gelatoSigner)
      .callWithSyncFee(target, data, feeToken, FEE, TASK_ID);

    expect(await mockERC20.balanceOf(FEE_COLLECTOR)).to.be.eq(FEE);
  });

  it("#3: testTransferRelayFeeCapped: works if at maxFee", async () => {
    const maxFee = FEE;

    const data = mockGelatoRelayContext.interface.encodeFunctionData(
      "testTransferRelayFeeCapped",
      [maxFee]
    );

    await mockERC20.transfer(target, FEE);

    await gelatoRelay
      .connect(gelatoSigner)
      .callWithSyncFee(target, data, feeToken, FEE, TASK_ID);

    expect(await mockERC20.balanceOf(FEE_COLLECTOR)).to.be.eq(FEE);
  });

  it("#4: testTransferRelayFeeCapped: works if below maxFee", async () => {
    const maxFee = FEE.add(1);

    const data = mockGelatoRelayContext.interface.encodeFunctionData(
      "testTransferRelayFeeCapped",
      [maxFee]
    );

    await mockERC20.transfer(target, FEE);

    await gelatoRelay
      .connect(gelatoSigner)
      .callWithSyncFee(target, data, feeToken, FEE, TASK_ID);

    expect(await mockERC20.balanceOf(FEE_COLLECTOR)).to.be.eq(FEE);
  });

  it("#5: testTransferRelayFeeCapped: reverts if above maxFee", async () => {
    const maxFee = FEE.sub(1);

    const data = mockGelatoRelayContext.interface.encodeFunctionData(
      "testTransferRelayFeeCapped",
      [maxFee]
    );

    await mockERC20.transfer(target, FEE);

    await expect(
      gelatoRelay
        .connect(gelatoSigner)
        .callWithSyncFee(target, data, feeToken, FEE, TASK_ID)
    ).to.be.revertedWith(
      "GelatoRelay.callWithSyncFee:GelatoRelayContext._transferRelayFeeCapped: maxFee"
    );
  });

  it("#6: testOnlyGelatoRelay reverts if not GelatoRelay", async () => {
    await expect(
      mockGelatoRelayContext.testOnlyGelatoRelay()
    ).to.be.revertedWith("GelatoRelayContext.onlyGelatoRelay");
  });
});
